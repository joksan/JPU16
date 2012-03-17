//+-----------------------------------------------------------------------------------------------+
//| j16asm_messages.c                                                                             |
//| Modulo de generacion de archivos de salida en lenguaje VHDL (Generico)                        |
//|                                                                                               |
//| Este modulo implementa las funciones de creacion de archivos en lenguaje VHDL que implementan |
//| la logica de las memorias de programa y datos, incluyendo al mismo tiempo los datos iniciales |
//| que deberan contener para poder ejecutar un programa previamente definido en el codigo fuente |
//| que se le pasa al ensamblador.                                                                |
//| Notese que el codigo generado es de caracter generico, es decir, no hace uso de ninguna       |
//| primitiva especifica al FPGA, como pudieran ser bloques de RAM. En vez, la logica generada es |
//| tal que dichos bloques de RAM son inferidos automaticamente. Esto trae la ventaja de que el   |
//| codigo VHDL generado es altamente portable entre distintas plataformas, pero al mismo tiempo  |
//| requiere que se hagan sintesis completas al actualizar el codigo fuente del programa, lo cual |
//| consume tiempo.                                                                               |
//+-----------------------------------------------------------------------------------------------+
#include <stdio.h>              //Permite invocar las funciones de manejo de archivos
#include "j16asm_output_vhdl.h" //Cabecera propia
#include "j16asm.h"             //Importa los arreglos con los datos de memoria
#include "j16asm_messages.h"    //Permite generar mensajes de error

//+----------------------------------+
//| Plantillas de codigo fuente VHDL |
//+----------------------------------+-------------------------------------------------------------
//Denotacion de los prefijos de las plantillas:
//  "plantilla: Codigo generado sin parametros modificables (estatico)
//  "codigo: Codigo generado con parametros modificables (dinamico)
//Denotacion de los sufijos:
//  "u":  codigo generado incondicionalmente para instancias unicas de bloques de RAM
//  "m":  codigo generado incondicionalmente para multiples instancias de bloques de RAM
//  "mo": codigo generado opcionalmente para multiples instancias de bloques de RAM

//-------------------------------------------------------------------------------------------------
static const char plantilla_vhdl_0[] =
"---------------------------------------------------------------\n"
"-- Paquete con las definiciones de los tamaños de la memoria --\n"
"---------------------------------------------------------------\n"
"package JPU16_MEM_SIZE_DEFS is\n";
//-------------------------------------------------------------------------------------------------

static const char codigo_vhdl_0[] =
"   constant nBits_DirProg: integer := %i;\n"
"   constant nBits_DirDatos: integer := %i;\n";

//-------------------------------------------------------------------------------------------------
static const char plantilla_vhdl_1[] =
"end JPU16_MEM_SIZE_DEFS;\n"
"\n"
"---------------------------------------\n"
"-- Entidad de la memoria de programa --\n"
"---------------------------------------\n"
"library IEEE;\n"
"use IEEE.STD_LOGIC_1164.ALL;\n"
"use IEEE.STD_LOGIC_ARITH.ALL;\n"
"use IEEE.STD_LOGIC_UNSIGNED.ALL;\n"
"use work.JPU16_MEM_SIZE_DEFS.all;\n"
"\n"
"entity JPU16_PROG_MEM is\n"
"   generic (nBits_BusProg: integer := 26);\n"
"   Port (SysClk:    in  STD_LOGIC;\n"
"         SysHold:   in  STD_LOGIC;\n"
"         CicloInst: in  STD_LOGIC;\n"
"         Direccion: in  STD_LOGIC_VECTOR (nBits_DirProg - 1 downto 0);\n"
"         DatoProg:  out STD_LOGIC_VECTOR (nBits_BusProg - 1 downto 0) := (others => '0'));\n"
"end JPU16_PROG_MEM;\n"
"\n"
"architecture Funcionamiento of JPU16_PROG_MEM is\n"
"   type PROG_DATA is array (2**nBits_DirProg-1 downto 0) of\n"
"      STD_LOGIC_VECTOR (nBits_BusProg-1 downto 0);\n"
"\n"
"   constant MemoriaProg: PROG_DATA := (\n";

static const char plantilla_vhdl_2[] =
"   );\n"
"begin\n"
"   process (SysClk)\n"
"   begin\n"
"      if rising_edge(SysClk) then\n"
"         if CicloInst = '0' and SysHold = '0' then\n"
"            DatoProg  <= MemoriaProg(conv_integer(Direccion));\n"
"         end if;\n"
"      end if;\n"
"   end process;\n"
"end Funcionamiento;\n"
"\n"
"-------------------------------\n"
"-- Entidad de la memoria RAM --\n"
"-------------------------------\n"
"library IEEE;\n"
"use IEEE.STD_LOGIC_1164.ALL;\n"
"use IEEE.STD_LOGIC_ARITH.ALL;\n"
"use IEEE.STD_LOGIC_UNSIGNED.ALL;\n"
"use WORK.JPU16_MEM_SIZE_DEFS.ALL;\n"
"\n"
"entity JPU16_RAM is\n"
"   generic (nBits_BusDatos: integer := 16);\n"
"   port (SysClk:    in  STD_LOGIC;\n"
"         SysHold:   in  STD_LOGIC;\n"
"         Ren:       in  STD_LOGIC;\n"
"         Wen:       in  STD_LOGIC;\n"
"         Direccion: in  STD_LOGIC_VECTOR (nBits_DirDatos-1 downto 0);\n"
"         DatoEnt:   in  STD_LOGIC_VECTOR (nBits_BusDatos-1 downto 0);\n"
"         DatoSal:   out STD_LOGIC_VECTOR (nBits_BusDatos-1 downto 0) := (others => '0'));\n"
"end JPU16_RAM;\n"
"\n"
"architecture Funcionamiento of JPU16_RAM is\n"
"   type RAM_DATA is array (2**nBits_DirDatos-1 downto 0) of\n"
"      STD_LOGIC_VECTOR (nBits_BusDatos-1 downto 0);\n"
"\n"
"   signal MemoriaRam: RAM_DATA := (\n";

static const char plantilla_vhdl_3[] =
"   );\n"
"begin\n"
"   process (SysClk)\n"
"   begin\n"
"      if rising_edge(SysClk) then\n"
"         if SysHold = '0' and (Ren = '1' or Wen = '1') then\n"
"            if Wen = '1' then\n"
"               MemoriaRam(conv_integer(Direccion)) <= DatoEnt;\n"
"            end if;\n"
"            DatoSal <= MemoriaRam(conv_integer(Direccion));\n"
"         end if;\n"
"      end if;\n"
"   end process;\n"
"end Funcionamiento;";
//-------------------------------------------------------------------------------------------------

//Declaracion previa de las funciones locales al modulo
static void generar_datos_prg(FILE *fp_archivo);
static void generar_datos_ram(FILE *fp_archivo);

//+------------------------------+
//| Inicio del codigo del modulo |
//+------------------------------+-----------------------------------------------------------------
//Funcion para generar los datos de salida del ensamblador en formato VHDL
bool generar_salida_vhdl() {
  FILE *fp_archivo = NULL;
  int i;
  int nbits_dir_prg;
  int nbits_dir_ram;

  //Primeramente se crea el archivo de salida
  fp_archivo = fopen(nombre_archivo_vhd, "w");
  if (!fp_archivo) {
    msg_error_crear_archivo_salida(nombre_archivo_vhd);
    return false;
  }

  //Se determina la cantidad de bits que contendra el bus de direcciones de programa
  nbits_dir_prg = 0;  //Inicia la cuenta a 0
  for (i=tam_prg; i>>=1; nbits_dir_prg++);

  //Se determina la cantidad de bits que contendra el bus de direcciones de RAM
  nbits_dir_ram = 0;
  for (i=tam_ram; i>>=1; nbits_dir_ram++);

  //Generacion del codigo VHDL asociado al paquete con las definiciones de tamaños
  //-----------------------------------------------------------------------------------------------

  //Se procede a escribir la plantilla inicial
  fprintf(fp_archivo, plantilla_vhdl_0);

  //Se escriben las lineas de codigo con las dimensiones de la memoria
  fprintf(fp_archivo, codigo_vhdl_0, nbits_dir_prg, nbits_dir_ram);

  //Generacion del codigo VHDL asociado a la memoria de programa
  //-----------------------------------------------------------------------------------------------

  //Se escribe la plantilla con la definicion de entidad y arquitectura de la memoria de programa
  fprintf(fp_archivo, plantilla_vhdl_1);

  //Se generan las constantes con los datos de la memoria de programa
  generar_datos_prg(fp_archivo);

  //Se escribe la plantilla con la definicion de la parte operativa de la arquitectura de la
  //memoria de programa y la apertura de la definicion de la memoria RAM del procesador
  fprintf(fp_archivo, plantilla_vhdl_2);

  //Generacion del codigo VHDL asociado a la memoria RAM
  //-----------------------------------------------------------------------------------------------

  //Se generan las constantes con los datos iniciales de la memoria RAM
  generar_datos_ram(fp_archivo);

  //Se escribe la plantilla con la definicion de la parte operativa de la arquitectura
  fprintf(fp_archivo, plantilla_vhdl_3);

  //Al final del proceso, cierra el archivo
  fclose(fp_archivo);
  return true;                //Retorna con exito
}

//Funcion para generar los datos de inicializacion de los bloques de RAM con el programa
void generar_datos_prg(FILE *fp_archivo) {
  int i;
  int pos_mem;

  for (pos_mem=0; pos_mem<tam_prg; pos_mem++) {
    //Verifica si la localidad de programa esta usada
    if (!(datos_prg[pos_mem] & MASC_LIBRE)) {
      //De estar usada, escribe el inicio de la linea con su direccion
      fprintf(fp_archivo, "      %i => B\"", pos_mem);

      //Luego escribe el codigo de operacion en notacion binaria con separadores
      for (i=25; i>=0; i--) {
        fprintf(fp_archivo, "%i", (datos_prg[pos_mem] & 1 << i) != 0);
        if (i == 16 || i == 20) fprintf(fp_archivo, "_");
      }

      //Escribe el final de la linea
      fprintf(fp_archivo, "\",\n");
    }
  }

  //Agrega la linea que rellena las localidades sin usar
  fprintf(fp_archivo, "      others => B\"000000_0000_0000000000000000\"\n");
}

//Funcion para generar los datos de inicializacion de los bloques de RAM con los datos
void generar_datos_ram(FILE *fp_archivo) {
  int pos_mem;

  for (pos_mem=0; pos_mem<tam_ram; pos_mem++) {
    //Verifica si la localidad de RAM esta usada
    if (!(datos_ram[pos_mem] & MASC_LIBRE))
      //De estar usada, escribe su contenido
      fprintf(fp_archivo, "      %i => X\"%.4X\",\n", pos_mem, datos_ram[pos_mem]);
  }

  //Agrega la linea que rellena las localidades sin usar
  fprintf(fp_archivo, "      others => X\"0000\"\n");
}