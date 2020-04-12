#*****************************************************************************
# This script is used to synthesize the RISC-V 
#*****************************************************************************

#to preserve rtl names in the netlist for power consumption estimation.
set power_preserve_rtl_hier_names true

#analyze all possible file contained in the work folder 
analyze -library WORK -format vhdl {/home/isa25/Desktop/RISCV/src/my_package.vhd}
analyze -library WORK -format vhdl {/home/isa25/Desktop/RISCV/src/ALU_package.vhd}
analyze -library WORK -format vhdl {/home/isa25/Desktop/RISCV/src/FU_package.vhd}
analyze -library WORK -format vhdl {/home/isa25/Desktop/RISCV/src/HDU_package.vhd}
analyze -library WORK -format vhdl {/home/isa25/Desktop/RISCV/src/RISCV_package.vhd}
analyze -library WORK -format vhdl {/home/isa25/Desktop/RISCV/src/CU_package.vhd}
analyze -library WORK -format vhdl {/home/isa25/Desktop/RISCV/src/FA.vhd}
analyze -library WORK -format vhdl {/home/isa25/Desktop/RISCV/src/MUX_2to1.vhd}
analyze -library WORK -format vhdl {/home/isa25/Desktop/RISCV/src/RCA.vhd}
analyze -library WORK -format vhdl {/home/isa25/Desktop/RISCV/src/MUX_4to1.vhd}
analyze -library WORK -format vhdl {/home/isa25/Desktop/RISCV/src/G_block.vhd}
analyze -library WORK -format vhdl {/home/isa25/Desktop/RISCV/src/PG_block.vhd}
analyze -library WORK -format vhdl {/home/isa25/Desktop/RISCV/src/PG_network.vhd}
analyze -library WORK -format vhdl {/home/isa25/Desktop/RISCV/src/carry_select_block.vhd}
analyze -library WORK -format vhdl {/home/isa25/Desktop/RISCV/src/MUX_8to1.vhd}
analyze -library WORK -format vhdl {/home/isa25/Desktop/RISCV/src/barrel_shifter.vhd}
analyze -library WORK -format vhdl {/home/isa25/Desktop/RISCV/src/HDU.vhd}
analyze -library WORK -format vhdl {/home/isa25/Desktop/RISCV/src/FU.vhd}
analyze -library WORK -format vhdl {/home/isa25/Desktop/RISCV/src/RF.vhd}
analyze -library WORK -format vhdl {/home/isa25/Desktop/RISCV/src/BPU.vhd}
analyze -library WORK -format vhdl {/home/isa25/Desktop/RISCV/src/adder_subtractor.vhd}
analyze -library WORK -format vhdl {/home/isa25/Desktop/RISCV/src/carry_generator.vhd}
analyze -library WORK -format vhdl {/home/isa25/Desktop/RISCV/src/sum_generator.vhd}
analyze -library WORK -format vhdl {/home/isa25/Desktop/RISCV/src/PC.vhd}
analyze -library WORK -format vhdl {/home/isa25/Desktop/RISCV/src/reg.vhd}
analyze -library WORK -format vhdl {/home/isa25/Desktop/RISCV/src/branch_comp.vhd}
analyze -library WORK -format vhdl {/home/isa25/Desktop/RISCV/src/IR.vhd}
analyze -library WORK -format vhdl {/home/isa25/Desktop/RISCV/src/CU.vhd}
analyze -library WORK -format vhdl {/home/isa25/Desktop/RISCV/src/comparator.vhd}
analyze -library WORK -format vhdl {/home/isa25/Desktop/RISCV/src/logic_block.vhd}
analyze -library WORK -format vhdl {/home/isa25/Desktop/RISCV/src/ALU.vhd}
analyze -library WORK -format vhdl {/home/isa25/Desktop/RISCV/src/datapath.vhd}
analyze -library WORK -format vhdl {/home/isa25/Desktop/RISCV/src/RISCV.vhd}

#elaborate top entity, set the variables
elaborate RISCV -architecture structural -library WORK -parameters "BPU_TAG_FIELD_SIZE = 8 , BPU_SET_FIELD_SIZE = 3, BPU_LINES_PER_SET = 4"

#**************** CONSTRAINT THE SYNTHESIS ****************#
#timing constraint. WCP holds the minimum value of the delay
set WCP 2
#forces a combinational max delay from any input to any output 
set_max_delay $WCP -from [all_inputs] -to [all_outputs]
#create a clock signal with a period equal to the worst critical path
create_clock -name "CLK" -period $WCP CLK
#clock uncertainty (jitter)
set_clock_uncertainty 0.07 [get_clocks CLK]
#max input delay
set_input_delay 0.5 -max -clock CLK [remove_from_collection [all_inputs] CLK]
#max output delay
set_output_delay 0.5 -max -clock CLK [all_outputs]
#output load equal to the buffer input capacitance of the library
set OUT_LOAD [load_of NangateOpenCellLibrary/BUF_X4/A]
set_load $OUT_LOAD [all_outputs]
#verify the correct creation of the clock
report_clock > clock_test.rpt
set_dont_touch_network CLK

#compile ultra command, in order to perform an advanced synthesis
compile_ultra

#perform retiming on the compiled netlist
optimize_register

ungroup -all -flatten
change_names -hierarchy -rules verilog
#delay description
write_sdf ../netlist/RISCV.sdf
#write verilog netlist
write -f verilog -hierarchy -output ../netlist/RISCV.v
#input/output constraints
write_sdc ../netlist/RISCV.sdc

report_timing > ../report/timing.rpt
report_area > ../report/area.rpt
report_power > ../report/power.rpt

