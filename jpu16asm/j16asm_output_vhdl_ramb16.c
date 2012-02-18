//+-----------------------------------------------------------------------------------------------+
//| j16asm_messages.c                                                                             |
//| Modulo de generacion de archivos de salida en lenguaje VHDL (usando primitivas RAMB16)        |
//|                                                                                               |
//| Este modulo implementa las funciones de creacion de archivos en lenguaje VHDL que implementan |
//| la logica de las memorias de programa y datos, incluyendo al mismo tiempo los datos iniciales |
//| que deberan contener para poder ejecutar un programa previamente definido en el codigo fuente |
//| que se le pasa al ensamblador.                                                                |
//| Notese que el codigo generado esta ligado a la arquitectura de los FPGA de la marca Xilinx,   |
//| lo cual implica que el mismo es pobremente portable entre sistemas. Sin embargo, conlleva la  |
//| ventaja de que los bloques de memoria pueden ser instanciados directamente, de tal forma que  |
//| se puede llevar control individual de cada uno de ellos a la hora de refrescar sus contenidos |
//| con programas nuevos, virtualmente eliminando el problema de tener que realizar sintesis      |
//| completas a la hora de actualizar el codigo fuente del programa y agilizando dramaticamente   |
//| el ciclo de desarrollo de aplicaciones.                                                       |
//+-----------------------------------------------------------------------------------------------+
#include <stdio.h>                     //Permite invocar las funciones de manejo de archivos
#include "j16asm_output_vhdl_ramb16.h" //Cabecera propia
#include "j16asm.h"                    //Importa los arreglos con los datos de memoria
#include "j16asm_messages.h"           //Permite generar mensajes de error

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
"Library UNISIM;\n"
"use UNISIM.vcomponents.all;\n"
"use work.JPU16_MEM_SIZE_DEFS.all;\n"
"\n"
"entity JPU16_PROG_MEM is\n"
"   generic (nBits_BusProg: integer := 26);\n"
"   Port (SysClk:    in  STD_LOGIC;\n"
"         SysHold:   in  STD_LOGIC;\n"
"         CicloInst: in  STD_LOGIC;\n"
"         Direccion: in  STD_LOGIC_VECTOR (nBits_DirProg - 1 downto 0);\n"
"         DatoProg:  out STD_LOGIC_VECTOR (nBits_BusProg - 1 downto 0));\n"
"end JPU16_PROG_MEM;\n"
"\n"
"architecture Funcionamiento of JPU16_PROG_MEM is\n";
//-------------------------------------------------------------------------------------------------

static const char codigo_vhdl_1[] =
"   type PROG_DATA_BUS is array (%i downto 0) of STD_LOGIC_VECTOR (31 downto 0);\n";

//-------------------------------------------------------------------------------------------------
static const char plantilla_vhdl_2[] =
"\n"
"   signal BusProg: PROG_DATA_BUS;\n";
//-------------------------------------------------------------------------------------------------

static const char codigo_vhdl_2[] =
"   signal CS: STD_LOGIC_VECTOR (%i downto 0);\n"
"begin\n";

static const char codigo_vhdl_3_m[] =
"   Chip_Select: for i in 0 to %i generate\n"
"      CS(i) <= '1' when CicloInst = '0' and SysHold = '0' and\n"
"               Direccion(nBits_DirProg-1 downto 9) = i else '0';\n"
"   end generate;\n"
"\n";

static const char codigo_vhdl_3_u[] =
"   CS(0) <= '1' when CicloInst = '0' and SysHold = '0' else '0';\n"
"\n";

//-------------------------------------------------------------------------------------------------
static const char plantilla_vhdl_3_m[] =
"   DatoProg <= BusProg(conv_integer(Direccion(nBits_DirProg-1 downto 9)))(nBits_BusProg-1 downto 0);\n";

static const char plantilla_vhdl_3_u[] =
"   DatoProg <= BusProg(0)(nBits_BusProg-1 downto 0);\n";

static const char plantilla_vhdl_4[] =
"end Funcionamiento;\n"
"\n"
"-------------------------------\n"
"-- Entidad de la memoria RAM --\n"
"-------------------------------\n"
"library IEEE;\n"
"use IEEE.STD_LOGIC_1164.ALL;\n"
"use IEEE.STD_LOGIC_ARITH.ALL;\n"
"use IEEE.STD_LOGIC_UNSIGNED.ALL;\n"
"Library UNISIM;\n"
"use UNISIM.vcomponents.all;\n"
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
"         DatoSal:   out STD_LOGIC_VECTOR (nBits_BusDatos-1 downto 0));\n"
"end JPU16_RAM;\n"
"\n"
"architecture Funcionamiento of JPU16_RAM is\n";
//-------------------------------------------------------------------------------------------------

static const char codigo_vhdl_4[] =
"   type RAM_DATA_BUS is array (%i downto 0) of STD_LOGIC_VECTOR (nBits_BusDatos-1 downto 0);\n";

//-------------------------------------------------------------------------------------------------
static const char plantilla_vhdl_5[] =
"\n"
"   signal BusRam: RAM_DATA_BUS;\n";
//-------------------------------------------------------------------------------------------------

static const char codigo_vhdl_5[] =
"   signal CS: STD_LOGIC_VECTOR (%i downto 0);\n"
"begin\n";

static const char codigo_vhdl_6_m[] =
"   Chip_Select: for i in 0 to %i generate\n"
"      CS(i) <= '1' when SysHold = '0' and (Ren = '1' or Wen = '1') and\n"
"               Direccion(nBits_DirDatos-1 downto 10) = i else '0';\n"
"   end generate;\n"
"\n";

static const char codigo_vhdl_6_u[] =
"   CS(0) <= '1' when SysHold = '0' and (Ren = '1' or Wen = '1') else '0';\n"
"\n";

//-------------------------------------------------------------------------------------------------
static const char plantilla_vhdl_6_m[] =
"   DatoSal <= BusRam(conv_integer(Direccion(nBits_DirDatos-1 downto 10)));\n";

static const char plantilla_vhdl_6_u[] =
"   DatoSal <= BusRam(0);\n";

static const char plantilla_vhdl_7[] =
"end Funcionamiento;";
//-------------------------------------------------------------------------------------------------

//Declaracion previa de las funciones locales al modulo
static void generar_ramb16_prg(FILE *fp_archivo, int indice);
static void generar_ramb16_ram(FILE *fp_archivo, int indice);

//+------------------------------+
//| Inicio del codigo del modulo |
//+------------------------------+-----------------------------------------------------------------
//Funcion para generar los datos de salida del ensamblador en formato VHDL usando primitivas RAMB16
bool generar_salida_vhdl_ramb16() {
  FILE *fp_archivo = NULL;
  int i;
  int nbits_dir_prg;
  int nbits_dir_ram;
  int num_bloques_prg;
  int num_bloques_ram;

  //Primeramente se crea el archivo de salida
  fp_archivo = fopen(nombre_archivo_vhd_r, "w");
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

  //Determina la cantidad de bloques para la memoria de programa y RAM
  num_bloques_prg = tam_prg / 512;
  num_bloques_ram = tam_ram / 1024;

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

  //Se escribe la linea con la definicion del tipo de dato del bus que interconecta los bloques
  fprintf(fp_archivo, codigo_vhdl_1, num_bloques_prg-1);

  //Se escribe la linea con la declaracion del bus de interconexion
  fprintf(fp_archivo, plantilla_vhdl_2);

  //Se escribe la linea con la declaracion de las señales de seleccion de bloque
  fprintf(fp_archivo, codigo_vhdl_2, num_bloques_prg-1);

  //Dependiendo de si se generan uno o varios bloques, se escriben las lineas de codigo que
  //describen las operaciones de seleccion de bloque
  if (num_bloques_prg > 1)
    fprintf(fp_archivo, codigo_vhdl_3_m, num_bloques_prg-1);
  else
    fprintf(fp_archivo, codigo_vhdl_3_u);

  //Procede a generar los bloques de memoria con los datos del programa
  for (i=0; i<num_bloques_prg; i++)
    generar_ramb16_prg(fp_archivo, i);

  //Dependiendo de la cantidad de bloques, genera el codigo de interconexion de los bloques a
  //traves de un mux, o bien solo conecta el unico bloque a la salida
  if (num_bloques_prg > 1)
    fprintf(fp_archivo, plantilla_vhdl_3_m);
  else
    fprintf(fp_archivo, plantilla_vhdl_3_u);

  //Se escribe la plantilla de cierre de la parte operativa de la memoria de programa e inicio de
  //la parte declarativa de la memoria de datos
  fprintf(fp_archivo, plantilla_vhdl_4);

  //Generacion del codigo VHDL asociado a la memoria de datos (RAM)
  //-----------------------------------------------------------------------------------------------

  //Se escribe la linea con la definicion del tipo de dato del bus que interconecta los bloques
  fprintf(fp_archivo, codigo_vhdl_4, num_bloques_ram-1);

  //Se escribe la linea con la declaracion del bus de interconexion
  fprintf(fp_archivo, plantilla_vhdl_5);

  //Se escribe la linea con la declaracion de las señales de seleccion de bloque
  fprintf(fp_archivo, codigo_vhdl_5, num_bloques_ram-1);

  //Se escriben las lineas de codigo que describen las operaciones de seleccion de bloque
  if (num_bloques_ram > 1)
    fprintf(fp_archivo, codigo_vhdl_6_m, num_bloques_ram-1);
  else
    fprintf(fp_archivo, codigo_vhdl_6_u);

  //Procede a generar los bloques de memoria con los datos de RAM
  for (i=0; i<num_bloques_ram; i++)
    generar_ramb16_ram(fp_archivo, i);

  //Dependiendo de la cantidad de bloques, genera el codigo de interconexion de los bloques a
  //traves de un mux, o bien solo conecta el unico bloque a la salida
  if (num_bloques_ram > 1)
    fprintf(fp_archivo, plantilla_vhdl_6_m);
  else
    fprintf(fp_archivo, plantilla_vhdl_6_u);

  //Se escribe la plantilla de cierre de la parte operativa de la memoria RAM
  fprintf(fp_archivo, plantilla_vhdl_7);

  //Al final del proceso, cierra el archivo
  fclose(fp_archivo);
  return true;                //Retorna con exito
}

//Funcion de generacion de codigo de bloques tipo RAMB16 para la memoria de programa
void generar_ramb16_prg(FILE *fp_archivo, int indice) {
  int i, j;

  //Se genera la cabecera del bloque
  fprintf(fp_archivo,
          "   MemoriaProg%i: RAMB16_S36\n"
          "   generic map (\n"
          "      INIT => X\"000000000\",       --Valor inicial del registro de salida\n"
          "      SRVAL => X\"000000000\",      --Valor de set/reset del registro de salida\n"
          "      WRITE_MODE => \"READ_FIRST\", --Modalidad de lectura antes de escritura\n",
          indice);

  //Se generan los argumentos genericos INIT_XX que contienen los datos iniciales de la memoria
  for (i=0; i<0x40; i++) {
    fprintf(fp_archivo, "      INIT_%.2X => X\"", i);
    for (j=7; j>=0; j--)
      fprintf(fp_archivo, "%.8X", datos_prg[indice*512+i*8+j] & 0x03FFFFFF);
    fprintf(fp_archivo, "\",\n");
  }

  //Se generan los argumentos genericos INITP_XX que contienen los bits de paridad (no usados)
  for (i=0; i<8; i++) {
    fprintf(fp_archivo, "      INITP_%.2X => X\"", i);
    for (j=0; j<8; j++)
      fprintf(fp_archivo, "00000000");
    if (i != 7)
      fprintf(fp_archivo, "\",\n");
    else
      fprintf(fp_archivo, "\")\n");
  }

  //Se genera el segmento de mapeo de puertos del bloque
  fprintf(fp_archivo,
          "   port map (\n"
          "      DO => BusProg(%i),              --Salida de datos de 32 bits\n"
          "      DOP => open,                   --Salida de paridad de 4 bits\n"
          "      ADDR => Direccion(8 downto 0), --Entrada de direcciones de 9 bits\n"
          "      CLK => SysClk,                 --Entrada de reloj\n"
          "      DI => X\"00000000\",             --Entrada de datos de 32 bits\n"
          "      DIP => \"0000\",                 --Entrada de paridad de 4 bits\n"
          "      EN => CS(%i),                   --Entrada de habilitacion (seleccion)\n"
          "      SSR => '0',                    --Entrada sincrona de set/reset\n"
          "      WE => '0'                      --Entrada de habilitacion de escritura\n"
          "   );\n"
          "\n",
          indice, indice);
}

//Funcion de generacion de codigo de bloques tipo RAMB16 para la memoria de datos
void generar_ramb16_ram(FILE *fp_archivo, int indice) {
  int i, j;

  //Se genera la cabecera del bloque
  fprintf(fp_archivo,
          "   MemoriaRam%i: RAMB16_S18\n"
          "   generic map (\n"
          "      INIT => X\"00000\",           --Valor inicial del registro de salida\n"
          "      SRVAL => X\"00000\",          --Valor de set/reset del registro de salida\n"
          "      WRITE_MODE => \"READ_FIRST\", --Modalidad de lectura antes de escritura\n",
          indice);

  //Se generan los argumentos genericos INIT_XX que contienen los datos iniciales de la memoria
  for (i=0; i<0x40; i++) {
    fprintf(fp_archivo, "      INIT_%.2X => X\"", i);
    for (j=15; j>=0; j--)
      fprintf(fp_archivo, "%.4X", datos_ram[indice*1024+i*16+j] & 0x0000FFFF);
    fprintf(fp_archivo, "\",\n");
  }

  //Se generan los argumentos genericos INITP_XX que contienen los bits de paridad (no usados)
  for (i=0; i<8; i++) {
    fprintf(fp_archivo, "      INITP_%.2X => X\"", i);
    for (j=0; j<8; j++)
      fprintf(fp_archivo, "00000000");
    if (i != 7)
      fprintf(fp_archivo, "\",\n");
    else
      fprintf(fp_archivo, "\")\n");
  }

  //Se genera el segmento de mapeo de puertos del bloque
  fprintf(fp_archivo,
          "   port map (\n"
          "      DO => BusRam(%i),               --Salida de datos de 16 bits\n"
          "      DOP => open,                   --Salida de paridad de 2 bits\n"
          "      ADDR => Direccion(9 downto 0), --Entrada de direcciones de 10 bits\n"
          "      CLK => SysClk,                 --Entrada de reloj\n"
          "      DI => DatoEnt,                 --Entrada de datos de 16 bits\n"
          "      DIP => \"00\",                   --Entrada de paridad de 2 bits\n"
          "      EN => CS(%i),                   --Entrada de habilitacion (seleccion)\n"
          "      SSR => '0',                    --Entrada sincrona de set/reset\n"
          "      WE => Wen                      --Entrada de habilitacion de escritura\n"
          "   );\n"
          "\n",
          indice, indice);
}