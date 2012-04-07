/*************************************************************************************************/
/* j16asm_lex.l                                                                                  */
/* Archivo de entrada de flex para jpu16asm                                                      */
/*                                                                                               */
/* En este archivo se describen todas las expresiones regulares asociadas a cada uno de los      */
/* token terminales que componen el lenguaje ensamblador que se implementa para JPU16, asi como  */
/* todas las acciones a llevar a cabo cada vez que se encuentra uno.                             */
/* El producto de procesar este archivo es un modulo de codigo fuente automaticamente generado,  */
/* el cual provee la funcion yylex() que implementa el analizador lexico utilizado durante el    */
/* paso 1 del ensamblador.                                                                       */
/*                                                                                               */
/* Nota acerca del alojamiento de las cadenas                                                    */
/* Siempre que el analizador lexico determina que un token terminal es el nombre de un simbolo,  */
/* busca primero si el mismo existe en la lista de simbolos y en caso de existir, entrega su     */
/* puntero dentro de la lista al analizador sintactico. Sin embargo, si el simbolo  no existe    */
/* previamente en dicha lista, entrega directamente el nombre del token en forma de cadena de    */
/* texto, para lo cual aloja memoria dinamicamente a traves de la funcion strdup().              */
/* Dicha cadena no es desalojada por el analizador sintactico, quedando esta tarea delegada a    */
/* las funciones que manejan las estructuras de datos del ensamblador. Dependiendo del contexto  */
/* donde se haya encontrado el nombre del simbolo, la cadena podria ser alojada en la lista de   */
/* simbolos (en caso de una declaracion) o en la cola de acciones (en caso de una referencia de  */
/* uso). Esto se hace asi por motivos de eficiencia, para evitar hacer duplicados adicionales    */
/* innecesarios y que sea posible acceder las cadenas hasta una etapa bien avanzada del          */
/* ensamblador.                                                                                  */
/*************************************************************************************************/
%{
  //Se definen las cabeceras que iran a parar al archivo de codigo fuente generado
  #include "j16asm_dat_struct.h"  //Incluye las funciones de manejo de simbolos
  #include "j16asm_parser.tab.h"  //Incluye los tipos de token creados

  //Variables usadas localmente
  static SIMBOLO *p_simbolo;
%}
/* Define la condicion de inicio usada para los comentarios como de tipo exclusivo */
%x COM
%%
(?# Primeramente se manejan todos los caracteres especiales)
[ \t]       ;                   //No hace nada con los espacios
[\n]        return '\n';        //La regla anterior no aplica para fines de linea, asi que se incluye tambien

(?# Se definen los comentarios)
;           BEGIN(COM);         //Los comentarios inician con un punto y coma
<COM>.      ;                   //Durante los comentarios todo caracter excepto fin de linea es ignorado
<COM>\n     { BEGIN(INITIAL); return '\n'; } //Un comentario termina con un fin de linea (y lo devuelve)

(?# Se definen aquellos operadores que se componen de dos caracteres )
\*\*        return TOP_EXP;     //Operador de exponenciacion
\<\<        return TOP_SHL;     //Operador de desplazamiento a la izquierda
\>\>        return TOP_SHR;     //Operador de desplazamiento a la derecha

(?# Se definen todas las palabras reservadas - ninguna es sensitiva a la capitalizacion )
(?i:nop)    return TI_NOP;      //Nombres de instrucciones
(?i:clrc)   return TI_CLRC;
(?i:setc)   return TI_SETC;
(?i:clrz)   return TI_CLRZ;
(?i:setz)   return TI_SETZ;
(?i:clrn)   return TI_CLRN;
(?i:setn)   return TI_SETN;
(?i:clrv)   return TI_CLRV;
(?i:setv)   return TI_SETV;
(?i:clri)   return TI_CLRI;
(?i:seti)   return TI_SETI;
(?i:move)   return TI_MOVE;
(?:in)      return TI_IN;
(?i:out)    return TI_OUT;
(?i:jmp)    return TI_JMP;
(?i:jmpnc)  return TI_JMPNC;
(?i:jmpc)   return TI_JMPC;
(?i:jmpnz)  return TI_JMPNZ;
(?i:jmpz)   return TI_JMPZ;
(?i:jmpp)   return TI_JMPP;
(?i:jmpn)   return TI_JMPN;
(?i:jmpnv)  return TI_JMPNV;
(?i:jmpv)   return TI_JMPV;
(?i:call)   return TI_CALL;
(?i:callnc) return TI_CALLNC;
(?i:callc)  return TI_CALLC;
(?i:callnz) return TI_CALLNZ;
(?i:callz)  return TI_CALLZ;
(?i:callp)  return TI_CALLP;
(?i:calln)  return TI_CALLN;
(?i:callnv) return TI_CALLNV;
(?i:callv)  return TI_CALLV;
(?i:return) return TI_RETURN;
(?i:idret)  return TI_IDRET;
(?i:ieret)  return TI_IERET;
(?i:not)    return TI_NOT;
(?i:add)    return TI_ADD;
(?i:or)     return TI_OR;
(?i:addc)   return TI_ADDC;
(?i:and)    return TI_AND;
(?i:sub)    return TI_SUB;
(?i:xor)    return TI_XOR;
(?i:subb)   return TI_SUBB;
(?i:test)   return TI_TEST;
(?i:cmp)    return TI_CMP;
(?i:mul)    return TI_MUL;
(?i:smul)   return TI_SMUL;
(?i:shl0)   return TI_SHL0;
(?i:shl1)   return TI_SHL1;
(?i:rol)    return TI_ROL;
(?i:rolc)   return TI_ROLC;
(?i:shr0)   return TI_SHR0;
(?i:shr1)   return TI_SHR1;
(?i:ror)    return TI_ROR;
(?i:rorc)   return TI_RORC;

(?i:je)     return TI_JMPZ;     //Nombres de instruccion que son alias
(?i:jne)    return TI_JMPNZ;
(?i:jae)    return TI_JMPC;
(?i:jb)     return TI_JMPNC;
(?i:jge)    return TI_JMPP;
(?i:jl)     return TI_JMPN;
(?i:ce)     return TI_CALLZ;
(?i:cne)    return TI_CALLNZ;
(?i:cae)    return TI_CALLC;
(?i:cb)     return TI_CALLNC;
(?i:cge)    return TI_CALLP;
(?i:cl)     return TI_CALLN;

(?i:data)   return TD_DATA;     //Nombres de directivas
(?i:code)   return TD_CODE;
(?i:word)   return TD_WORD;
(?i:equ)    return TD_EQU;

(?# Se definen todos los nombres de los registros desde r0 a r15 )
[rR][0-9]|[rR]1[0-5] { yylval.valor = strtoul(&yytext[1], NULL, 10); return T_REG; }

(?# Se definen todas las constantes numericas literales )
0[bB][01]+          { yylval.valor = strtoul(&yytext[2], NULL, 2);  return T_LIT; }   //La constante es un numero binario
0[oO][0-7]+         { yylval.valor = strtoul(&yytext[2], NULL, 8);  return T_LIT; }   //La constante es un numero octal
[0-9]+              { yylval.valor = strtoul(yytext, NULL, 10);     return T_LIT; }   //La constante es un numero decimal
0[dD][0-9]+         { yylval.valor = strtoul(&yytext[2], NULL, 10); return T_LIT; }   //Decimal pero con prefijo 0d
0[xX][0-9a-fA-F]+   { yylval.valor = strtoul(&yytext[2], NULL, 16); return T_LIT; }   //La constante es un numero hexadecimal
'.'                 { yylval.valor = yytext[1];                     return T_LIT; }   //La constante es un caracter (ascii)

(?# Se definen los nombres de los simbolos - etiquetas, variables y constantes )
[_a-zA-Z]+[_a-zA-Z0-9]*   {
                            //Determina si el simbolo existe previamente en la lista
                            p_simbolo = buscar_simbolo(yytext);
                            if (p_simbolo) {
                              //En caso de existir, retorna el puntero a la entrada de la lista
                              yylval.simbolo = p_simbolo;
                              return T_SIM_CON;
                            }
                            else {
                              //En caso de no existir, solo retorna una copia de la cadena de texto
                              yylval.nombre = strdup(yytext);
                              //Nota: la cadena alojada aqui sera desalojada posteriomente ya sea en la funcion de desalojo
                              //de simbolos o bien en la funcion de desalojo de elementos de la cola de acciones 
                              return T_SIM_DESC;
                            }
                          }

(?# Se definen el resto de caracteres )
.               return yytext[0]; //Todos los demas caracteres (excepto fin de linea) retornan su mismo codigo

%%
