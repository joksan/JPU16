#Archivos de entrada
#-------------------
#Codigo fuente del programa
codigo_asm := Programa.asm
#Archivo bitfile producido por sintesis (archivo original)
bitfile_org := ../Proyecto_ISE/Sistema_Ejemplo.bit

#Archivos de salida
#------------------
#Definicion de la memoria en formato VHDL mediante primitivas RAMB16
def_mem_vhd := JPU16_MEM.vhd
#Mapa de bloques de memoria en formato MEM
mapa_bmm := Mapa_Memoria.bmm
#Programa ensamblado en formato MEM
programa_mem := Programa.mem
#Archivo bitfile con el programa actualizado (archivo modificado)
bitfile_act := Sistema_Reprogramado.bit

#Parametros de memoria
#---------------------
parametros := -p 512 -r 1024

#Rutas de las herramientas usadas
#--------------------------------
SHELL := /bin/bash
config_ise := . /opt/Xilinx/13.1/ISE_DS/settings64.sh

#Nombres de archivo inferidos
mapa_bmm_act := $(patsubst %.bmm, %_bd.bmm, $(mapa_bmm))

#Objetivo primario: crear el archivo MEM
.PHONY: all
all: $(bitfile_act)

#Objetivo de limpieza: limpia todos los archivos generados
.PHONY: clean
clean:
	rm -f $(def_mem_vhd) $(mapa_bmm) $(programa_mem) $(bitfile_act)

.PHONY: codigo_hdl
codigo_hdl: $(def_mem_vhd) $(mapa_bmm)

#Crea el archivo de salida con formato MEM
$(programa_mem): $(codigo_asm) makefile
	jpu16asm $(codigo_asm) $(parametros) -m $@

#Crea el archivo bitfile modificado
$(bitfile_act): $(programa_mem) $(bitfile_org) $(mapa_bmm_act)
	$(config_ise) && data2mem -bd $(programa_mem) -bt $(bitfile_org) -bm $(mapa_bmm_act) -o b $@

#Crea los archivos de salida con formato VHDL y BMM
$(def_mem_vhd) $(mapa_bmm): $(codigo_asm) makefile
	jpu16asm $(codigo_asm) $(parametros) -vr $(def_mem_vhd) -b $(mapa_bmm)