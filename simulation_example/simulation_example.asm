;Programa de demostracion para JPU16
;Autor: Joksan Alvarado
;
;El siguiente programa de ejemplo implementa un contador en un registro, cuyo
;valor es enviado continuamente a un unico puerto de salida.
;
;Siga los pasos del archivo "readme_es.txt" para simular el ejemplo

code              ;La directiva code se usa para definir secciones de codigo
  move r0, 0      ;Limpia el registro r0
lazo:
  add r0, 1       ;Incrementa el registro
  out 0x1234, r0  ;Envia el dato a puerto de salida
  jmp lazo        ;Repite el proceso