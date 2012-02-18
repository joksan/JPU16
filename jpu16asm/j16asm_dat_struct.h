#ifndef j16asm_dat_struct_h_Incluida
#define j16asm_dat_struct_h_Incluida

#include <stdbool.h>                    //Incluye la definicion del tipo de dato bool

//Tipos de datos exportados
//-------------------------
//Enumeracionn de todas las operaciones que pueden entrar a la cola
typedef enum _OPERACION {
  OPER_OR, OPER_XOR, OPER_AND,
  OPER_SHL, OPER_SHR,
  OPER_SUM, OPER_RES,
  OPER_MUL, OPER_DIV, OPER_MOD,
  OPER_NEG, OPER_NOT,
  OPER_EXP,
  //Nota: Los parentesis no estan incluidos porque no generan operaciones relevantes en la pila
} OPERACION;

//Esta bandera combinada con la enumeracion anterior (mediante OR) indica si se deben intercambiar
//los argumentos al operar (permite compensar la entrada invertida de los argumentos a la pila)
#define OPER_INTERCAMBIO 0x10000
#define MASC_OPER        0x0FFFF        //Mascara que permite aislar la operacion en si

//Enumeracion de los tipos de accion que pueden entrar a la cola
typedef enum _TIPO_ACCION {
  TPA_APILAR_LITERAL,           //Operacion de colocar literal en la pila
  TPA_APILAR_SIMBOLO,           //Operacion de colocar simbolo (su valor equivalente) en la pila
  TPA_OPERACION_ARITMETICA,     //Operacion de realizar una operacion aritmetica
  TPA_GUARDAR_RESULTADO_RAM,    //Operacion de guardar resultado en la memoria RAM de JPU16
  TPA_GUARDAR_RESULTADO_PRG,    //Operacion de guardar resultado en memoria de programa de JPU16
} TIPO_ACCION;

//Estructura que describe una accion en la cola de acciones
typedef struct _ACCION_PASO_2 {
  TIPO_ACCION tipo;     //Tipo de accion
  union {               //Valor asociado segun el tipo de accion
    int valor;          //El valor del literal a apilar
    char *nombre;       //El nombre del simbolo a apilar
    OPERACION op;       //El tipo de operacion a realizar
    int direccion;      //La direccion de RAM o programa donde se almacenara el resultado
  };
  int num_lin;          //Numero de linea donde aparece la accion (util para reportar errores)
  struct _ACCION_PASO_2 *siguiente;     //Siguiente elemento de la cola
} ACCION_PASO_2;

//Estructura que describe una entrada de la lista de simbolos
typedef struct _SIMBOLO {
  char *nombre;                 //Nombre del simbolo almacenado (usa memoria dinamica)
  int valor;                    //Valor equivalente del simbolo (valor de la constante o direccion)
  struct _SIMBOLO *siguiente;   //Puntero al elemento siguiente (util para recorrer la lista)
} SIMBOLO;

//Funciones exportadas
//--------------------
//Funciones asociadas a la cola de operaciones
extern void encolar_literal(int valor, int num_lin);
extern void encolar_simbolo(char *nombre, int num_lin);
extern void encolar_operacion(OPERACION op, int num_lin);
extern void encolar_resultado_ram(int direccion, int num_lin);
extern void encolar_resultado_prg(int direccion, int num_lin);
extern ACCION_PASO_2 *desencolar_accion();
extern void desalojar_accion(ACCION_PASO_2 *accion);

//Funciones asociadas a la pila de datos
extern void apilar_dato(int valor);
extern bool desapilar_dato(int *valor);

//Funciones asociadas a la lista de simbolos
extern void agregar_simbolo(char *nombre, int valor, int num_lin);
extern SIMBOLO *buscar_simbolo(char *nombre);
extern void desalojar_simbolos();

#endif //j16asm_dat_struct_h_Incluida
