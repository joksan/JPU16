;Programa de demostracion para JPU16
;Autor: Joksan Alvarado
;
;El siguiente programa de ejemplo hace uso de un unico puerto de I/O conectado al bus del
;procesador para parpadear 8 LEDs conectados al puerto A de una tarjeta Papilio One de 500K.
;
;Siga los pasos del archivo "indicaciones" contenido en el paquete donde vino este archivo para
;correrlo.

code              ;La directiva code se usa para definir secciones de codigo
  move r0, 0      ;Limpia el registro r0
inicio:
  out 0, r0       ;Envia el contenido de r0 al puerto 0
  not r0          ;Invierte los bits de r0
  call retardo    ;Genera un retardo
  jmp inicio      ;Repite el proceso

retardo:
  move r15, 64    ;Carga el valor inicial de conteo sobre r15
  move r14, 0     ;Limpia el valor de r14

  sub r14, 1      ;Substrae 1 de r14 (provoca un desbordamiento en la primera iteracion)
  jmpnz $-1       ;Repite el proceso hasta que r14 sea 0 nuevamente

  sub r15, 1      ;Substrae 1 de r15
  jmpnz $-4       ;Repite el proceso (salta 4 instrucciones atras) hasta que r14 sea 0
  return          ;Retorna tras terminar los conteos