#ifndef j16asm_h_Incluida
#define j16asm_h_Incluida

#include <stdbool.h>                    //Incluye la definicion del tipo de dato bool

//Variables exportadas
//--------------------
#define MASC_LIBRE 0x80000000       //Mascara de bits que define si una localidad de RAM o programa esta libre
extern char nombre_archivo_ent[];   //Nombre del archivo de entrada
extern char nombre_archivo_vhd[];   //Nombre del archivo que se genera en formato vhdl
extern char nombre_archivo_vhd_r[]; //Nombre del archivo que se genera en formato vhdl (RAMB16)
extern char nombre_archivo_mem[];   //Nombre del archivo que se genera en formato mem
extern char nombre_archivo_bmm[];   //Nombre del archivo que se genera en formato bmm
extern int tam_prg;                 //Cantidad maxima de instrucciones para la memoria de programa
extern int tam_ram;                 //Cantidad maxima de palabras para la memoria RAM
extern int datos_prg[];             //Arreglo con el espacio de datos de la memoria de programa
extern int datos_ram[];             //Arreglo con el espacio de datos de la memoria RAM
extern int pos_prg;                 //Posicion actual en la memoria de programa
extern int pos_ram;                 //Posicion actual en la memoria RAM

//Funciones exportadas
//--------------------
//Funciones para agregar datos a la memoria RAM y de programa
extern bool agregar_dato_ram(int dato, int num_lin);
extern bool agregar_dato_prg(int dato, int num_lin);

#endif //j16asm_h_Incluida
