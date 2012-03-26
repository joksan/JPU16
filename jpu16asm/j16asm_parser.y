//+-----------------------------------------------------------------------------------------------+
//| j16asm_parser.y                                                                               |
//| Archivo de gramatica de Bison para jpu16asm                                                   |
//|                                                                                               |
//| En este archivo se describen todos los token que componen el lenguaje ensamblador que se      |
//| implementa para JPU16, asi como todas las acciones a llevar a cabo cada vez que se encuentra  |
//| uno.                                                                                          |
//| El producto de procesar este archivo es un modulo de codigo fuente automaticamente generado,  |
//| el cual provee la funcion yyparse() que implementa el paso 1 del ensamblador.                 |
//+-----------------------------------------------------------------------------------------------+
%{
  //Se definen todas las cabeceras, dependencias externas y declaraciones previas que iran a
  //parar al archivo de codigo fuente generado
  #include <math.h>                     //Permite invocar la funcion pow()
  #include "j16asm.h"                   //Importa las funciones y variables de manejo de RAM y ROM
  #include "j16asm_messages.h"          //Importa funciones para generar mensajes

  #define NULL 0

  //Dependencias externas
  extern int yylex (void);      //Funcion del analizador lexico

  //Tipos de dato de uso local
  typedef enum _TIPO_SECCION {  //Enumeracion de las posibles secciones de memoria donde se generan datos
    TS_DATOS, TS_PROG,
  } TIPO_SECCION;

  //Variables de uso local
  static TIPO_SECCION seccion_actual = TS_PROG;         //Seccion actual del codigo fuente
  static int num_lin = 1;                               //Conteo del numero de lineas

  //Declaracion previa de las funciones locales
  static void yyerror(char const *s);   //funcion de manejo de errores invocada por el analizador sintactico
%}

//Se definen los tipos de datos que maneja el analizador sintactico
%union {
  int valor;            //Valor numerico (tambien numero registro de CPU desde r0 a r15)
  char *nombre;         //Nombre de un simbolo (constante, variable o etiqueta) desconocido
  SIMBOLO *simbolo;     //Puntero a un simbolo conocido que existe en la lista de simbolos
}

//Definicion de los token terminales
//----------------------------------
//Token especiales
%token FIN_ARCHIVO 0            //Indica el final del archivo

//Token de nombres de instrucciones
%token TI_NOP
%token TI_CLRC TI_SETC TI_CLRZ TI_SETZ TI_CLRN TI_SETN TI_CLRV TI_SETV TI_CLRI TI_SETI
%token TI_MOVE TI_IN TI_OUT
%token TI_JMP TI_JMPNC TI_JMPC TI_JMPNZ TI_JMPZ TI_JMPP TI_JMPN TI_JMPNV TI_JMPV
%token TI_CALL TI_CALLNC TI_CALLC TI_CALLNZ TI_CALLZ TI_CALLP TI_CALLN TI_CALLNV TI_CALLV
%token TI_RETURN TI_IDRET TI_IERET
%token TI_NOT TI_ADD TI_OR TI_ADDC TI_AND TI_SUB TI_XOR TI_SUBB TI_TEST TI_CMP
%token TI_SHL0 TI_SHL1 TI_ROL TI_ROLC TI_SHR0 TI_SHR1 TI_ROR TI_RORC

//Token de elementos del lenguaje
%token TD_DATA                  //Directiva para ubicar datos en RAM
%token TD_CODE                  //Directiva para ubicar instrucciones en memoria de programa
%token TD_WORD                  //Directiva para generar datos en RAM
%token TD_EQU                   //Directiva para generar simbolos con valores arbitrarios
%token <valor> T_REG            //Registros (r0 - r15)
%token <valor> T_LIT            //Valores literales
%token <nombre> T_SIM_DESC      //Simbolos (constantes, variables y etiquetas) cuyo valor no ha sido definido aun
%token <simbolo> T_SIM_CON      //Simbolos cuyo valor equivalente es previamente conocido

//Token de operadores compuestos de dos caracteres
%token TOP_SHL TOP_SHR TOP_EXP

//Tipos de token no terminales que poseen un valor asociado
//---------------------------------------------------------
%type <valor> instr
%type <valor> exp
%type <valor> exp_lit

//Se define la prioridad de los operadores y su asociatividad
//-----------------------------------------------------------
%left '|'               //OR - menor precedencia (asocia de izquierda a derecha)
%left '^'               //XOR
%left '&'               //AND
%left TOP_SHL TOP_SHR   //Desplazamiento a la izquierda y a la derecha
%left '+' '-'           //Suma y resta
%left '*' '/' '%'       //Multiplicacion, division y modulo
%left TOP_NEG '~'       //negacion aritmetica (signo negativo unario) y NOT
%right TOP_EXP          //exponenciacion - mayor precedencia (asocia de derecha a izquierda)

//Definicion de la gramatica del ensamblador
//------------------------------------------
%%
//El programa puede consistir de un archivo vacio o bien cualquier cantidad de lineas
entrada:
  /* archivo vacio */           {}
  | entrada linea               { num_lin++; } //Coleccion de cualquier cantidad de lineas
;

//Una linea puede ser terminada por el caracter especial \n o bien por el final mismo del archivo
fin_lin:
  '\n'                                  {} //Final de linea normal
  | FIN_ARCHIVO                         {} //Un final de archivo tambien termina una linea
;

//Definicion de la sintaxis de las lineas de codigo
linea:
  '\n'                                  {} //Una linea puede estar vacia
  | etiqueta fin_lin                    {} //Una linea puede tener solo una etiqueta (el token es procesado mas abajo)
  | TD_DATA fin_lin                     { seccion_actual = TS_DATOS; }
  | TD_DATA exp_lit fin_lin             { seccion_actual = TS_DATOS; pos_ram = $2; }
  | TD_CODE fin_lin                     { seccion_actual = TS_PROG; }
  | TD_CODE exp_lit fin_lin             { seccion_actual = TS_PROG; pos_prg = $2; }
  | T_SIM_DESC TD_EQU exp_lit fin_lin   { agregar_simbolo($1, $3, num_lin); }
  | T_SIM_DESC TD_EQU exp_sim fin_lin   { msg_expr_simbolo_no_definido(num_lin); YYABORT; }
  | T_SIM_CON TD_EQU exp_lit fin_lin    { msg_simbolo_redefinido(num_lin, $1->nombre); YYABORT; }
  | T_SIM_CON TD_EQU exp_sim fin_lin    { msg_simbolo_redefinido(num_lin, $1->nombre); YYABORT; }
  | datos_ram fin_lin                   {} //Aqui no se hace nada, los token individuales son procesados mas adelante
  | etiqueta datos_ram fin_lin          {} //Igual que el anterior, esta parte solo valida sintaxis
  | dato_prg fin_lin                    {}
  | etiqueta dato_prg fin_lin           {}
;

//Definicion de la sintaxis de los datos de RAM
datos_ram:
  TD_WORD exp                   { //Los datos de RAM se pueden declarar con la directiva word
                                  if (seccion_actual != TS_DATOS) {
                                    //Verifica que los datos sean declarados dentro de una seccion de datos
                                    msg_datos_seccion_incorrecta(num_lin);
                                    YYABORT;
                                  }
                                  if (!agregar_dato_ram($2, num_lin)) YYABORT;
                                  //Nota: Si el token exp es una expresion simbolica, entonces el dato que se recibe aca
                                  //es 0x00 (de manera temporal), de manera que solo se reserva la localidad de memoria
                                  //para ser posteriormente rellenada con el valor resultante en el paso 2
                                }
  | datos_ram ',' exp           { //Una declaracion de datos puede tener mas de uno si la lista se separa con comas
                                  //Nota: no es necesario verificar que datos adicionales esten en su seccion correcta
                                  //porque eso se ya se hace cuando se encuentra el token TD_WORD
                                  if (!agregar_dato_ram($3, num_lin)) YYABORT;
                                }
;

//Definicion de la sintaxis de los datos que van en la memoria de programa
dato_prg:
  instr                         { //Los datos de la memoria de programa son las instrucciones
                                  if (seccion_actual != TS_PROG) {
                                    //Verifica que las instrucciones sean declaradas dentro de una seccion de codigo
                                    msg_instr_seccion_incorrecta(num_lin);
                                    YYABORT;
                                  }
                                  if (!agregar_dato_prg($1, num_lin)) YYABORT;
                                  //Nota: El valor numerico asociado a una instruccion es su opcode resultante. En caso
                                  //que la misma posea una expresion simbolica, entonces su valor temporal posee los bits
                                  //que la codifican junto con un argumento literal cuyo valor es (usualmente) 0x00, y su
                                  //valor final sera determinado en el paso 2
                                }
;

//Definicion de la sintaxis de las etiquetas
etiqueta:
  T_SIM_DESC ':'                { //Una etiqueta debe ser seguida de 2 puntos
                                  switch (seccion_actual) {
                                  case TS_DATOS:
                                    //Si esta en una seccion de datos, entonces la etiqueta corresponde a la RAM
                                    agregar_simbolo($1, pos_ram, num_lin);
                                    break;
                                  case TS_PROG:
                                    //Si esta en una seccion de codigo, entonces la etiqueta corresponde a la memoria
                                    //de programa
                                    agregar_simbolo($1, pos_prg, num_lin);
                                    break;
                                  }
                                }
  | T_SIM_CON ':'               { msg_simbolo_redefinido(num_lin, $1->nombre); YYABORT; }
;

//Definicion de la sintaxis de las instrucciones
instr:
  //Primer bloque de instrucciones: No operacion 
    //nop
  TI_NOP          { $$ = 0x0000; }                //El valor generado es el opcode

  //Segundo bloque: Instrucciones de manejo de banderas
    //clrc
  | TI_CLRC       { $$ = 0b0001000001 << 16; }
    //setc
  | TI_SETC       { $$ = 0b0001100001 << 16; }
    //clrz
  | TI_CLRZ       { $$ = 0b0001000010 << 16; }
    //setz
  | TI_SETZ       { $$ = 0b0001100010 << 16; }
    //clrn
  | TI_CLRN       { $$ = 0b0001000100 << 16; }
    //setn
  | TI_SETN       { $$ = 0b0001100100 << 16; }
    //clrv
  | TI_CLRV       { $$ = 0b0001001000 << 16; }
    //setv
  | TI_SETV       { $$ = 0b0001101000 << 16; }
    //clri
  | TI_CLRI       { $$ = 0b0001010000 << 16; }
    //seti
  | TI_SETI       { $$ = 0b0001110000 << 16; }

  //Tercer bloque: Operaciones de prueba (solo afectan banderas)
    //test reg, lit
  | TI_TEST T_REG ',' exp       { $$ = (0b001000 << 20) | ($2 << 16) | ($4 & 0xFFFF); }
    //test reg, reg
  | TI_TEST T_REG ',' T_REG     { $$ = (0b001001 << 20) | ($2 << 16) | ($4 << 12);    }
    //cmp reg, lit
  | TI_CMP  T_REG ',' exp       { $$ = (0b001010 << 20) | ($2 << 16) | ($4 & 0xFFFF); }
    //cmp reg, reg
  | TI_CMP  T_REG ',' T_REG     { $$ = (0b001011 << 20) | ($2 << 16) | ($4 << 12);    }

  //Cuarto bloque: Instrucciones de salida de datos desde el CPU (hacia la memoria o bus de I/O)
    //move [dir], reg
  | TI_MOVE '[' exp   ']' ',' T_REG     { $$ = (0b001100 << 20) | ($6 << 16) | ($3 & 0xFFFF); }
    //move [reg], reg
  | TI_MOVE '[' T_REG ']' ',' T_REG     { $$ = (0b001101 << 20) | ($6 << 16) | ($3 << 12);    }
    //out dir, reg
  | TI_OUT      exp       ',' T_REG     { $$ = (0b001110 << 20) | ($4 << 16) | ($2 & 0xFFFF); }
    //out reg, reg
  | TI_OUT      T_REG     ',' T_REG     { $$ = (0b001111 << 20) | ($4 << 16) | ($2 << 12);    }

  //Quinto bloque: Instrucciones de salto
    //jmp dir
  | TI_JMP exp          { $$ = (0b010000 << 20) | (($2-pos_prg) & 0xFFFF); }
    //jmp reg
  | TI_JMP T_REG        { $$ = (0b010001 << 20) | ($2 << 12);    }
    //jmpnc dir
  | TI_JMPNC exp        { $$ = (0b0100100000 << 16) | (($2-pos_prg) & 0xFFFF); }
    //jmpnc reg
  | TI_JMPNC T_REG      { $$ = (0b0100110000 << 16) | ($2 << 12); }
    //jmpc dir
  | TI_JMPC exp         { $$ = (0b0100100001 << 16) | (($2-pos_prg) & 0xFFFF); }
    //jmpc reg
  | TI_JMPC T_REG       { $$ = (0b0100110001 << 16) | ($2 << 12); }
    //jmpnz dir
  | TI_JMPNZ exp        { $$ = (0b0100100010 << 16) | (($2-pos_prg) & 0xFFFF); }
    //jmpnz reg
  | TI_JMPNZ T_REG      { $$ = (0b0100110010 << 16) | ($2 << 12); }
    //jmpz dir
  | TI_JMPZ exp         { $$ = (0b0100100011 << 16) | (($2-pos_prg) & 0xFFFF); }
    //jmpz reg
  | TI_JMPZ T_REG       { $$ = (0b0100110011 << 16) | ($2 << 12); }
    //jmpp dir
  | TI_JMPP exp         { $$ = (0b0100100100 << 16) | (($2-pos_prg) & 0xFFFF); }
    //jmpp reg
  | TI_JMPP T_REG       { $$ = (0b0100110100 << 16) | ($2 << 12); }
    //jmpn dir
  | TI_JMPN exp         { $$ = (0b0100100101 << 16) | (($2-pos_prg) & 0xFFFF); }
    //jmpn reg
  | TI_JMPN T_REG       { $$ = (0b0100110101 << 16) | ($2 << 12); }
    //jmpnv dir
  | TI_JMPNV exp        { $$ = (0b0100100110 << 16) | (($2-pos_prg) & 0xFFFF); }
    //jmpnv reg
  | TI_JMPNV T_REG      { $$ = (0b0100110110 << 16) | ($2 << 12); }
    //jmpv dir
  | TI_JMPV exp         { $$ = (0b0100100111 << 16) | (($2-pos_prg) & 0xFFFF); }
    //jmpv reg
  | TI_JMPV T_REG       { $$ = (0b0100110111 << 16) | ($2 << 12); }

  //Sexto bloque: Instrucciones de llamada
    //call dir
  | TI_CALL exp         { $$ = (0b010100 << 20) | (($2-pos_prg) & 0xFFFF); }
    //call reg
  | TI_CALL T_REG       { $$ = (0b010101 << 20) | ($2 << 12);    }
    //callnc dir
  | TI_CALLNC exp       { $$ = (0b0101100000 << 16) | (($2-pos_prg) & 0xFFFF); }
    //callnc reg
  | TI_CALLNC T_REG     { $$ = (0b0101110000 << 16) | ($2 << 12); }
    //callc dir
  | TI_CALLC exp        { $$ = (0b0101100001 << 16) | (($2-pos_prg) & 0xFFFF); }
    //callc reg
  | TI_CALLC T_REG      { $$ = (0b0101110001 << 16) | ($2 << 12); }
    //callnz dir
  | TI_CALLNZ exp       { $$ = (0b0101100010 << 16) | (($2-pos_prg) & 0xFFFF); }
    //callnz reg
  | TI_CALLNZ T_REG     { $$ = (0b0101110010 << 16) | ($2 << 12); }
    //callz dir
  | TI_CALLZ exp        { $$ = (0b0101100011 << 16) | (($2-pos_prg) & 0xFFFF); }
    //callz reg
  | TI_CALLZ T_REG      { $$ = (0b0101110011 << 16) | ($2 << 12); }
    //callp dir
  | TI_CALLP exp        { $$ = (0b0101100100 << 16) | (($2-pos_prg) & 0xFFFF); }
    //callp reg
  | TI_CALLP T_REG      { $$ = (0b0101110100 << 16) | ($2 << 12); }
    //calln dir
  | TI_CALLN exp        { $$ = (0b0101100101 << 16) | (($2-pos_prg) & 0xFFFF); }
    //calln reg
  | TI_CALLN T_REG      { $$ = (0b0101110101 << 16) | ($2 << 12); }
    //callnv dir
  | TI_CALLNV exp       { $$ = (0b0101100110 << 16) | (($2-pos_prg) & 0xFFFF); }
    //callnv reg
  | TI_CALLNV T_REG     { $$ = (0b0101110110 << 16) | ($2 << 12); }
    //callv dir
  | TI_CALLV exp        { $$ = (0b0101100111 << 16) | (($2-pos_prg) & 0xFFFF); }
    //callv reg
  | TI_CALLV T_REG      { $$ = (0b0101110111 << 16) | ($2 << 12); }

  //Septimo bloque: Instrucciones de retorno
    //return
  | TI_RETURN     { $$ = 0b011000 << 20; }
    //idret
  | TI_IDRET      { $$ = 0b011100 << 20; }
    //ieret
  | TI_IERET      { $$ = 0b011110 << 20; }

  //Octavo bloque: operaciones aritmeticas y logicas
    //not reg
  | TI_NOT T_REG                { $$ = (0b100000 << 20) | ($2 << 16); }
    //add reg, lit
  | TI_ADD T_REG ',' exp        { $$ = (0b100010 << 20) | ($2 << 16) | ($4 & 0xFFFF); }
    //add reg, reg
  | TI_ADD T_REG ',' T_REG      { $$ = (0b100011 << 20) | ($2 << 16) | ($4 << 12); }
    //or reg, lit
  | TI_OR T_REG ',' exp         { $$ = (0b100100 << 20) | ($2 << 16) | ($4 & 0xFFFF); }
    //or reg, reg
  | TI_OR T_REG ',' T_REG       { $$ = (0b100101 << 20) | ($2 << 16) | ($4 << 12); }
    //addc reg, lit
  | TI_ADDC T_REG ',' exp       { $$ = (0b100110 << 20) | ($2 << 16) | ($4 & 0xFFFF); }
    //addc reg, reg
  | TI_ADDC T_REG ',' T_REG     { $$ = (0b100111 << 20) | ($2 << 16) | ($4 << 12); }
    //and reg, lit
  | TI_AND T_REG ',' exp        { $$ = (0b101000 << 20) | ($2 << 16) | ($4 & 0xFFFF); }
    //and reg, reg
  | TI_AND T_REG ',' T_REG      { $$ = (0b101001 << 20) | ($2 << 16) | ($4 << 12); }
    //sub reg, lit
  | TI_SUB T_REG ',' exp        { $$ = (0b101010 << 20) | ($2 << 16) | ($4 & 0xFFFF); }
    //sub reg, reg
  | TI_SUB T_REG ',' T_REG      { $$ = (0b101011 << 20) | ($2 << 16) | ($4 << 12); }
    //xor reg, lit
  | TI_XOR T_REG ',' exp        { $$ = (0b101100 << 20) | ($2 << 16) | ($4 & 0xFFFF); }
    //xor reg, reg
  | TI_XOR T_REG ',' T_REG      { $$ = (0b101101 << 20) | ($2 << 16) | ($4 << 12); }
    //subb reg, lit
  | TI_SUBB T_REG ',' exp       { $$ = (0b101110 << 20) | ($2 << 16) | ($4 & 0xFFFF); }
    //subb reg, reg
  | TI_SUBB T_REG ',' T_REG     { $$ = (0b101111 << 20) | ($2 << 16) | ($4 << 12); }

  //Noveno bloque: operaciones de desplazamiento de bits
    //shl0 reg, lit
  | TI_SHL0 T_REG ',' exp     { $$ = (0b111000 << 20) | (0x0 << 9) | ($2 << 16) | ($4 & 0x000F); }
    //shl0 reg, reg
  | TI_SHL0 T_REG ',' T_REG   { $$ = (0b111001 << 20) | (0x0 << 9) | ($2 << 16) | ($4 << 12); }
    //shl1 reg, lit
  | TI_SHL1 T_REG ',' exp     { $$ = (0b111000 << 20) | (0x1 << 9) | ($2 << 16) | ($4 & 0x000F); }
    //shl1 reg, reg
  | TI_SHL1 T_REG ',' T_REG   { $$ = (0b111001 << 20) | (0x1 << 9) | ($2 << 16) | ($4 << 12); }
    //rol reg, lit
  | TI_ROL T_REG ',' exp      { $$ = (0b111000 << 20) | (0x2 << 9) | ($2 << 16) | ($4 & 0x000F); }
    //rol reg, reg
  | TI_ROL T_REG ',' T_REG    { $$ = (0b111001 << 20) | (0x2 << 9) | ($2 << 16) | ($4 << 12); }
    //rolc reg
  | TI_ROLC T_REG             { $$ = (0b111000 << 20) | (0x3 << 9) | ($2 << 16) | 0x1; }
    //shr0 reg, lit
  | TI_SHR0 T_REG ',' exp     { $$ = (0b111000 << 20) | (0x4 << 9) | ($2 << 16) | ($4 & 0x000F); }
    //shr0 reg, reg
  | TI_SHR0 T_REG ',' T_REG   { $$ = (0b111001 << 20) | (0x4 << 9) | ($2 << 16) | ($4 << 12); }
    //shr1 reg, lit
  | TI_SHR1 T_REG ',' exp     { $$ = (0b111000 << 20) | (0x5 << 9) | ($2 << 16) | ($4 & 0x000F); }
    //shr1 reg, reg
  | TI_SHR1 T_REG ',' T_REG   { $$ = (0b111001 << 20) | (0x5 << 9) | ($2 << 16) | ($4 << 12); }
    //ror reg, lit
  | TI_ROR T_REG ',' exp      { $$ = (0b111000 << 20) | (0x6 << 9) | ($2 << 16) | ($4 & 0x000F); }
    //ror reg, reg
  | TI_ROR T_REG ',' T_REG    { $$ = (0b111001 << 20) | (0x6 << 9) | ($2 << 16) | ($4 << 12); }
    //rorc reg
  | TI_RORC T_REG             { $$ = (0b111000 << 20) | (0x7 << 9) | ($2 << 16) | 0x1; }

  //Decimo bloque: Instrucciones de entrada de datos hacia el CPU (desde literal, registro, memoria o I/O)
    //move reg, lit
  | TI_MOVE T_REG ',' exp               { $$ = (0b111010 << 20) | ($2 << 16) | ($4 & 0xFFFF); }
    //move reg, reg
  | TI_MOVE T_REG ',' T_REG             { $$ = (0b111011 << 20) | ($2 << 16) | ($4 << 12); }
    //move reg, [dir]
  | TI_MOVE T_REG ',' '[' exp   ']'     { $$ = (0b111100 << 20) | ($2 << 16) | ($5 & 0xFFFF); }
    //move reg, [reg]
  | TI_MOVE T_REG ',' '[' T_REG ']'     { $$ = (0b111101 << 20) | ($2 << 16) | ($5 << 12); }
    //in reg, dir
  | TI_IN T_REG ',' exp                 { $$ = (0b111110 << 20) | ($2 << 16) | ($4 & 0xFFFF); }
    //in reg, reg
  | TI_IN T_REG ',' T_REG               { $$ = (0b111111 << 20) | ($2 << 16) | ($4 << 12); }
;

//Definicion de los tipos de expresiones aritmeticas
exp:
  //Las expresiones literales incluyen solo valores numericos conocidos
  exp_lit       { $$ = $1; }    //Retorna directamente el valor calculado
  //Las expresiones simbolicas son aquellas que incluyen al menos un simbolo (constante, etiqueta o variable)
  | exp_sim     {
                  $$ = 0;       //Retorna cero de momento (generara un resultado despues)
                  switch (seccion_actual) {
                  case TS_DATOS: encolar_resultado_ram(pos_ram, num_lin); break;  //Guardara el resultado en RAM
                  case TS_PROG:  encolar_resultado_prg(pos_prg, num_lin); break;  //Guardara resultado en memoria de prog.
                  }
                }
;

exp_lit:
  //Un token literal (un numero) califica como expresion literal de forma implicita
  T_LIT                         { $$ = $1; }
  //Un token simbolico previamente conocido puede ser promovido sin problemas a expresion literal, devolviendo su valor
  //numerico equivalente
  | T_SIM_CON                   { $$ = $1->valor; }
  //El simbolo $ representa la localidad de memoria actual
  | '$'                         {
                                  switch (seccion_actual) {
                                  case TS_DATOS: $$ = pos_ram; break;  //Aca significa localidad actual de RAM
                                  case TS_PROG:  $$ = pos_prg; break;  //Y aca localidad actual de memoria de programa
                                  }
                                }
  //Definicion de la sintaxis de los operadores
  | exp_lit '|' exp_lit         { $$ = $1 | $3; }
  | exp_lit '^' exp_lit         { $$ = $1 ^ $3; }
  | exp_lit '&' exp_lit         { $$ = $1 & $3; }
  | exp_lit TOP_SHL exp_lit     { $$ = $1 << $3; }
  | exp_lit TOP_SHR exp_lit     { $$ = $1 >> $3; }
  | exp_lit '+' exp_lit         { $$ = $1 + $3; }
  | exp_lit '-' exp_lit         { $$ = $1 - $3; }
  | exp_lit '*' exp_lit         { $$ = $1 * $3; }
  | exp_lit '/' exp_lit         { $$ = $1 / $3; }
  | exp_lit '%' exp_lit         { $$ = $1 % $3; }
  | '-' exp_lit %prec TOP_NEG   { $$ = -$2; }
  | '~' exp_lit                 { $$ = ~$2; }
  | exp_lit TOP_EXP exp_lit     { $$ = pow($1, $3); }
  | '(' exp_lit ')'             { $$ = $2; }
;

exp_sim:
  //Un simbolo cuyo valor no se conoce es encolado para poder determinarlo despues en el paso 2, ademas un token simbolico
  //califica automaticamente como expresion simbolica
  T_SIM_DESC                    { encolar_simbolo($1, num_lin); }

  //Si se mezcla una expresion simbolica con algo mas, pueden darse los siguientes casos
  //1- Si se mezcla con una expresion literal a la izquierda, entonces se encola dicho literal para ser agregado a la pila,
  //   pero al quedar ambos elementos ordenados de forma invertida, la operacion encolada tambien debera hacer un
  //   intercambio de sus operandos
  //2- Si se mezcla con una expresion literal a la derecha, entonces se encola dicho literal para ser apilado, pero como
  //   quedan en el orden correcto, se encola la operacion sin intercambio de operandos
  //3- Si se mezcla con otra expresion simbolica, entonces ambos valores deberan estar pre-procesados en pila y en el orden
  //   correcto, asi que solo se encola la operacion
  //Notese que los operadores unarios por su naturaleza impiden mezclar las expresiones simbolicas con otras expresiones,
  //por lo que se encola unicamente su operacion

  | exp_lit '|' exp_sim         { encolar_literal($1, num_lin); encolar_operacion(OPER_OR | OPER_INTERCAMBIO, num_lin); }
  | exp_sim '|' exp_lit         { encolar_literal($3, num_lin); encolar_operacion(OPER_OR, num_lin); }
  | exp_sim '|' exp_sim         { encolar_operacion(OPER_OR, num_lin); }

  | exp_lit '^' exp_sim         { encolar_literal($1, num_lin); encolar_operacion(OPER_XOR | OPER_INTERCAMBIO, num_lin); }
  | exp_sim '^' exp_lit         { encolar_literal($3, num_lin); encolar_operacion(OPER_XOR, num_lin); }
  | exp_sim '^' exp_sim         { encolar_operacion(OPER_XOR, num_lin); }

  | exp_lit '&' exp_sim         { encolar_literal($1, num_lin); encolar_operacion(OPER_AND | OPER_INTERCAMBIO, num_lin); }
  | exp_sim '&' exp_lit         { encolar_literal($3, num_lin); encolar_operacion(OPER_AND, num_lin); }
  | exp_sim '&' exp_sim         { encolar_operacion(OPER_AND, num_lin); }

  | exp_lit TOP_SHL exp_sim     { encolar_literal($1, num_lin); encolar_operacion(OPER_SHL | OPER_INTERCAMBIO, num_lin); }
  | exp_sim TOP_SHL exp_lit     { encolar_literal($3, num_lin); encolar_operacion(OPER_SHL, num_lin); }
  | exp_sim TOP_SHL exp_sim     { encolar_operacion(OPER_SHL, num_lin); }

  | exp_lit TOP_SHR exp_sim     { encolar_literal($1, num_lin); encolar_operacion(OPER_SHR | OPER_INTERCAMBIO, num_lin); }
  | exp_sim TOP_SHR exp_lit     { encolar_literal($3, num_lin); encolar_operacion(OPER_SHR, num_lin); }
  | exp_sim TOP_SHR exp_sim     { encolar_operacion(OPER_SHR, num_lin); }

  | exp_lit '+' exp_sim         { encolar_literal($1, num_lin); encolar_operacion(OPER_SUM | OPER_INTERCAMBIO, num_lin); }
  | exp_sim '+' exp_lit         { encolar_literal($3, num_lin); encolar_operacion(OPER_SUM, num_lin); }
  | exp_sim '+' exp_sim         { encolar_operacion(OPER_SUM, num_lin); }

  | exp_lit '-' exp_sim         { encolar_literal($1, num_lin); encolar_operacion(OPER_RES | OPER_INTERCAMBIO, num_lin); }
  | exp_sim '-' exp_lit         { encolar_literal($3, num_lin); encolar_operacion(OPER_RES, num_lin); }
  | exp_sim '-' exp_sim         { encolar_operacion(OPER_RES, num_lin); }

  | exp_lit '*' exp_sim         { encolar_literal($1, num_lin); encolar_operacion(OPER_MUL | OPER_INTERCAMBIO, num_lin); }
  | exp_sim '*' exp_lit         { encolar_literal($3, num_lin); encolar_operacion(OPER_MUL, num_lin); }
  | exp_sim '*' exp_sim         { encolar_operacion(OPER_MUL, num_lin); }

  | exp_lit '/' exp_sim         { encolar_literal($1, num_lin); encolar_operacion(OPER_DIV | OPER_INTERCAMBIO, num_lin); }
  | exp_sim '/' exp_lit         { encolar_literal($3, num_lin); encolar_operacion(OPER_DIV, num_lin); }
  | exp_sim '/' exp_sim         { encolar_operacion(OPER_DIV, num_lin); }

  | exp_lit '%' exp_sim         { encolar_literal($1, num_lin); encolar_operacion(OPER_MOD | OPER_INTERCAMBIO, num_lin); }
  | exp_sim '%' exp_lit         { encolar_literal($3, num_lin); encolar_operacion(OPER_MOD, num_lin); }
  | exp_sim '%' exp_sim         { encolar_operacion(OPER_MOD, num_lin); }

  | '-' exp_sim %prec TOP_NEG   { encolar_operacion(OPER_NEG, num_lin); }
  | '~' exp_sim                 { encolar_operacion(OPER_NOT, num_lin); }

  | exp_lit TOP_EXP exp_sim     { encolar_literal($1, num_lin); encolar_operacion(OPER_EXP | OPER_INTERCAMBIO, num_lin); }
  | exp_sim TOP_EXP exp_lit     { encolar_literal($3, num_lin); encolar_operacion(OPER_EXP, num_lin); }
  | exp_sim TOP_EXP exp_sim     { encolar_operacion(OPER_EXP, num_lin); }

  | '(' exp_sim ')'             {}  //Los parentesis no provocan operaciones relevantes sobre la pila, sin embargo su
                                    //presencia aca permite implentar la regla de agrupacion
;
%%

//Funcion de manejo de errores (llamada por yyparse cuando hay errores)
void yyerror(char const *s) {
  msg_error_sintaxis(num_lin);
}
