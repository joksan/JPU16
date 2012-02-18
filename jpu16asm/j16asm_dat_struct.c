//+-----------------------------------------------------------------------------------------------+
//| j16asm_dat_struct.c                                                                           |
//| Modulo con las implementaciones de las estructuras de datos: Cola de operaciones, pila de     |
//| datos y lista de simbolos                                                                     |
//|                                                                                               |
//| Este modulo implementa las estructuras de datos que usa el ensamblador. La cola de            |
//| operaciones guarda todas las operaciones que no pueden efectuarse en el paso 1 de compilacion |
//| y que deben postergarse a el paso 2. La pila de datos almacena los resultados parciales de    |
//| los calculos temporales (guardados en la cola de operaciones con notacion polaca inversa).    |
//| La lista de simbolos guarda todos los nombres de aquellas constantes, etiquetas de datos      |
//| (variables) y etiquetas de programa que aparecen en el codigo fuente, junto con sus valores   |
//| equivalentes (el valor de las constantes o las direcciones de las etiquetas).                 |
//| Notese que este modulo solo implementa las estructuras de datos en si y se limita a ello,     |
//| quedando la logica general de su operacion a cargo del resto de las partes del programa.      |
//|                                                                                               |
//| Nota acerca del alojamiento de las cadenas                                                    |
//| Las funciones encolar_simbolo() y agregar_simbolo() no crean copias de las cadenas que        |
//| reciben, a pesar de que alojan memoria dinamica para los elementos que crean (solo copian los |
//| punteros de dichas cadenas). Esto es asi por motivos de eficiencia, para evitar crear 2       |
//| copias consecutivas de las cadenas y terminar por desalojar una de ellas al dejar de          |
//| utilizarla. En vez, la responsabilidad de desalojar las cadenas es trasladada a la estructura |
//| de datos asociada a cada funcion (cola de acciones o lista de simbolos).                      |
//| Notese tambien que las cadenas que recibe cada funcion provienen de origenes distintos por    |
//| cuanto al analizador sintactico se refiere, dado que las que van a parar a la cola de         |
//| acciones son referencias a simbolos que aun no han sido declarados en el codigo fuente,       |
//| mientras que las que van a parar a la lista de simbolos provienen de sus mismas               |
//| declaraciones.                                                                                |
//+-----------------------------------------------------------------------------------------------+
#include <stdlib.h>             //Permite invocar malloc y free
#include <string.h>             //Permite manejar cadenas
#include <stdbool.h>            //Incluye la definicion del tipo de dato bool
#include "j16asm_dat_struct.h"  //Cabecera propia

//Tipos y variables usados para la cola de acciones (cola fifo)
typedef struct _COLA_ACCIONES_PASO_2 {
  ACCION_PASO_2 *inicio;        //Puntero al inicio de la lista (util para retirar elementos)
  ACCION_PASO_2 *final;         //Puntero al final de la lista (util para agregar elementos)
} COLA_ACCIONES_PASO_2;

static COLA_ACCIONES_PASO_2 cola_acciones = { NULL, NULL };    //La cola se inicializa vacia

//Tipos y variables usados para la pila de datos
typedef struct _DATO_PILA {
  int valor;                    //Valor almacenado
  struct _DATO_PILA *siguiente; //Puntero al elemento siguiente (util para desapilar datos)
} DATO_PILA;

static DATO_PILA *cima_pila = NULL;    //La pila se inicializa vacia

//Tipos y variables usados para la lista de simbolos
typedef struct _LISTA_SIMBOLOS {
  SIMBOLO *inicio;              //Puntero al inicio de la lista (util para comenzar a recorrerla)
  SIMBOLO *final;               //Puntero al final de la lista (util para agregar elementos)
} LISTA_SIMBOLOS;

static LISTA_SIMBOLOS lista_simbolos = { NULL, NULL }; //La lista se inicializa vacia

//Declaracion previa de las funciones locales al modulo
static void encolar(ACCION_PASO_2 *nueva_accion);

//+---------------------------------------------+
//| Operaciones asociadas a la cola de acciones |
//+---------------------------------------------+--------------------------------------------------
//Funcion general para encolar acciones (solo gestiona memoria)
static void encolar(ACCION_PASO_2 *nueva_accion) {
  //Como se agregara un elemento a la cola, se asegura que el siguiente sea nulo
  nueva_accion->siguiente = NULL;

  //Si la cola esta vacia, hace que el inicio apunte al nuevo elemento
  if (!cola_acciones.inicio)
    cola_acciones.inicio = nueva_accion;
  //Si la cola no esta vacia, agrega el nuevo elemento al final de la misma
  else
    cola_acciones.final->siguiente = nueva_accion;

  //El final de la cola siempre apuntara al nuevo elemento agregado
  cola_acciones.final = nueva_accion;
}

//Funcion especifica para encolar literales (cuando se retiran, su valor es apilado)
void encolar_literal(int valor, int num_lin) {
  ACCION_PASO_2 *nueva_accion;

  //Aloja memoria para el nuevo elemento de la cola
  nueva_accion = malloc(sizeof(ACCION_PASO_2));
  //Establece el tipo de accion para el nuevo elemento
  nueva_accion->tipo = TPA_APILAR_LITERAL;
  //Hace una copia del valor pasado
  nueva_accion->valor = valor;
  //Tambien copia el numero de linea
  nueva_accion->num_lin = num_lin;

  //Finalmente encola el elemento
  encolar(nueva_accion);
}

//Funcion especifica para encolar simbolos (cuando se retiran, su valor equivalente es apilado)
void encolar_simbolo(char *nombre, int num_lin) {
  ACCION_PASO_2 *nueva_accion;

  nueva_accion = malloc(sizeof(ACCION_PASO_2));
  nueva_accion->tipo = TPA_APILAR_SIMBOLO;
  nueva_accion->nombre = nombre;
  //NOTA: El puntero de la cadena solo se traslada. No se hace una copia a una nueva locacion de
  //memoria por motivos de eficiencia y por el hecho que la cadena sera desalojada automaticamente
  //cuando se desaloje la accion de la cola
  nueva_accion->num_lin = num_lin;

  encolar(nueva_accion);
}

//Funcion especifica para encolar operaciones (cuando se retiran, trabajan sobre datos de pila)
void encolar_operacion(OPERACION op, int num_lin) {
  ACCION_PASO_2 *nueva_accion;

  nueva_accion = malloc(sizeof(ACCION_PASO_2));
  nueva_accion->tipo = TPA_OPERACION_ARITMETICA;
  nueva_accion->op = op;
  nueva_accion->num_lin = num_lin;

  encolar(nueva_accion);
}

//Funcion especifica para encolar almacenamientos a RAM (cuando se retiran, se guarda el dato de
//arriba de la pila en el espacio de RAM de JPU16)
void encolar_resultado_ram(int direccion, int num_lin) {
  ACCION_PASO_2 *nueva_accion;

  nueva_accion = malloc(sizeof(ACCION_PASO_2));
  nueva_accion->tipo = TPA_GUARDAR_RESULTADO_RAM;
  nueva_accion->direccion = direccion;
  nueva_accion->num_lin = num_lin;

  encolar(nueva_accion);
}

//Funcion especifica para encolar almacenamientos a memoria de programa (cuando se retiran, se
//guarda el dato de arriba de la pila en el espacio de programa de JPU16)
void encolar_resultado_prg(int direccion, int num_lin) {
  ACCION_PASO_2 *nueva_accion;

  nueva_accion = malloc(sizeof(ACCION_PASO_2));
  nueva_accion->tipo = TPA_GUARDAR_RESULTADO_PRG;
  nueva_accion->direccion = direccion;
  nueva_accion->num_lin = num_lin;

  encolar(nueva_accion);
}

//Funcion para desencolar acciones (retira el elemento de la cola y lo retorna)
ACCION_PASO_2 *desencolar_accion() {
  ACCION_PASO_2 *elemento;

  //Verifica que la cola tenga elementos antes de intentar removerlos
  if (!cola_acciones.inicio) return NULL;
  //Toma el primer elemento disponible de la cola
  elemento = cola_acciones.inicio;
  //Hace que el nuevo inicio de la cola sea el siguiente elemento
  cola_acciones.inicio = elemento->siguiente;

  //Retorna el elemento obtenido
  return elemento;
}

//Funcion para desalojar elementos retirados de la cola
void desalojar_accion(ACCION_PASO_2 *accion) {
  //Si la accion era de apilar el nombre de un simbolo, desaloja la cadena asociada
  if (accion->tipo == TPA_APILAR_SIMBOLO)
    free(accion->nombre);
  //NOTA: AQUI SE DESALOJAN LAS CADENAS CREADAS CON strdup() DURANTE LA ETAPA DE ANALISIS LEXICO

  //Luego desaloja la accion en si
  free(accion);
}

//+------------------------------------------+
//| Operaciones asociadas a la pila de datos |
//+------------------------------------------+-----------------------------------------------------
//Funcion para agregar datos a la pila
void apilar_dato(int valor) {
  DATO_PILA *nuevo_dato;

  //Aloja memoria para el nuevo elemento de la pila
  nuevo_dato = malloc(sizeof(DATO_PILA));
  //Asigna el valor que contendra el nuevo dato
  nuevo_dato->valor = valor;
  //Hace que el nuevo dato apunte a la vieja cima de la pila
  nuevo_dato->siguiente = cima_pila;
  //La nueva cima de la pila es el dato recien agregado
  cima_pila = nuevo_dato;
}

//Funcion para retirar datos de la pila
bool desapilar_dato(int *valor) {
  DATO_PILA *dato_retirado;

  //Si la pila esta vacia, no retorna nada
  if (!cima_pila) return false;
  //Obtiene el elemento en la cima de la pila
  dato_retirado = cima_pila;
  //La nueva cima de la pila es el siguiente elemento apuntado por el elemento retirado
  cima_pila = dato_retirado->siguiente;
  //Obtiene el valor almacenado en el elemento
  *valor = dato_retirado->valor;
  //Libera la memoria usada por el elemento
  free(dato_retirado);

  //Como todo salio bien, retorna con exito
  return true;
}

//+----------------------------------------------+
//| Operaciones asociadas a la lista de simbolos |
//+----------------------------------------------+-------------------------------------------------
//Funcion para agregar elementos a la lista de simbolos
void agregar_simbolo(char *nombre, int valor, int num_lin) {
  SIMBOLO *nuevo_simbolo;

  //Aloja memoria para el nuevo simbolo
  nuevo_simbolo = malloc(sizeof(SIMBOLO));
  //Copia la informacion del nuevo simbolo
  nuevo_simbolo->nombre = nombre;
  //NOTA: El puntero de la cadena solo se traslada. No se hace una copia a una nueva locacion de
  //memoria por motivos de eficiencia y por el hecho que la cadena sera desalojada automaticamente
  //cuando se desaloje el simbolo de la lista
  nuevo_simbolo->valor = valor;
  //Como se agregara un simbolo a la lista, se asegura que el siguiente sea nulo
  nuevo_simbolo->siguiente = NULL;

   //Si la lista esta vacia, hace que el inicio apunte al nuevo elemento
  if (!lista_simbolos.inicio)
    lista_simbolos.inicio = nuevo_simbolo;
  //Si la lista no esta vacia, agrega el nuevo elemento al final de la misma
  else
    lista_simbolos.final->siguiente = nuevo_simbolo;

  //El nuevo final de la lista apunta al nuevo simbolo
  lista_simbolos.final = nuevo_simbolo;
}

//Funcion de busqueda para la lista de simbolos
SIMBOLO *buscar_simbolo(char *nombre) {
  SIMBOLO *p_simbolo;

  //Inicia la busqueda con el inicio de la lista
  p_simbolo = lista_simbolos.inicio;
  while (p_simbolo) {
    //Si el nombre del simbolo buscado coincide con la entrada actual, detiene el proceso
    if (strcmp(p_simbolo->nombre, nombre) == 0) break;
    //Caso contrario prueba con el siguiente de la lista
    p_simbolo = p_simbolo->siguiente;
  }

  //Al final del proceso retorna el simbolo encontrado (si lo hubo)
  return p_simbolo;
}

//Funcion para desalojar simultaneamente todos los simbolos de la lista
void desalojar_simbolos() {
  SIMBOLO *p_siguiente_simbolo;

  //Comienza desde el inicio de la lista
  p_siguiente_simbolo = lista_simbolos.inicio;
  while (p_siguiente_simbolo) {
    //Primero se obtiene el siguiente elemento
    p_siguiente_simbolo = lista_simbolos.inicio->siguiente;
    //Luego desaloja el inicio de la lista
    //NOTA: AQUI SE DESALOJAN LAS CADENAS CREADAS CON strdup() DURANTE LA ETAPA DE ANALISIS LEXICO
    free(lista_simbolos.inicio->nombre);
    free(lista_simbolos.inicio);
    //Se reubica el nuevo inicio de la lista
    lista_simbolos.inicio = p_siguiente_simbolo;
  }
}
