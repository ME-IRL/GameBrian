module GameBrian #(
    parameter CLK_FREQ = 200_000_000
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

    input  wire          sd_det,
    output wire          sd_cs,
    output wire          spi_sck,
    output wire          spi_mosi,
    input  wire          spi_miso,

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
        .leds()
    );

    // UART Serial
    assign ser_tx = ser_rx;

    SPI spi_wires();
    assign spi_sck = spi_wires.sck;
    assign spi_mosi = spi_wires.mosi;
    assign spi_wires.miso = spi_miso;
    assign sd_cs = spi_wires.cs_n;

    Wishbone_bus bus(clk, rst);
    SPI_WB  #(
        .CLK_FREQ(CLK_FREQ)
    ) spi (
        .bus(bus.S),
        .spi(spi_wires.M),
        .debug()
    );

    dummy_wb_master dummy (
        .bus(bus.M),
        .debug(leds)
    );

endmodule