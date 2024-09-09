`define INVERTED_IO

module top (
    input  wire         board_clk,
    input  wire         board_rst,
    output wire [2:0]   leds,

    input  wire          GBA_CLK,
    input  wire          GBA_nWR,
    input  wire          GBA_nRD,
    input  wire          GBA_nCS,
    input  wire          GBA_VDD,
    inout  wire [15:0]   GBA_AD,
    inout  wire [7:0]    GBA_A,
    input  wire          GBA_nCS2,
    output wire          GBA_nREQ,

    output wire          sd_cs,
    output wire          sd_sck,
    output wire          sd_mosi,
    input  wire          sd_miso,
    input  wire          sd_det,

    output wire          ser_tx,
    input  wire          ser_rx,

    output wire [7:0]    debug
);

    // Flip IO
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

    // With PLL (use for ECP5 board)
    wire clk, clk_spi, pll_locked;
    wire rst = (!pll_locked) || rst_actual;
    PLL200 pll (
        .clk_in(board_clk),
        .clk_out(clk),
        .clk_spi(clk_spi),
        .locked(pll_locked)
    );

    GameBrian #(
        .CLK_FREQ(CLK_FREQ),
    ) gb (
        .clk      (clk     ),
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

        .spi_clk  (clk_spi ),
        .sd_cs    (sd_cs   ),
        .sd_sck   (sd_sck  ),
        .sd_mosi  (sd_mosi ),
        .sd_miso  (sd_miso ),
        .sd_det   (sd_det  ),

        .ser_tx   (ser_tx  ),
        .ser_rx   (ser_rx  ),

        .debug    (debug   )
    );
endmodule