package wishbone;
    typedef reg [31:0] u32;
endpackage

interface Wishbone_bus #(
    WIDTH = 32,
) (
    input clk,
    input rst
);

    logic [WIDTH-1:0]       adr;
    logic [WIDTH-1:0]       dat_miso;
    logic [WIDTH-1:0]       dat_mosi;

    logic [(WIDTH/8)-1:0] sel;
    logic we;
    logic stb;
    logic cyc;
    logic stall;
    logic ack;
    logic err;
    logic rty;

    modport M (
        output adr,
        input  dat_miso,
        output dat_mosi,
        output sel,
        output we,
        output stb,
        output cyc,
        input  stall,
        input  ack,
        input  err,
        input  rty
    );

    modport S (
        input  adr,
        output dat_miso,
        input  dat_mosi,
        input  sel,
        input  we,
        input  stb,
        input  cyc,
        output stall,
        output ack,
        output err,
        output rty
    );
endinterface

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
        .wbm_cyc_o(bus.cyc)
    );

endmodule