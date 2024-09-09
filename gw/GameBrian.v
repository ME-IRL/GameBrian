// `define SIM

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

    // LED Blinky
    Blinky #(
        .CLK_FREQ(CLK_FREQ),
        .LED_FREQ(4)
    ) b (
        .clk(clk),
        .rst(rst),
        .leds(leds)
    );

    // GBA
    reg  [7:0]  gba_miso;
    wire [15:0] gba_addr;
    wire        gba_write;
    wire [7:0]  gba_mosi;
    GBA gba (
        .clk(clk),
        .rst(rst),
        .GBA_CLK (GBA_CLK ),
        .GBA_nWR (GBA_nWR ),
        .GBA_nRD (GBA_nRD ),
        .GBA_nCS (GBA_nCS ),
        .GBA_VDD (GBA_VDD ),
        .GBA_AD  (GBA_AD  ),
        .GBA_A   (GBA_A   ),
        .GBA_nCS2(GBA_nCS2),
        .GBA_nREQ(GBA_nREQ),

        .addr(gba_addr),
        .mosi(gba_mosi),
        .miso(gba_miso),
        .write(gba_write)
    );

    // RAM
    wire        ram_write;
    wire [7:0]  ram_miso;
    RAM ram(
        .clk(clk),
        .rst(rst),
        .addr(gba_addr),
        .mosi(gba_mosi),
        .miso(ram_miso),
        .write(ram_write)
    );

    // SPI
    wire        spi_write;
    wire [7:0]  spi_miso;
    // SPI #(
    //     .CLK_FREQ(CLK_FREQ),
    //     .SPI_FREQ(200_000)
    // ) spi (
    //     .clk(clk),
    //     .rst(rst),
    //     .addr(gba_addr),
    //     .mosi(gba_mosi),
    //     .miso(spi_miso),
    //     .write(spi_write),

    //     .sd_cs(sd_cs),
    //     .sd_sck(sd_sck),
    //     .sd_mosi(sd_mosi),
    //     .sd_miso(sd_miso),
    //     .sd_det(sd_det),

    //     .debug(debug)
    // );
    // assign leds = {sd_present, spi[1][6:0]};
    assign sd_sck = spi_clk;
    assign sd_mosi = sd_miso;
    assign sd_cs = 0;
    assign spi_miso = 0;

    // Interconnect
    wire is_spi = ((gba_addr & 16'hFFFE) == 16'h0000);
    wire [7:0] miso = is_spi ? spi_miso : ram_miso;

    always @(posedge clk)
        if(rst)
            gba_miso <= 8'h0;
        else
            gba_miso <= miso;

    assign spi_write = is_spi && gba_write;
    assign ram_write = !is_spi && gba_write;

    // Debug
    assign debug = 8'h0;

    // Serial TODO
    assign ser_tx = ser_rx;

endmodule