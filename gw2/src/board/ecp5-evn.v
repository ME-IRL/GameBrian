`default_nettype none
`timescale 1ns/1ns

`define INVERTED_IO

module top (
    input  wire          board_clk,
    output wire          board_clk_en,
    input  wire          board_rst,
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

    input  wire          sd_det,
    output wire          sd_cs,
    output wire          spi_mosi,
    input  wire          spi_miso,

    output wire          ser_tx,
    input  wire          ser_rx,

    output wire [7:0]    debug
);

    // IO is inverted on ECP5-EVN
    wire [7:0] leds_actual;
    wire rst_actual;

`ifdef INVERTED_IO
    assign leds = ~leds_actual;
    assign rst_actual = !board_rst;
`else
    assign leds = leds_actual;
    assign rst_actual = board_rst;
`endif

    // Clock and reset
    parameter CLK_FREQ = 200_000_000;
    assign board_clk_en = 1'b1;

    // With PLL
    wire clk, pll_locked;
    wire rst = (!pll_locked) || rst_actual;
    PLL200 pll (
        .clk_in   (board_clk ),
        .clk_out  (clk       ),
    );

    reg zero = 0;
    wire UCLK;
    USRMCLK spi_clk_u (
        .USRMCLKI(UCLK),
        .USRMCLKTS(zero)
    );

    GameBrian #(
        .CLK_FREQ (CLK_FREQ),
    ) gb (
        .clk      (clk        ),
        .rst      (rst_actual ),
        .leds     (leds_actual),

        .GBA_CLK  (GBA_CLK ),
        .GBA_nWR  (GBA_nWR ),
        .GBA_nRD  (GBA_nRD ),
        .GBA_nCS  (GBA_nCS ),
        .GBA_VDD  (GBA_VDD ),
        .GBA_AD   (GBA_AD  ),
        .GBA_A    (GBA_A   ),
        .GBA_nCS2 (GBA_nCS2),
        .GBA_nREQ (GBA_nREQ),

        .sd_det   (sd_det  ),
        .sd_cs    (sd_cs   ),
        .spi_sck  (UCLK    ),
        .spi_mosi (spi_mosi ),
        .spi_miso (spi_miso ),

        .ser_tx   (ser_tx  ),
        .ser_rx   (ser_rx  ),

        .debug    (debug   )
    );

endmodule

module USRMCLK (USRMCLKI, USRMCLKTS);
    input USRMCLKI, USRMCLKTS;
endmodule