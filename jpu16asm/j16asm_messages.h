#ifndef j16asm_messages_h_Incluida
#define j16asm_messages_h_Incluida

#include "j16asm_dat_struct.h"

//Mensajes generados por el modulo principal
extern void msg_exito_etapa(int n);
extern void msg_mem_prg_usada(int n);
extern void msg_mem_ram_usada(int n);
extern void msg_lc_ayuda_invocacion();
extern void msg_lc_error_argumentos_faltantes();
extern void msg_lc_error_argumento_invalido(const char *argumento);
extern void msg_lc_error_capacidad_ram(int num_pal);
extern void msg_lc_error_capacidad_prg(int num_inst);
extern void msg_error_abrir_archivo_entrada();
extern void msg_error_crear_archivo_salida(const char *nombre_archivo);
extern void msg_fin_ram(int num_lin);
extern void msg_colision_ram(int num_lin, int pos_ram);
extern void msg_fin_prg(int num_lin);
extern void msg_colision_prg(int num_lin, int pos_prg);
extern void msg_simbolo_no_definido(int num_lin, const char *nombre);

//Mensajes generados por el analizador sintactico
extern void msg_expr_simbolo_no_definido(int num_lin);
extern void msg_simbolo_redefinido(int num_lin, const char *nombre);
extern void msg_datos_seccion_incorrecta(int num_lin);
extern void msg_instr_seccion_incorrecta(int num_lin);
extern void msg_error_sintaxis(int num_lin);

//Funciones para mensajes de depuracion solamente
//extern void msg_error_archivo(int num_lin, const char *mensaje, const char *elemento);
//extern void msg_error_interno(const char *mensaje);
//extern void msg_encolar_accion(ACCION_PASO_2 *accion);
//extern void msg_realizar_accion(ACCION_PASO_2 *accion);
//extern void msg_apilar(int valor);
//extern void msg_desapilar(int valor);
//extern void msg_desalojar_simbolo(char *nombre, int valor);

#endif //j16asm_messages_h_Incluida