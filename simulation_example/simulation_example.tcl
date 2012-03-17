wave add /banca_jpu16/test_cpu/SysClk
wave add /banca_jpu16/test_cpu/PC -radix unsigned
wave add /JPU16_DISASM_DEFS/Instruccion -radix ascii -color cyan

set grupo_regs [group add registros]
wave add /banca_jpu16/test_cpu/REGS_RXX/RegsR(15) -name r15 -into $grupo_regs -radix hex
wave add /banca_jpu16/test_cpu/REGS_RXX/RegsR(14) -name r14 -into $grupo_regs -radix hex
wave add /banca_jpu16/test_cpu/REGS_RXX/RegsR(13) -name r13 -into $grupo_regs -radix hex
wave add /banca_jpu16/test_cpu/REGS_RXX/RegsR(12) -name r12 -into $grupo_regs -radix hex
wave add /banca_jpu16/test_cpu/REGS_RXX/RegsR(11) -name r11 -into $grupo_regs -radix hex
wave add /banca_jpu16/test_cpu/REGS_RXX/RegsR(10) -name r10 -into $grupo_regs -radix hex
wave add /banca_jpu16/test_cpu/REGS_RXX/RegsR(9) -name r9 -into $grupo_regs -radix hex
wave add /banca_jpu16/test_cpu/REGS_RXX/RegsR(8) -name r8 -into $grupo_regs -radix hex
wave add /banca_jpu16/test_cpu/REGS_RXX/RegsR(7) -name r7 -into $grupo_regs -radix hex
wave add /banca_jpu16/test_cpu/REGS_RXX/RegsR(6) -name r6 -into $grupo_regs -radix hex
wave add /banca_jpu16/test_cpu/REGS_RXX/RegsR(5) -name r5 -into $grupo_regs -radix hex
wave add /banca_jpu16/test_cpu/REGS_RXX/RegsR(4) -name r4 -into $grupo_regs -radix hex
wave add /banca_jpu16/test_cpu/REGS_RXX/RegsR(3) -name r3 -into $grupo_regs -radix hex
wave add /banca_jpu16/test_cpu/REGS_RXX/RegsR(2) -name r2 -into $grupo_regs -radix hex
wave add /banca_jpu16/test_cpu/REGS_RXX/RegsR(1) -name r1 -into $grupo_regs -radix hex
wave add /banca_jpu16/test_cpu/REGS_RXX/RegsR(0) -name r0 -into $grupo_regs -radix hex

wave add /banca_jpu16/test_cpu/Banderas
wave add /banca_jpu16/test_cpu/IO_Din -radix hex
wave add /banca_jpu16/test_cpu/IO_Dout -radix hex
wave add /banca_jpu16/test_cpu/IO_Addr -radix hex
wave add /banca_jpu16/test_cpu/IO_RD
wave add /banca_jpu16/test_cpu/IO_WR
run 500ns