#nombre del analizador sintactico (extension .y omitida)
parser_name := j16asm_parser
#Nombre del analizador lexico (extension .l omitida)
lex_ana_name := j16asm_lex
#Nombre de los demas archivos de codigo fuente (extension .c omitida)
source_names := j16asm j16asm_dat_struct j16asm_output_vhdl j16asm_output_vhdl_ramb16 j16asm_output_mem_bmm j16asm_messages
#nombre del binario ejecutable
compiler_name := jpu16asm
#Librerias a usar (pasadas directamente a gcc)
libraries := -lfl -lm

#Listas de archivos generadas automaticamente
#Nombres de las cabeceras de los archivos de codigo fuente
header_names := $(patsubst %,%.h,$(source_names))
#Nombre de los archivos de codigo objeto generados por los fuente
object_names := $(patsubst %,%.o,$(source_names))

#Objetivo primario: crear el binario ejecutable
.PHONY: all
all: $(compiler_name)

#Objetivo de limpieza: limpia todos los archivos generados
.PHONY: clean
clean:
	rm -f $(parser_name).tab.c $(parser_name).tab.h $(lex_ana_name).yy.c $(compiler_name) $(object_names)

.PHONY: install
install: $(compiler_name)
	cp $(compiler_name) /usr/local/bin

.PHONY: uninstall
uninstall:
	rm -f /usr/local/bin/$(compiler_name)

#Genera el parser mediane bison
$(parser_name).tab.c $(parser_name).tab.h: $(parser_name).y $(header_names)
	bison -d $<

#Genera el analizador lexico mediante flex
$(lex_ana_name).yy.c: $(lex_ana_name).l $(parser_name).tab.h $(header_names)
	flex -o$@ $<

#Compila los demas archivos de codigo fuente
$(object_names): %.o: %.c $(parser_name).tab.h $(header_names)
	gcc -Wall -c $< -o $@

#Genera el compilador con gcc
$(compiler_name): $(parser_name).tab.c $(lex_ana_name).yy.c $(object_names)
	gcc -Wall -Wno-unused-function $(parser_name).tab.c $(lex_ana_name).yy.c $(object_names) $(libraries) -o $@
