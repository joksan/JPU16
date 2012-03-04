JPU16 Simulation example
------------------------

This directory contains some example code to simulate JPU16 using Xilinx's ISim
simulator. Included along the scripts is a dissasembler in VHDL format. It is
intended to ease the viewing of the simulation results, as it gives a good clue
on what is happening inside the processor by showing the currently executed
instruction and its arguments. One thing to note about the dissasembler is that
it does NOT show source code, as that information is already lost in the
compiling process, so what you get to see are the bare numbers coded into the
instructions instead of variables or code labels.

If you have not compiled and installed the assembler first, please do so now, as
this is required for this example.

In order to run the example code, follow the steps below:

- Clone the git repository or uncompress the downloaded archive into your PC.
- Create a new ISE project.
- Add the following files to the project:
  jpu16src/JPU16.vhd
  jpu16src/JPU16_ALU.vhd
  jpu16src/JPU16_BUSES.vhd
  jpu16src/JPU16_CU.vhd
  jpu16src/JPU16_DEFS.vhd
  jpu16src/JPU16_REGS.vhd
  simulation_scripts/JPU16_DISASM.vhd
  simulation_example/JPU16_TEST_BENCH.vhd
- Compile the example code in "simulation_example/simulacion.asm" by running the
  makefile:
  $cd simulation_example
  $make
  Alternatively you may directly invoke jpu16asm with the -v option:
  $jpu16asm simulacion.asm -p 512 -r 1024 -v JPU16_MEM.vhd
- Add the generated VHDL source (JPU16_MEM.vhd) into the ISE project.
- In ISE Project Navigator, switch to simulation view then select the entity
  called "Banca_JPU16" in the project hierarchy. Expand the "ISim Simulator"
  node in the list of processes and right-click on the process called "Simulate
  Behavioral Model" then select process properties.
- Tick the check box called "Use Custom Simulation Command File", then browse
  and select the file "simulation_scripts/jpu16_simulation.tcl" in the field
  called "Custom Simulation Command File". Click OK to close the dialog box.
- Run the process called "Simulate Behavioral Model" to start ISim simulation.

Tips and hints.

- If any change is made to the processor code remember to run the makefile again
  and then completely restart simulation.
- You may add any external hardware to the processor in the testbench file
  (JPU16_TEST_BENCH.vhd), by editing it.
- The .tcl script can be modified to add (or remove) any signal in the VHDL
  hierarchy, including signals in hardware outside the processor.
- It is possible to use the same project for simulation and synthesis, but some
  adjustments will be necesary. In particular, the files "JPU16_TEST_BENCH.vhd"
  and "JPU16_DISASM.vhd" should have their view association set to simulation
  only. Also, as the top-level entity (used for synthesis) should contain the
  processor itself, and this should be subsequently contained in the testbench,
  then the processor will be located in a different hierarchy level than is
  defined in the .tcl script, so some adjustments should be made on it.