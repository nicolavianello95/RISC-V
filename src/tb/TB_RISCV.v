module TB_RISCV ();

	wire [31:0] IRAM_ADDR, DRAM_ADDR, IRAM_OUT, DRAM_OUT, DRAM_IN;
	wire [1:0] DRAM_WR_EN;
	reg IRAM_CS, DRAM_CS;
	wire CLK, RST;
	
	IRAM IRAM_instance(
		.DATA_OUT(IRAM_OUT),
		.ADDR(IRAM_ADDR[15:0]),
		.CS(IRAM_CS)
	);
	
	always @ (IRAM_ADDR) begin
		if (IRAM_ADDR[31:16]=='H0040)
			IRAM_CS=1;
		else
			IRAM_CS=0;
	end
	
	DRAM DRAM_instance(
		.DATA_IN(DRAM_IN),
		.DATA_OUT(DRAM_OUT),
		.ADDR(DRAM_ADDR[15:0]),
		.WR_EN(DRAM_WR_EN),
		.CS(DRAM_CS),
		.CLK(CLK)
	);
	
	always @ (DRAM_ADDR) begin
		if (DRAM_ADDR[31:16]=='H1001)
			DRAM_CS=1;
		else
			DRAM_CS=0;
	end
	
	clk_gen clk_gen_instance(
		.CLK(CLK),
		.RST(RST)
	);
	
	RISCV DUT(
		.IRAM_ADDR(IRAM_ADDR),
		.IRAM_OUT(IRAM_OUT),
		.DRAM_ADDR(DRAM_ADDR),
		.DRAM_OUT(DRAM_OUT),
		.DRAM_IN(DRAM_IN),
		.DRAM_WR_EN(DRAM_WR_EN),
		.CLK(CLK),
		.RST(RST)
	);
	
endmodule