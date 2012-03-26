JPU16
A soft core processor for Xilinx and Altera FPGAs, by Joksan Alvarado

JPU16 is a relatively simple 16-bit soft processor written in VHDL, designed to
provide a simple way to interconnect external pripherals with relatively little
effort and write programs for it quickly, providing CPU processing capabilities
to any FPGA project.

A basic assembler is provided along with the processor, wich takes source code
in a native assembly language and generates its output in several formats, each
one providing a different way to program the processor inside an FPGA.

Project features:
- Soft core processor language: VHDL - with no especific FPGA architecture
  features used, wich makes for very portable code.
- Tested FPGA architectures:
  - Xilinx Spartan 3 (R) series.
  - Xilinx Spartan 6 (R) series.
  - Altera Cyclone IV (R) series, with limited assembler support at the moment.
- The assembler runs on Linux, is coded in plain C and compiles with gcc.

Processor features:
- Processor architecture: RISC (load and store machine type).
- Bus architecture: Harvard (separate program, data RAM and I/O buses).
- General purpose registers:
  - Number of registers available: 16 (named r0 to r15)
  - Register size: 16-bit.
  - Every register has the same capabilities and can be used interchangeably
- Processor flags: Carry, Zero, Negative, Overflow and Interrupt
- Data RAM:
  - Data word size: 16-bit.
  - Configurable address width, supporting several memory sizes depending on
    application requirements and FPGA resource avaiability.
  - Maximum memory size: 64K locations (16-bit addresses).
  - Internally managed: the user does not need to connect to it externally in
    HDL source.
  - Flat memory model (no banking required)
- Program memory:
  - Instruction size: 26-bit
  - Configurable address width.
  - Maximum program size: 64K instructions.
  - Internally managed.
  - Flat memory model.
- I/O Bus:
  - Data size: 16-bit.
  - Address width: 16 bit.
  - Externally managed: the user determines external device mapping in HDL
    source.
- 8 addressing modes:
  - Implicit (no arguments).
  - Register.
  - Register, immediate/literal.
  - Register, register.
  - Direct, register.
  - Indirect, register.
  - Relative jump/call.
  - Indirect jump/call.
- 32 level deep call stack.
- 1 external maskable interrupt
- Reset vector at 0x0000.
- Interrupt vector at last address of program memory.
- Instruction set capabilities:
  - Direct clearing/setting of flags.
  - Non destructive test and compare instructions.
  - Jumps can be made either inconditionally or based on any single flag value.
  - Calls can also be made inconditionally or based on a flag.
  - Data movement possible in 4 different addressing modes.
  - Separate input/output instructions for I/O bus.
  - ALU instructions for addition/subtraction with optional carry/borrow.
  - ALU instructions for AND, OR, NOT and XOR logical operations.
  - A 2-stage barrel shifter unit provides instructions for shifting and
    rotating registers left or right by up to 15 positions, with either ones or
    zeroes entering when shifting.
  - Instructions for rotating registers left or right one position at a time
    while involving the carry flag.
- Instruction timing is 2 clock cycles for every instruction, even jumps and
  calls.
- Maximum clock speed is about 90MHz to 100MHz on an Spartan 3E FPGA. Higher
  speeds are possible on Spartan 6 (about 160MHz) and Cyclone IV (about 150MHz).