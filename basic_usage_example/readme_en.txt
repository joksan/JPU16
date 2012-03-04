Indications for running the example project
-------------------------------------------
This directory has several example files that are used to run a simple demo of
blinking LEDs.
Also a .ucf file is included that allows the demo to be run on a Papilio One
FPGA board (500K gate version), with pin definitions to connect all the LED to
port A. If you don't have a Papilio board, you can modify the .ucf file and
configure it to the hardware of your choice.

Please note: The soft core processor is designed to be run on any type of FPGA.
The instructions below are for Xilinx FPGA's. In order to use the processor on
other plattforms (e.g. Altera) some adjustmens should be made.

In order to run the example, follow the steps given below:

- Clone the git repository or uncompress the downloaded archive into your PC.
- Create a project with ISE Project Navigator with the name "proyecto_ISE" in
  the directory called "basic_usage_example".
- Add the following files into the project:
  basic_usage_example/sistema_ejemplo.vhd
  basic_usage_example/sistema_ejemplo.ucf
  jpu16src/JPU16.vhd
  jpu16src/JPU16_ALU.vhd
  jpu16src/JPU16_BUSES.vhd
  jpu16src/JPU16_CU.vhd
  jpu16src/JPU16_DEFS.vhd
  jpu16src/JPU16_REGS.vhd
- Run the example makefile that comes along with the program to generate the
  files with the memory definitions in VHDL format:
  $cd basic_usage_example
  $make codigo_hdl
- Add the generated files to the ISE project
  basic_usage_example/JPU16_MEM.vhd
  basic_usage_example/mapa_memoria.bmm
- Run the full sinthesis process with ISE
- Upload the generated bitfile into the FPGA with the command:
  $papilio-prog -f proyecto_ISE/sistema_ejemplo.bit
  Note: If you don't have a Papilio board, you may use the software intended for
  your hardware instead.

In order to update the FPGA with an newer version of the program without doing a
full sinthesis, follow these steps:

- Generate the file sistema_reprogramado.bit by running make without arguments:
  $make
- Upload the generated bitfile into the FPGA with the command:
  $sudo papilio-prog -f sistema_reprogramado.bit

Additional notes:
- There is a possibility that you need to adjust some paths or names defined at
  the beggining of the makefile in the case that errors exist. In particular, it
  could be necessary to redefine the path to the ISE configuration script, which
  is defined in the variable called "config_ise", specially if you are using a
  more recent version of the software.