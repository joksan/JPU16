Indicaciones para correr el proyecto de ejemplo
-----------------------------------------------
Este directorio cuenta con varios archivos de ejemplo para correr un simple demo
de LEDs parpadeantes.
Asimismo, se incluye un archivo .ucf que permite correr el demo en una tarjeta
Papilio One (version de 500K compuertas), con definiciones de pines para
conectar los LED al puerto A de la misma. En caso de no contar con una tarjeta
Papilio, puede modificar el archivo .ucf para configurarlo al hardware de su
eleccion.

Por favor note: El procesador esta diseñado para poder correrse en cualquier
tipo de FPGA. Las instrucciones abajo son para FPGA de Xilinx. Para poder usar
el procesador en otras plataformas (por ejemplo Altera) deberian hacerse algunos
ajustes.

Para correr el ejemplo, siga las siguientes indicaciones:

- Clonar el repositorio git o descomprimir los archivos en la PC.
- Crear un proyecto con el Project Navigator de ISE con el nombre "proyecto_ISE"
  en el directorio llamado "basic_usage_example".
- Agregar al proyecto los archivos siguientes:
  basic_usage_example/sistema_ejemplo.vhd
  basic_usage_example/sistema_ejemplo.ucf
  jpu16src/JPU16.vhd
  jpu16src/JPU16_ALU.vhd
  jpu16src/JPU16_BUSES.vhd
  jpu16src/JPU16_CU.vhd
  jpu16src/JPU16_DEFS.vhd
  jpu16src/JPU16_REGS.vhd
- Correr el makefile de ejemplo que viene con el programa para generar los
  archivos con las definiciones de la memoria en formato VHDL:
  $cd basic_usage_example
  $make codigo_hdl
- Agregar los archivos generados al proyecto de ISE:
  basic_usage_example/JPU16_MEM.vhd
  basic_usage_example/mapa_memoria.bmm
- Realizar el proceso de sintesis completa mediante ISE
- Subir el bitfile generado al FPGA mediante el comando
  $papilio-prog -f proyecto_ISE/Sistema_ejemplo.bit
  Nota: En caso de no contar con una tarjeta Papilio, puede usarse el software
  designado para su hardware en vez.

Para actualizar el FPGA con una version mas reciente del programa sin necesidad
de hacer sintesis completa, seguir los siguientes pasos:

- Generar el archivo sistema_reprogramado.bit corriendo make sin argumentos:
  $make
- Subir el bitfile generado al FPGA mediante el comando
  $sudo papilio-prog -f sistema_reprogramado.bit

Notas adicionales:
- Existe la posibilidad de tener que ajustar algunas de las rutas o nombres
  definidos al principio del makefile en caso que existan errores. En
  particular, podria ser necesario redefinir la ruta del script de configuracion
  de ISE, definido en la variable nombrada "config_ise", sobretodo si se usa una
  version mas reciente del software.