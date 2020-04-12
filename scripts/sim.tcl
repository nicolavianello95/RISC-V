onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -format Logic -label CLOCK /TB_RISCV/CLK
add wave -noupdate -format Logic -label RESET /TB_RISCV/RST
add wave -noupdate -divider IRAM
add wave -noupdate -color Magenta -format Literal -label DATA_OUT -radix hexadecimal /TB_RISCV/IRAM_instance/data_out
add wave -noupdate -color Magenta -format Literal -label ADDRESS -radix hexadecimal /TB_RISCV/IRAM_instance/addr
add wave -noupdate -divider DRAM
add wave -noupdate -color Blue -format Literal -label DATA_IN -radix hexadecimal /TB_RISCV/DRAM_instance/data_in
add wave -noupdate -color Blue -format Literal -label ADDRESS -radix hexadecimal /TB_RISCV/DRAM_instance/addr
add wave -noupdate -color Blue -format Literal -label WRITE_ENABLE /TB_RISCV/DRAM_instance/wr_en
add wave -noupdate -color Blue -format Literal -label DRAM(28) -radix decimal /TB_RISCV/DRAM_instance/mem(28)
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {0 ns} 0}
configure wave -namecolwidth 281
configure wave -valuecolwidth 100
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
update
WaveRestoreZoom {0 ns} {200 ns}
