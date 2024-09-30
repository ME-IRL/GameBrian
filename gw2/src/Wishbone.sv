interface Wishbone_bus #(
    WIDTH = 32
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