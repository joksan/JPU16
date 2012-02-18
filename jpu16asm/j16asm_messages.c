//+-----------------------------------------------------------------------------------------------+
//| j16asm_messages.c                                                                             |
//| Modulo de impresion de mensajes del programa                                                  |
//|                                                                                               |
//| En este modulo se agrupan todas las funciones que se encargan de imprimir los mensajes que    |
//| genera el ensamblador. Esto se hace de esta manera para facilitar la ubicacion de todos los   |
//| mensajes en vista a la posible internacionalizacion del programa.                             |
//+-----------------------------------------------------------------------------------------------+
#include <stdio.h>            //Permite invocar la funcion printf
#include "j16asm_messages.h"  //Cabecera propia
#include "j16asm.h"           //Permite el acceso al nombre del archivo procesado

//Mensajes generados por el modulo principal
//------------------------------------------
void msg_exito_etapa(int n) {
  switch (n) {
  case 1: printf("Primera etapa: OK\n"); break;
  case 2: printf("Segunda etapa: OK\n"); break;
  case 3: printf("Operacion realizada con exito.\n"); break;
  }
}

void msg_mem_prg_usada(int n) {
  printf(" - %i instrucciones en total\n", n);
}

void msg_mem_ram_usada(int n) {
  printf(" - %i palabras en total\n", n);
}

void msg_lc_ayuda_invocacion() {
  printf("Forma de uso: jpu16asm codigo_fuente [opciones]\n"
         "  opciones:\n"
         "    -v  archivo     Genera la salida en formato vhdl normal\n"
         "    -vr archivo     Genera la salida en formato vhdl usando primitivas RAMB16\n"
         "                    (para poder actualizar programas sin realizar sintesis)\n"
         "    -m  archivo     Genera la salida en formato MEM\n"
         "    -b  archivo     Genera un mapa de los bloques de RAM (RAMB16) en formato BMM\n"
         "    -p  numero      Especifica la capacidad de la memoria de programa\n"
         "                    (512 instrucciones por defecto)\n"
         "    -r  numero      Especifica la capacidad de la memoria RAM\n"
         "                    (1024 palabras por defecto)\n"
         "  Se puede invocar jpu16asm sin opciones para solo hacer un chequeo sintactico\n");
}

void msg_lc_error_argumentos_faltantes() {
  printf("Error: faltan argumentos\n");
  msg_lc_ayuda_invocacion();
}

void msg_lc_error_argumento_invalido(const char *argumento) {
  printf("Error: argumento invalido: %s\n", argumento);
  msg_lc_ayuda_invocacion();
}

void msg_lc_error_capacidad_ram(int num_pal) {
  printf("Error: Capacidad de memoria de RAM no valida: %i palabras\n", num_pal);
  printf("Las cantidades validas son 1024, 2048, 4096, 8192, 16384 y 32768 palabras\n");
}

void msg_lc_error_capacidad_prg(int num_inst) {
  printf("Error: Capacidad de memoria de programa no valida: %i instrucciones\n", num_inst);
  printf("Las cantidades validas son 512, 1024, 2048, 4096, 8192 y 16384 instrucciones\n");
}

void msg_error_abrir_archivo_entrada() {
  printf("Error al abrir el archivo: %s\n", nombre_archivo_ent);
}

void msg_error_crear_archivo_salida(const char *nombre_archivo) {
  printf("Error al crear el archivo: %s\n", nombre_archivo);
}

void msg_fin_ram(int num_lin) {
  printf("%s:%i: Error: Final de la memoria ram sobrepasado (%i palabras)\n",
         nombre_archivo_ent, num_lin, tam_ram);
}

void msg_colision_ram(int num_lin, int pos_ram) {
  printf("%s:%i: Error al ubicar el dato en la direccion 0x%.4X - La localidad ya esta en uso\n",
         nombre_archivo_ent, num_lin, pos_ram);
}

void msg_fin_prg(int num_lin) {
  printf("%s:%i: Error: Final de la memoria de programa sobrepasado (%i instrucciones)\n",
         nombre_archivo_ent, num_lin, tam_prg);
}

void msg_colision_prg(int num_lin, int pos_prg) {
  printf("%s:%i: Error al ubicar la instruccion en la direccion 0x%.4X - La localidad ya esta en uso\n",
         nombre_archivo_ent, num_lin, pos_prg);
}

void msg_simbolo_no_definido(int num_lin, const char *nombre) {
  printf("%s:%i: Error: simbolo no definido: %s\n", nombre_archivo_ent, num_lin, nombre);
}

//Mensajes generados por el analizador sintactico
//-----------------------------------------------
void msg_expr_simbolo_no_definido(int num_lin) {
  printf("%s:%i: Error en la expresion: uno o mas simbolos aun no han sido definidos\n", nombre_archivo_ent, num_lin);
}

void msg_simbolo_redefinido(int num_lin, const char *nombre) {
  printf("%s:%i: Error: Simbolo redefinido: %s\n", nombre_archivo_ent, num_lin, nombre);
}

void msg_datos_seccion_incorrecta(int num_lin) {
  printf("%s:%i: Error: Dato definido fuera de seccion de datos\n", nombre_archivo_ent, num_lin);
}

void msg_instr_seccion_incorrecta(int num_lin) {
  printf("%s:%i: Error: Instruccion definida fuera de seccion de codigo\n", nombre_archivo_ent, num_lin);
}

void msg_error_sintaxis(int num_lin) {
  printf("%s:%i: Error de sintaxis\n", nombre_archivo_ent, num_lin);
}

//-----------------------------------------------
//Funciones para mensajes de depuracion solamente
//-----------------------------------------------
void msg_error_archivo(int num_lin, const char *mensaje, const char *elemento) {
  if (!elemento)
    printf("%s:%i: %s\n", nombre_archivo_ent, num_lin, mensaje);
  else
    printf("%s:%i: %s %s\n", nombre_archivo_ent, num_lin, mensaje, elemento);
}

void msg_error_interno(const char *mensaje) {
  printf("%s: Error interno del ensamblador: %s", nombre_archivo_ent, mensaje);
}

void msg_encolar_accion(ACCION_PASO_2 *accion) {
  switch (accion->tipo) {
  case TPA_APILAR_LITERAL:
    printf("encolar literal: %i\n", accion->valor);
    break;
  case TPA_APILAR_SIMBOLO:
    printf("encolar simbolo: %s\n", accion->nombre);
    break;
  case TPA_OPERACION_ARITMETICA:
    printf("encolar operacion: ");    

    switch (accion->op & MASC_OPER) {
    case OPER_OR:  printf("| ");   break;
    case OPER_XOR: printf("^ ");   break;
    case OPER_AND: printf("& ");   break;
    case OPER_SHL: printf("<< ");  break;
    case OPER_SHR: printf(">> ");  break;
    case OPER_SUM: printf("+ ");   break;
    case OPER_RES: printf("- ");   break;
    case OPER_MUL: printf("* ");   break;
    case OPER_DIV: printf("/ ");   break;
    case OPER_MOD: printf("%% ");  break;
    case OPER_NEG: printf("NEG "); break;
    case OPER_NOT: printf("~ ");   break;
    case OPER_EXP: printf("** ");  break;
    default: printf("ERROR! ");    break;
    }

    if (accion->op & OPER_INTERCAMBIO) printf("(con intercambio)");
    printf("\n");
    break;
  case TPA_GUARDAR_RESULTADO_RAM:
    printf("encolar resultado hacia RAM: 0x%.4x\n", accion->direccion);
    break;
  case TPA_GUARDAR_RESULTADO_PRG:
    printf("encolar resultado hacia PRG: 0x%.4x\n", accion->direccion);
    break;
  }
}

void msg_realizar_accion(ACCION_PASO_2 *accion) {
  switch (accion->tipo) {
  case TPA_APILAR_LITERAL:
    printf("apilar literal: %i\n", accion->valor);
    break;
  case TPA_APILAR_SIMBOLO:
    printf("apilar simbolo: %s\n", accion->nombre);
    break;
  case TPA_OPERACION_ARITMETICA:
    printf("aplicar operacion: ");    

    switch (accion->op & MASC_OPER) {
    case OPER_OR:  printf("| ");   break;
    case OPER_XOR: printf("^ ");   break;
    case OPER_AND: printf("& ");   break;
    case OPER_SHL: printf("<< ");  break;
    case OPER_SHR: printf(">> ");  break;
    case OPER_SUM: printf("+ ");   break;
    case OPER_RES: printf("- ");   break;
    case OPER_MUL: printf("* ");   break;
    case OPER_DIV: printf("/ ");   break;
    case OPER_MOD: printf("%% ");  break;
    case OPER_NEG: printf("NEG "); break;
    case OPER_NOT: printf("~ ");   break;
    case OPER_EXP: printf("** ");  break;
    default: printf("ERROR! ");    break;
    }

    if (accion->op & OPER_INTERCAMBIO) printf("(con intercambio)");
    printf("\n");
    break;
  case TPA_GUARDAR_RESULTADO_RAM:
    printf("desapilar resultado hacia RAM @ 0x%.4x\n", accion->direccion);
    break;
  case TPA_GUARDAR_RESULTADO_PRG:
    printf("desapilar resultado hacia PRG @ 0x%.4x\n", accion->direccion);
    break;
  }
}

void msg_apilar(int valor) {
  printf("Apilar: %i\n", valor);
}

void msg_desapilar(int valor) {
  printf("Desapilar: %i\n", valor);
}

void msg_desalojar_simbolo(char *nombre, int valor) {
  printf("Desalojando simbolo: %s (0x%.4X)\n", nombre, valor);
}
