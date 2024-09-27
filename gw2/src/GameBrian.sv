import wishbone::*;

module GameBrian #(
    parameter CLK_FREQ = 200_000_000,
) (
    input  wire          clk,
    input  wire          rst,
    output wire [7:0]    leds,

    input  wire          GBA_CLK,
    input  wire          GBA_nWR,
    input  wire          GBA_nRD,
    input  wire          GBA_nCS,
    input  wire          GBA_VDD,
    inout  wire [15:0]   GBA_AD,
    inout  wire [7:0]    GBA_A,
    input  wire          GBA_nCS2,
    output wire          GBA_nREQ,

    input  wire          spi_clk,
    output wire          sd_cs,
    output wire          sd_sck,
    output wire          sd_mosi,
    input  wire          sd_miso,
    input  wire          sd_det,

    output wire          ser_tx,
    input  wire          ser_rx,

    output wire [7:0]    debug
);

    assign debug = 8'h0;

    // LED Blinky
    Blinky #(
        .CLK_FREQ(CLK_FREQ),
        .LED_FREQ(1)
    ) b (
        .clk(clk),
        .rst(rst),
        .leds(leds),
    );

    Wishbone_bus bus(clk, rst);

    CPU_WB core (bus.M);

endmodule