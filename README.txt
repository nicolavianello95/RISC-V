************************************************************************************
* 								RV32I PROJECT										   
* 				   TESSER ANDREA		   VIANELLO NICOLA						   
************************************************************************************
Folder's organization:

innovous: contains all the useful files and reports generated during and after the
place-and-route phase in Cadence Innovous environment.
conn.rpt and geom.rpt show the successful outcome of the verification phase.
The netlists generated at the end of the process are saved in verilog format as: 
RISCV_pr_standard.v and RISCV_pr_custom.v

final_report: The final technical report of our work in pdf format.

scripts: Scripts used for simulation, synthesis and place-and-route

sim: Source code (.asm) and binary (.hex) of the programs used for the design verification 

src: Here all the files that compose the design are stored.
In the tb subfolder there are all the files used in the testbench.

syn: Inside it you can find: reports for area, timing, power and switching activity;
.sdc and .sdf files; the verilog synthesized netlist.

