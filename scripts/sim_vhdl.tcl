onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -label CLK /tb_riscv/clk
add wave -noupdate -label RST /tb_riscv/rst
add wave -noupdate -divider IF
add wave -noupdate -label IRAM_OUT -radix hexadecimal /tb_riscv/iram_out
add wave -noupdate -label PC -radix hexadecimal /tb_riscv/dut/datapath_instance/pc_if
add wave -noupdate -divider ID
add wave -noupdate -label OPCODE /tb_riscv/dut/cu_instance/opcode
add wave -noupdate -label FUNCT7 -radix hexadecimal /tb_riscv/dut/cu_instance/funct7
add wave -noupdate -label MISPREDICTION /tb_riscv/dut/misprediction
add wave -noupdate -label BRANCH_COND /tb_riscv/dut/datapath_instance/branch_comp_instance/branch_cond
add wave -noupdate -label BRANCH_COMP /tb_riscv/dut/datapath_instance/branch_is_taken
add wave -noupdate -divider EXE
add wave -noupdate -label ALU_IN1_EXE -radix decimal /tb_riscv/dut/datapath_instance/alu_in1_exe
add wave -noupdate -label ALU_IN2_EXE -radix decimal /tb_riscv/dut/datapath_instance/alu_in2_exe
add wave -noupdate -label ALU_OUT_EXE -radix decimal /tb_riscv/dut/datapath_instance/alu_out_exe
add wave -noupdate -label FUNC /tb_riscv/dut/datapath_instance/alu_instance/func
add wave -noupdate -divider MEM
add wave -noupdate -label DRAM_ADDR -radix decimal /tb_riscv/dram_instance/addr
add wave -noupdate -label DRAM_IN -radix decimal /tb_riscv/dram_instance/data_in
add wave -noupdate -label WR_EN /tb_riscv/dram_instance/wr_en
add wave -noupdate -label DRAM_OUT_EXT -radix decimal /tb_riscv/dut/datapath_instance/dram_out_ext
add wave -noupdate -divider WB
add wave -noupdate -label RF_WR_ADDR_WB -radix unsigned /tb_riscv/dut/datapath_instance/rf_instance/addr_wr
add wave -noupdate -label RF_IN_WB -radix decimal /tb_riscv/dut/datapath_instance/rf_in_wb
add wave -noupdate -divider REG
add wave -noupdate -label MEM(28) -radix decimal /tb_riscv/dram_instance/mem(28)
add wave -noupdate -label REG4 -radix hexadecimal /tb_riscv/dut/datapath_instance/rf_instance/registers(4)
add wave -noupdate -label REG10 -radix decimal /tb_riscv/dut/datapath_instance/rf_instance/registers(10)
add wave -noupdate -label REG13 -radix decimal /tb_riscv/dut/datapath_instance/rf_instance/registers(13)
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {155000 ps} 0}
configure wave -namecolwidth 143
configure wave -valuecolwidth 114
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ns
update
WaveRestoreZoom {114307 ps} {163258 ps}
