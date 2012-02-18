//+-----------------------------------------------------------------------------------------------+
//| j16asm_messages.c                                                                             |
//| Modulo de generacion de archivos de salida en formato MEM y BMM                               |
//|                                                                                               |
//| Este modulo implementa las funciones de generacion de archivos para 2 formatos de salida.     |
//| El formato MEM contiene los datos de la memoria de programa y datos que deberan contener los  |
//| bloques de memoria del FPGA, en un formato legible que hace uso de numeracion hexadecimal,    |
//| mientras que el formato BMM contiene la distribucion de los bloques de memoria dentro de un   |
//| espacio global de direcciones, de tal forma que puedan ser identificados individualmente por  |
//| la utilidad data2mem de Xilinx a la hora de sustituir el contenido de los bloques de memoria  |
//| del FPGA.                                                                                     |
//+-----------------------------------------------------------------------------------------------+
#include <stdbool.h>                //Incluye la definicion del tipo de dato bool
#include <stdio.h>                  //Permite manejar archivos
#include "j16asm_output_mem_bmm.h"  //Cabecera propia
#include "j16asm.h"                 //Importa los arreglos con los datos de memoria
#include "j16asm_messages.h"        //Permite enviar mensajes al usuario

//+------------------------------+
//| Inicio del codigo del modulo |
//+------------------------------+-----------------------------------------------------------------
//Funcion de generacion de archivos con formato MEM (contenido para BRAM en hexadecimal)
bool generar_salida_mem() {
  FILE *fp_archivo = NULL;
  int i, j;
  const int DatosPorLineaPrg = 8;
  const int DatosPorLineaRam = 16;

  //Primeramente se crea el archivo de salida
  fp_archivo = fopen(nombre_archivo_mem, "w");
  if (!fp_archivo) {
    msg_error_crear_archivo_salida(nombre_archivo_mem);
    return false;
  }

  //Luego se rastrea la memoria de programa para generar los datos de salida (linea por linea)
  for (i=0; i<tam_prg; i+=DatosPorLineaPrg) {
    //Se genera el inicio de una linea de texto
    fprintf(fp_archivo, "@%.5X", i*4);

    //Se generan los datos que contiene la linea
    for (j=0; j<DatosPorLineaPrg; j++) {
      //Nota: El inicio de la linea actual es apuntado por la variable "i", pero la posicion dentro
      //de la linea es apuntada por la variable "j"
      fprintf(fp_archivo, " %.8X", datos_prg[i+j] & ~MASC_LIBRE);
    }

    //Se genera el final de la linea de texto
    fprintf(fp_archivo, "\n");
  }

  //En esta etapa se generan los datos correspondientes a la RAM (linea por linea tambien)
  for (i=0; i<tam_ram; i+=DatosPorLineaRam) {
    //Se genera el inicio de una linea de texto
    fprintf(fp_archivo, "@%.5X", i*2 + 0x10000);

    //Se generan los datos que contiene la linea
    for (j=0; j<DatosPorLineaRam; j++) {
      fprintf(fp_archivo, " %.4X", datos_ram[i+j] & ~MASC_LIBRE);
    }

    //Se genera el final de la linea de texto
    fprintf(fp_archivo, "\n");
  }

  //Al final del proceso, cierra el archivo
  fclose(fp_archivo);
  return true;                //Retorna con exito
}

//Funcion de generacion de archivos con formato BMM (mapas de memoria para BRAM)
bool generar_salida_bmm() {
  FILE *fp_archivo = NULL;
  int i;

  //Primeramente se crea el archivo de salida
  fp_archivo = fopen(nombre_archivo_bmm, "w");
  if (!fp_archivo) {
    msg_error_crear_archivo_salida(nombre_archivo_mem);
    return false;
  }

  //Luego se genera la cabecera del archivo, que contiene el tipo de procesador y su ID
  fprintf(fp_archivo, "ADDRESS_MAP JPU16 PPC405 0\n");

  //Se escribe la definicion del espacio de memoria para el programa
  fprintf(fp_archivo, "   ADDRESS_SPACE MemoriaPrograma RAMB16 [0x%.5X:0x%.5X]\n",
          0, tam_prg*4-1);

  //Se generan los bloques de bus para cada uno de los bloques de memoria de programa
  for (i=0; i<tam_prg/512; i++)
    fprintf(fp_archivo,
            "      BUS_BLOCK\n"
            "         CPU/PROG_MEM/MemoriaProg%i [31:0];\n"
            "      END_BUS_BLOCK;\n",
            i);

  //Se escribe el final de la definicion del espacio de memoria
  fprintf(fp_archivo, "   END_ADDRESS_SPACE;\n");

  //Se escribe la definicion del espacio de memoria para la RAM
  fprintf(fp_archivo, "   ADDRESS_SPACE MemoriaRam RAMB16 [0x%.5X:0x%.5X]\n",
          0x10000, 0x10000 + tam_ram*2 - 1);

  //Se generan los bloques de bus para cada uno de los bloques de la memoria de datos
  for (i=0; i<tam_ram/1024; i++)
    fprintf(fp_archivo,
            "      BUS_BLOCK\n"
            "         CPU/RAM/MemoriaRam%i [15:0];\n"
            "      END_BUS_BLOCK;\n",
            i);

  //Se escribe el final de la definicion del espacio de memoria
  fprintf(fp_archivo, "   END_ADDRESS_SPACE;\n");

  //Se escribe el final de la definicion del mapa de memoria
  fprintf(fp_archivo, "END_ADDRESS_MAP;");

  //Al final del proceso, cierra el archivo
  fclose(fp_archivo);
  return true;                //Retorna con exito
}