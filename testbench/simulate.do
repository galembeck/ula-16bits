# Projeto CPU 16 bits | Script de simulação do ModelSim
#
# Como usar (no ModelSim):
#   1. File -> Change Directory... -> escolha a pasta do projeto (ula-16bits)
#   2. No Transcript, digite:  do testbench/simulate.do
#
# O script compila todos os arquivos, roda o testbench e abre as ondas.

transcript on
onerror {resume}

# Biblioteca de trabalho (recriada do zero a cada execução).
if {[file exists work]} { vdel -lib work -all }
vlib work
vmap work work

# Compilação: primeiro o pacote de componentes, depois os blocos, a CPU e o testbench.
vcom -2008 -work work components.vhd
vcom -2008 -work work register_16bits.vhd
vcom -2008 -work work register_bank.vhd
vcom -2008 -work work multiplexers.vhd
vcom -2008 -work work extenders.vhd
vcom -2008 -work work alu_control.vhd
vcom -2008 -work work arithmetic_logic_unit.vhd
vcom -2008 -work work memory.vhd
vcom -2008 -work work control_unit.vhd
vcom -2008 -work work datapath.vhd
vcom -2008 -work work cpu.vhd
vcom -2008 -work work testbench/cpu_tb.vhd

# Simulação.
vsim -t ns work.cpu_tb

# Ondas (em hexadecimal).
add wave -noupdate -divider "Controle"
add wave -noupdate /cpu_tb/clk
add wave -noupdate /cpu_tb/reset
add wave -noupdate /cpu_tb/uut/controlUnitInstance/currentState
add wave -noupdate -divider "Datapath"
add wave -noupdate -radix hex /cpu_tb/uut/datapathInstance/pc
add wave -noupdate -radix hex /cpu_tb/uut/datapathInstance/instruction
add wave -noupdate -radix hex /cpu_tb/uut/datapathInstance/aRegister
add wave -noupdate -radix hex /cpu_tb/uut/datapathInstance/bRegister
add wave -noupdate -radix hex /cpu_tb/uut/datapathInstance/aluResult
add wave -noupdate -radix hex /cpu_tb/uut/datapathInstance/aluOut
add wave -noupdate /cpu_tb/uut/datapathInstance/zero
add wave -noupdate -radix hex /cpu_tb/uut/datapathInstance/mdr
add wave -noupdate -divider "Registradores"
add wave -noupdate -radix hex /cpu_tb/uut/datapathInstance/registerBankInstance/r1
add wave -noupdate -radix hex /cpu_tb/uut/datapathInstance/registerBankInstance/r2
add wave -noupdate -radix hex /cpu_tb/uut/datapathInstance/registerBankInstance/r3
add wave -noupdate -radix hex /cpu_tb/uut/datapathInstance/registerBankInstance/r4
add wave -noupdate -radix hex /cpu_tb/uut/datapathInstance/registerBankInstance/r5
add wave -noupdate -radix hex /cpu_tb/uut/datapathInstance/registerBankInstance/r6
add wave -noupdate -radix hex /cpu_tb/uut/datapathInstance/registerBankInstance/r7
add wave -noupdate -divider "Memoria"
add wave -noupdate -radix hex {/cpu_tb/uut/datapathInstance/memoryInstance/ram(30)}

run -all
wave zoom full
