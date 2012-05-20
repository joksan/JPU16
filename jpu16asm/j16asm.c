//+-----------------------------------------------------------------------------------------------+
//| j16asm.c                                                                                      |
//| Modulo principal del programa                                                                 |
//|                                                                                               |
//| Este modulo provee la funcion principal del ensamblador y se encarga de llevar a cabo las     |
//| tareas principales del mismo. El paso 1 de compilacion se lleva a cabo por medio de invocar   |
//| la funcion  yyparse(), la cual es provista por bison en el modulo de codigo fuente que genera |
//| mediante el archivo de gramatica asociado.                                                    |
//| El paso 2 de compilacion se lleva a cabo mediante la funcion proceso_paso_2(), las funciones  |
//| agregar_dato_ram() y agregar_dato_prg() proveen mecanismos para agregar datos a los espacios  |
//| de memoria que maneja JPU16 durante el paso 1 y la generacion de los datos de salida (codigo  |
//| de maquina) se lleva a cabo en la funcion generar_salida().                                   |
//|                                                                                               |
//| Las actividades generadas en el paso 1 son las siguientes:                                    |
//| - Analisis lexico - yylex() (leer el archivo de entrada y reconocer las palabras)             |
//| - Analisis sintactico - yyparse (identificar el orden de las palabras y las estructuras que   |
//|   forman, asociando significados a sus agrupaciones).                                         |
//| - Identificacion de simbolos y creacion de la tabla de simbolos.                              |
//| - Alojamiento de espacio en la memoria RAM y de programa e inicializacion de los datos.       |
//| - Evaluacion de expresiones aritmeticas literales.                                            |
//| - Evaluacion de expresiones simbolicas en aquellos casos donde los valores de los simbolos    |
//|   son previamente conocidos                                                                   |
//| - Identificacion de expresiones simbolicas en aquellos casos donde no se sabe el valor de     |
//|   todos los simbolos con anterioridad, para ser postergadas al paso 2 mediante una cola de    |
//|   acciones.                                                                                   |
//|                                                                                               |
//| Las actividades generadas en el paso 2 son las siguientes:                                    |
//| - Realizacion de todas las actividades guardadas en la cola de acciones, las cuales indican   |
//|   las operaciones postergadas del paso 1.                                                     |
//| - Determinacion de los valores de los simbolos cuyo valor no era conocido en el paso 1,       |
//|   mediante los datos registrados en la tabla de simbolos que ahora esta completa.             |
//| - Calculo de expresiones aritmeticas mediante una pila de datos, usando notacion polaca       |
//|   inversa.                                                                                    |
//| - Almacenamiento de los resultados generados en la memoria RAM y de programa.                 |
//+-----------------------------------------------------------------------------------------------+
#include <stdbool.h>                   //Incluye la definicion del tipo de dato bool
#include <math.h>                      //Permite invocar la funcion pow()
#include <stdio.h>                     //Permite manejar archivos
#include <string.h>                    //Permite manejar cadenas
#include <stdlib.h>                    //Permite invocar la funcion atoi()
#include "j16asm.h"                    //Cabecera propia
#include "j16asm_dat_struct.h"         //Importa las estructuras de datos
#include "j16asm_output_vhdl.h"        //Permite generar la definicion de la memoria en VHDL
#include "j16asm_output_vhdl_ramb16.h" //Permite generar la salida en VHDL con primitivas RAMB16
#include "j16asm_output_mem_bmm.h"     //Permite generar los otros archivos de salida
#include "j16asm_messages.h"           //Permite enviar mensajes al usuario

//Dependencias externas
extern int yyparse ();          //Funcion que implementa el analizador sintactico
extern FILE *yyin;              //Puntero al handle del archivo procesado

//Variables compartidas con otros modulos
char nombre_archivo_ent[256];    //Nombre del archivo de entrada
char nombre_archivo_vhd[256];    //Nombre del archivo que se genera en formato vhdl
char nombre_archivo_vhd_r[256];  //Nombre del archivo que se genera en formato vhdl (RAMB16)
char nombre_archivo_mem[256];    //Nombre del archivo que se genera en formato mem
char nombre_archivo_bmm[256];    //Nombre del archivo que se genera en formato bmm
int tam_prg = 512;               //Cantidad maxima de instrucciones para la memoria de programa
int tam_ram = 1024;              //Cantidad maxima de palabras para la memoria RAM
int datos_prg[65536];            //Arreglo con el espacio de datos de la memoria de programa
int datos_ram[65536];            //Arreglo con el espacio de datos de la memoria RAM
int pos_prg = 0;                 //Posicion actual en la memoria de programa
int pos_ram = 0;                 //Posicion actual en la memoria RAM

//Declaracion previa de las funciones compartidas con otros modulos
bool agregar_dato_ram(int dato, int num_lin);
bool agregar_dato_prg(int dato, int num_lin);

//Variables locales al modulo
static bool arglc_v = false;     //Indica la presencia del argumento -v en la linea de comando
static bool arglc_vr = false;    //Indica la presencia del argumento -vr
static bool arglc_m = false;     //Indica la presencia del argumento -m
static bool arglc_b = false;     //Indica la presencia del argumento -b

//Declaracion previa de las funciones locales al modulo
static bool proceso_paso_2();
static void marcar_memoria_libre_completa();
static void contar_memoria_usada();

//+------------------------------+
//| Inicio del codigo del modulo |
//+------------------------------+-----------------------------------------------------------------
//Funcion principal del programa
int main (int argc, char *argv[]) {
  int i;
  int valor_retorno;
  FILE *fp_archivo = NULL;

  //Verifica si se invoco el programa sin argumentos
  if (argc < 2) {
    msg_lc_ayuda_invocacion();   //De ser asi imprime la ayuda y sale
    return 0;
  }

  //Verifica si se invoco el programa con al menos 1 argumento
  if (argc >= 2)
    //De ser asi toma el segundo argumento como nombre de archivo de entrada
    strcpy(nombre_archivo_ent, argv[1]);

  //Recorre la linea de comandos tomando cada par de argumentos (las opciones van en pares)
  for (i=2; i<argc; i+=2) {
    //Verifica si el argumento actual es -v
    if (strcmp(argv[i], "-v") == 0) {
      //De ser asi, verifica que exista otro argumento mas adelante
      if (i+1 >= argc) {
        msg_lc_error_argumentos_faltantes();    //Si este es el ultimo argumento, emite un mensaje de error
        return 1;
      }
      arglc_v = true;                           //Marca el argumento como presente
      strcpy(nombre_archivo_vhd, argv[i+1]);    //Toma el siguiente argumento (nombre de archivo)
    }

    //Verifica si el argumento actual es -vr
    else if (strcmp(argv[i], "-vr") == 0) {
      if (i+1 >= argc) {
        msg_lc_error_argumentos_faltantes();
        return 1;
      }
      arglc_vr = true;
      strcpy(nombre_archivo_vhd_r, argv[i+1]);
    }

    //Verifica si el argumento es -m
    else if (strcmp(argv[i], "-m") == 0) {
      if (i+1 >= argc) {
        msg_lc_error_argumentos_faltantes();
        return 1;
      }
      arglc_m = true;
      strcpy(nombre_archivo_mem, argv[i+1]);
    }

    //Verifica si el argumento es -b
    else if (strcmp(argv[i], "-b") == 0) {
      if (i+1 >= argc) {
        msg_lc_error_argumentos_faltantes();
        return 1;
      }
      arglc_b = true;
      strcpy(nombre_archivo_bmm, argv[i+1]);
    }

    //Verifica si el argumento es -p
    else if (strcmp(argv[i], "-p") == 0) {
      if (i+1 >= argc) {
        msg_lc_error_argumentos_faltantes();
        return 1;
      }
      tam_prg = atoi(argv[i+1]);
      if (tam_prg != 512 && tam_prg != 1024 && tam_prg != 2048 && tam_prg != 4096 &&
          tam_prg != 8192 && tam_prg != 16384) {
        msg_lc_error_capacidad_prg(tam_prg);
        return 1;
      }
    }

    //Verifica si el argumento es -r
    else if (strcmp(argv[i], "-r") == 0) {
      if (i+1 >= argc) {
        msg_lc_error_argumentos_faltantes();
        return 1;
      }
      tam_ram = atoi(argv[i+1]);
      if (tam_ram != 1024 && tam_ram != 2048 && tam_ram != 4096 && tam_ram != 8192 &&
          tam_ram != 16384 && tam_ram != 32768) {
        msg_lc_error_capacidad_ram(tam_ram);
        return 1;
      }
    }

    //Emite un mensaje de error generico para todos los demas argumentos
    else {
      msg_lc_error_argumento_invalido(argv[i]);
      return 1;
    }
  }

  //A continuacion se intenta abrir el archivo
  fp_archivo = fopen(nombre_archivo_ent, "r");
  if (!fp_archivo) {
    //Si no se puede abrir, se reporta el mensaje de error
    msg_error_abrir_archivo_entrada();
    return 1;
  }
  //Luego redirije la entrada del analizador sintactico para que tome datos de el
  yyin = fp_archivo;

  //Antes de comenzar el proceso, se marca toda la memoria (programa y datos) como libre
  marcar_memoria_libre_completa();

  //En la primera etapa, se invoca la funcion del analizador sintactico
  valor_retorno = yyparse();
  if (valor_retorno) return valor_retorno;

  //Muestra el mensaje de exito para la primera etapa
  msg_exito_etapa(1);

  //En la segunda etapa se aplica la cola de acciones
  if (!proceso_paso_2()) return 1;

  //Muestra el mensaje de exito para la segunda etapa
  msg_exito_etapa(2);

  //Cuenta la cantidad de memoria usada y la reporta
  contar_memoria_usada();

  //Procede a generar los archivos de salida segun las banderas
  if (arglc_v)
    if (!generar_salida_vhdl())
      return 1;

  if (arglc_vr)
    if (!generar_salida_vhdl_ramb16())
      return 1;

  if (arglc_m)
    if (!generar_salida_mem())
      return 1;

  if (arglc_b)
    if (!generar_salida_bmm())
      return 1;

  //Finalmente muestra el ultimo mensaje de exito
  msg_exito_etapa(3);
  return 0;
}

//Funcion que implementa el paso 2 de compilacion
bool proceso_paso_2() {
  int valor;                    //Valor a operar en caso de operaciones unarias
  int valor_izquierda;          //Valor o argumento de mano izquierda
  int valor_derecha;            //Valor o argumento de mano derecha
  int valor_previo;             //Valor literal contenido previamente en la memoria de programa
  ACCION_PASO_2 *accion;        //Puntero a la accion de la cola
  SIMBOLO *p_simbolo;

  //El proceso del paso 2 se realiza una cantidad indeterminada de veces
  while (1) {
    accion = desencolar_accion();       //Toma la siguiente accion de la cola
    if (!accion) break;                 //Si ya no quedan acciones pendientes, termina

    //Se realiza una accion diferente dependiendo del valor almacenado en la cola
    switch (accion->tipo & MASC_OPER) {
    case TPA_APILAR_LITERAL:
      apilar_dato(accion->valor);       //Para esta accion solo se apila el valor numerico
      break;
    case TPA_APILAR_SIMBOLO:
      //Para poder apilar un simbolo, se ubica primero en la lista de simbolos
      p_simbolo = buscar_simbolo(accion->nombre);
      if (!p_simbolo) {
        //Si no se encontro el simbolo en la lista, se regresa un mensaje de error
        msg_simbolo_no_definido(accion->num_lin, accion->nombre);
        return false;
      }

      //Una vez ubicado el simbolo, se apila su valor equivalente
      apilar_dato(p_simbolo->valor);
      break;
    case TPA_OPERACION_ARITMETICA:
      //Primeramente se determina si la operacion indicada es de caracter unario o binario
      if((accion->op & MASC_OPER) == OPER_NEG ||
         (accion->op & MASC_OPER) == OPER_NOT) {
        //En caso de ser unaria, solo desapila un valor
        desapilar_dato(&valor);
      }
      else {
        //En caso de ser binaria, verifica si los argumentos deben ser intercambiados
        if (accion->op & OPER_INTERCAMBIO) {
          //En caso de ser intercambiados, los desapila acordemente
          desapilar_dato(&valor_izquierda);
          desapilar_dato(&valor_derecha);
        }
        else {
          //De no estar intercambiados, los desapila de forma normal
          desapilar_dato(&valor_derecha);
          desapilar_dato(&valor_izquierda);
        }
      }

      //Realiza la operacion segun lo indicado en la accion y guarda el resultado de regreso en la
      //pila de datos
      switch (accion->op & MASC_OPER) {
      case OPER_OR:  apilar_dato(valor_izquierda | valor_derecha);     break;
      case OPER_XOR: apilar_dato(valor_izquierda ^ valor_derecha);     break;
      case OPER_AND: apilar_dato(valor_izquierda & valor_derecha);     break;
      case OPER_SHL: apilar_dato(valor_izquierda << valor_derecha);    break;
      case OPER_SHR: apilar_dato(valor_izquierda >> valor_derecha);    break;
      case OPER_SUM: apilar_dato(valor_izquierda + valor_derecha);     break;
      case OPER_RES: apilar_dato(valor_izquierda - valor_derecha);     break;
      case OPER_MUL: apilar_dato(valor_izquierda * valor_derecha);     break;
      case OPER_DIV: apilar_dato(valor_izquierda / valor_derecha);     break;
      case OPER_MOD: apilar_dato(valor_izquierda % valor_derecha);     break;
      case OPER_NEG: apilar_dato(-valor);                              break;
      case OPER_NOT: apilar_dato(~valor);                              break;
      case OPER_EXP: apilar_dato(pow(valor_izquierda, valor_derecha)); break;
      }

      break;
    case TPA_GUARDAR_RESULTADO_RAM:
      //Para este caso se desapila el valor del tope de la pila (que deberia tener un resultado) y
      //se guarda en el espacio de la memoria RAM
      desapilar_dato(&valor);
      datos_ram[accion->direccion] = valor & 0xFFFF;
      break;
    case TPA_GUARDAR_RESULTADO_PRG:
      //Para este caso se desapila el valor del tope de la pila (que deberia tener un resultado) y
      //se guarda en el espacio de la memoria de programa
      desapilar_dato(&valor);
      valor_previo = datos_prg[accion->direccion] & 0xFFFF;     //Se obtiene el literal del opcode
      datos_prg[accion->direccion] &= 0xFFFF0000;               //Se suplantara el literal
      datos_prg[accion->direccion] |= (valor + valor_previo) & 0xFFFF;
      //Nota: Se hace la suma del resultado de la pila mas el valor que existia como literal del
      //opcode (usualmente 0x0000) asi que el valor final es normalmente el mismo valor del
      //resultado. Sin embargo, en saltos relativos este valor no es necesariamente cero (se trata
      //de la misma direccion donde se encuentra el salto con signo negativo), de manera que al
      //sumar, se obtiene automaticamente el offset del salto.
      break;
    }

    //Una vez procesada la accion, se desaloja la misma de memoria
    desalojar_accion(accion);
  }

  //Una vez terminado el paso 2, la lista de simbolos ya no es necesaria
  desalojar_simbolos();

  return true;
}

//Funcion para marcar toda la memoria de JPU16 como disponible
void marcar_memoria_libre_completa() {
  int i;

  for (i=0; i<65536; i++) {
    datos_prg[i] = MASC_LIBRE;
    datos_ram[i] = MASC_LIBRE;
  }
}

void contar_memoria_usada() {
  int i;
  int conteo_ram = 0;
  int conteo_prg = 0;

  //Realiza el proceso de conteo de acuerdo a las localidades ocupadas
  for (i=0; i<65536; i++) {
    if (!(datos_prg[i] & MASC_LIBRE)) conteo_ram++;
    if (!(datos_ram[i] & MASC_LIBRE)) conteo_prg++;
  }

  //Indica la cantidad de instrucciones generadas
  msg_mem_prg_usada(conteo_ram);
  //Indica la cantidad de palabras generadas
  msg_mem_ram_usada(conteo_prg);
}

//Funcion para agregar y reservar un dato en la memoria RAM
bool agregar_dato_ram(int dato, int num_lin) {
  //Primeramente determina si la direccion actual excede el limite de la memoria disponible
  if (pos_ram >= tam_ram) {
    //De exceder el limite, regresa con mensaje de error
    msg_fin_ram(num_lin);
    return false;
  }

  //Luego determina si la localidad esta libre
  if (!(datos_ram[pos_ram] & MASC_LIBRE)) {
    //De no estar libre, regresa con mensaje de error
    msg_colision_ram(num_lin, pos_ram);
    return false;
  }

  //Si todo esta bien, guarda el dato en la memoria RAM y desmarca la localidad como disponible
  datos_ram[pos_ram] = dato & 0xFFFF;
  pos_ram++;                    //Apunta a la siguiente posicion de la memoria
  return true;
}

//Funcion para agregar y reservar un dato en la memoria de programa
bool agregar_dato_prg(int dato, int num_lin) {
  //Primeramente determina si la direccion actual excede el limite de la memoria disponible
  if (pos_prg >= tam_prg) {
    //De exceder el limite, regresa con mensaje de error
    msg_fin_prg(num_lin);
    return false;
  }

  //Luego determina si la localidad esta libre
  if (!(datos_prg[pos_prg] & MASC_LIBRE)) {
    //De no estar libre, regresa con mensaje de error
    msg_colision_prg(num_lin, pos_prg);
    return false;
  }

  //Si todo esta bien, guarda el dato en la memoria de programa y desmarca la localidad como disponible
  datos_prg[pos_prg] = dato;
  pos_prg++;                    //Apunta a la siguiente posicion de la memoria
  return true;
}
