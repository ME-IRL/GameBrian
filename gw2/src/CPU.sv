module CPU_WB (
    Wishbone_bus bus
);
    picorv32_wb #() core (
        .wb_clk_i(bus.clk),
        .wb_rst_i(bus.rst),

        .wbm_adr_o(bus.adr),
        .wbm_dat_o(bus.dat_mosi),
        .wbm_dat_i(bus.dat_miso),
        .wbm_sel_o(bus.sel),
        .wbm_we_o (bus.we),
        .wbm_stb_o(bus.stb),
        .wbm_ack_i(bus.ack),
        .wbm_cyc_o(bus.cyc),

        .trap(),
	    .pcpi_valid(),
	    .pcpi_insn (),
	    .pcpi_rs1  (),
	    .pcpi_rs2  (),
	    .pcpi_wr   (),
	    .pcpi_rd   (),
	    .pcpi_wait (),
	    .pcpi_ready(),

	    .irq(),
	    .eoi(),

        .trace_valid(),
        .trace_data (),
        .mem_instr  ()
    );

endmodule