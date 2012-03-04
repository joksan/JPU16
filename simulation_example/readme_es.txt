Ejemplo de simulacion de JPU16
------------------------------

Este directorio tiene codigo de ejemplo para simular JPU16 utilizando el
simulador ISim de Xilinx. Incluido entre los archivos se encuentra un
desensamblador en formato VHDL. El mismo esta intencionado para facilitar la
visualizacion de los resultados de simulacion, puesto que da una buena idea de
lo que ocurre dentro del procesador por medio de mostrar la instruccion
ejecutada actualmente asi como sus argumentos. Una cosa que hay que notar acerca
del desensamblador es que este NO muestra codigo fuente, puesto que esta
informacion se pierde con anterioridad en el proceso de compilacion, asi que lo
que se obtiene son los puros numeros codificados en las instrucciones en vez de
variables o etiquetas de codigo.

Si no ha compilado e instaldo el ensamblador con anterioridad, por favor hagalo
ahora, puesto que es un requerimiento para el ejemplo.

Para correr el codigo de ejemplo, siga las siguientes indicaciones:

- Clonar el repositorio git o descomprimir los archivos en la PC.
- Crear un nuevo proyecto de ISE.
- Agregar los siguientes archivos al proyecto:
  jpu16src/JPU16.vhd
  jpu16src/JPU16_ALU.vhd
  jpu16src/JPU16_BUSES.vhd
  jpu16src/JPU16_CU.vhd
  jpu16src/JPU16_DEFS.vhd
  jpu16src/JPU16_REGS.vhd
  simulation_scripts/JPU16_DISASM.vhd
  simulation_example/JPU16_TEST_BENCH.vhd
- Compilar el codigo de ejemplo en "simulation_example/simulacion.asm" por medio
  de correr el makefile:
  $cd simulation_example
  $make
  Alternativamente, puede invocarse directamente jpu16asm con la opcion -v:
  $jpu16asm simulacion.asm -p 512 -r 1024 -v JPU16_MEM.vhd
- Agregar el codigo VHDL generado (JPU16_MEM.vhd) al proyecto de ISE.
- En el navegador de proyectos ISE, cambiar a la vista de simulacion y
  seleccionar la entidad llamada "Banca_JPU16" dentro de la jerarquia del
  proyecto. Luego expandir el nodo "ISim Simulator" en la lista de procesos y
  dar click derecho en el proceso llamado "Simulate Behavioral Model" para
  seleccionar propiedades.
- Activar la casilla llamada "Use Custom Simulation Command File", luego en el
  campo "Custom Simulation Command File" explorar y buscar el archivo
  "simulation_scripts/jpu16_simulation.tcl". Hacer click en OK para cerrar el
  cuadro de dialogo.
- Ejecutar el proceso llamado "Simulate Behavioral Model" para iniciar la
  simulacion de ISim.

Consejos y trucos.

- Si se realiza cualquier cambio al codigo del procesador, recuerde correr el
  makefile nuevamente y luego reiniciar completamente la simulacion.
- Puede agregarse cualquier hardware externo al procesador dentro del archivo de
  banca de prueba (JPU16_TEST_BENCH.vhd), por medio de editarlo.
- El script .tcl puede ser modificado para agregar (o remover) cualquier señal
  en la jerarquia VHDL, incluyendo señales en harware afuera del procesador.
- Es posible usar el mimso proyecto para simulacion y sintesis, pero algunos
  ajustes son necesarios. En particular, los archivos "JPU16_TEST_BENCH.vhd" y
  "JPU16_DISASM.vhd" deberian tener su asociacion de visualizacion establecida
  para simulacion solamente. Tambien, como la entidad de nivel superior (usada
  para sintesis) deberia contener al mismo procesador, y esta a su vez deberia
  estar subsecuentemente contenida en la banca de prueba, esto significa que el
  procesador estara localizado en un nivel de jerarquia diferente del que se ha
  definido en el script .tcl, asi que sera necesario realizarle algunos ajustes.