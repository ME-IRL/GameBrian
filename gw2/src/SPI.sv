interface SPI;
    logic sck;
    logic mosi;
    logic miso;
    logic cs_n;

    modport M (
        output sck,
        output mosi,
        input  miso,
        output cs_n
    );

    modport S (
        input  sck,
        input  mosi,
        output miso,
        input  cs_n
    );
endinterface

module SPI_WB #(
    parameter CLK_FREQ = 200_000_000,
    parameter SPI_FREQ = 25_000_000
) (
    Wishbone_bus.S bus,
    SPI.M spi,
    output [7:0] debug
);

    wire bus_request = (bus.stb) && (!bus.stall) && (!bus.we);

    // Generate SPI clock
    reg spi_clk_en = 0;

    localparam int clkdiv_width = $clog2(CLK_FREQ/SPI_FREQ)+1;
    localparam int toggle_val = (CLK_FREQ/(2*SPI_FREQ))-1;
    reg [clkdiv_width-1:0] clk_counter;

    wire toggle = (clk_counter == clkdiv_width'(toggle_val));

    always @(posedge bus.clk or posedge bus.rst) begin
        if (bus.rst) begin
            clk_counter <= 0;
            spi.sck <= 1;
        end else begin
            if(spi_clk_en) begin
                if(toggle) begin
                    spi.sck <= ~spi.sck;
                    clk_counter <= 0;
                end else begin
                    clk_counter <= clk_counter + 1;
                end
            end
        end
    end

    wire clkp = (toggle && !spi.sck);
    wire clkn = (toggle && spi.sck);

    // ACK Delay
    reg [5:0] ack_delay = 6'h0;
    always @(posedge bus.clk or posedge bus.rst) begin
        if(bus.rst) begin
            ack_delay <= 6'h0;
        end else begin
            if(bus_request)
                ack_delay <= 6'd40;
            else if((ack_delay > 0) && clkp)
                ack_delay <= ack_delay - 1;
        end
    end

    // Bus and state control
    always @(posedge bus.clk or posedge bus.rst) begin
        if(bus.rst) begin
            spi.cs_n <= 1;
            bus.ack <= 0;
            bus.stall <= 0;
            spi_clk_en <= 0;
        end else begin
            if(bus_request) begin
                spi.cs_n <= 0;
                spi_clk_en <= 1;
                bus.ack <= 0;
                bus.stall <= 1;
            end else if(ack_delay == 0 && clkp) begin
                spi_clk_en <= 0;
                spi.cs_n <= 1;
                bus.stall <= 0;
                bus.ack <= 1;
                bus.dat_miso <= {24'h0, rxfifo[7:0]};
            end else begin
                bus.ack <= bus.stb && bus.we;
                bus.dat_miso <= 0;
            end
        end
    end

    // Transmit and shift on negedge
    reg [32:0] txfifo = 33'h0;
    reg [31:0] rxfifo = 32'h0;
    always @(posedge bus.clk or posedge bus.rst) begin
        if(bus.rst) begin
            txfifo <= 33'h0;
            rxfifo <= 32'h0;
        end else begin
            if(bus_request) begin
                txfifo <= { 1'h1, 8'h03, bus.adr[23:0] };
            end else if(clkn) begin
                txfifo <= { txfifo[31:0], 1'b0 };
            end else if(clkp) begin
                rxfifo <= { rxfifo[30:0], spi.miso };
            end
        end
    end

    assign spi.mosi = txfifo[32];

    assign debug = { 8'h0 };

endmodule


module dummy_wb_master #(
    parameter int OFFSET = 32'h100_000,
) (
    Wishbone_bus.M bus,
    output [7:0] debug
);

    reg [4:0] counter = 0;
    assign bus.adr = OFFSET + counter;

    assign bus.dat_mosi = 32'hXXXXXXXX;
    assign bus.we = 0;
    
    wire idle = (!bus.stall) && (!bus.cyc) && (!bus.ack);

    reg[25:0] div = 0;

    always @(posedge bus.clk or posedge bus.rst) begin
        if(bus.rst) begin
            bus.cyc <= 0;
            bus.stb <= 0;

            counter <= 32'h50000;
        end else begin
            if(idle) begin
                div <= div + 1;
                if(div == 0) begin
                    bus.cyc <= 1;
                    bus.stb <= 1;
                end
            // end else if(bus.stall) begin
            end else if(bus.ack) begin
                bus.cyc <= 0;
                counter <= counter + 1;
                debug <= bus.dat_miso[7:0];
            end else if(bus.stb) begin
                bus.stb <= 0;
            end
        end
    end

    // assign debug = counter[7:0];
    // assign debug = {bus.cyc, bus.stall, bus.ack, bus.adr[4:0]};
    // assign debug = {bus.cyc, bus.dat_miso[6:0]};

endmodule

module spi_tb;

    bit clk = 1;
    bit rst = 0;

    wire sck;
    bit  mosi;
    reg miso;
    wire cs_n;

    task reset();
        #0 rst = 1;
        #4 rst = 0;
    endtask

    Wishbone_bus bus(clk, rst);
    dummy_wb_master m (
        .bus(bus.M),
        .debug()
    );

    SPI spi_wires();
    assign spi_wires.S.miso = 1;

    SPI_WB spi (
        .bus    (bus.S),
        .spi(spi_wires.M),
        .debug()
    );

    initial forever #1 clk = ~clk;


    initial begin
        $dumpfile("build/spi.vcd");
        $dumpvars(0, spi_tb);

        reset();

        #3
        // bus.cyc = 1;
        // bus.stb = 1;
        // bus.adr = 32'hF0;
        // bus.we = 1;
        // bus.dat_miso = 32'hAA;
        miso = 1;

        #10000 $finish();
    end

endmodule