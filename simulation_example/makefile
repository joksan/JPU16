#Archivos de entrada
#-------------------
#Codigo fuente del programa
codigo_asm := simulation_example.asm

#Archivos de salida
#------------------
#Definicion de la memoria en formato VHDL generico
def_mem_vhd := JPU16_MEM.vhd

#Parametros de memoria
#---------------------
parametros := -p 512 -r 1024

#Objetivo primario: crear el archivo con la definicion de la memoria mediante el
#assembler
.PHONY: all
all: $(def_mem_vhd)

#Objetivo de limpieza: limpia todos los archivos generados
.PHONY: clean
clean:
	rm -f $(def_mem_vhd)

#Crea el archivo de salida en formato VHDL generico
$(def_mem_vhd): $(codigo_asm)
	jpu16asm $(codigo_asm) $(parametros) -v $(def_mem_vhd)