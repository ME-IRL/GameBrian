interface UART;
    logic rx;
    logic tx;

    modport M (
        output tx,
        input  rx
    );

    modport S (
        output rx,
        input  tx
    );
endinterface

module FIFO #(
    parameter WIDTH  = 8,
    parameter SIZE_W = 3
) (
    input              clk,
    input              rst,

    input  logic [WIDTH-1:0] data_in,
    output logic [WIDTH-1:0] data_out,
    input  logic             read,
    input  logic             write,
    output logic             full,
    output logic             empty
);

    reg [WIDTH-1:0]        data [2**SIZE_W] = '{default: '0};
    reg [SIZE_W:0] r = 0;
    reg [SIZE_W:0] w = 0;

    // Empty if all same
    assign empty = (w == r);

    // Full if only top bit differs
    localparam [SIZE_W:0] x = {1'b1, SIZE_W'(0)};
    assign full = ((w ^ x) == r);

    always @(posedge clk, posedge rst) begin
        if(rst) begin
            r <= 0;
            w <= 0;
        end else begin
            if(write && !full) begin
                data[SIZE_W'(w)] <= data_in;
                w <= w + 1;
            end

            if(read && !empty) begin
                r <= r + 1;
                data_out <= data[SIZE_W'(r)];
            // end else if(read && write) begin
            //     data[w] <= data_in;
            //     w <= w + 1;
            //     r <= r + 1;
            end
        end
    end

endmodule

module UART_WB #(
    parameter CLK_FREQ  = 200_000_000,
    parameter UART_BAUD = 115200
) (
    Wishbone_bus.S bus,
    UART.M uart,
    output [7:0] debug
);

    wire bus_request = (bus.stb) && (!bus.stall);

    // FIFOs
    wire [7:0] txdata;
    logic txf_read, txf_write, txf_full, txf_empty;
    FIFO txfifo (
        .clk(bus.clk),
        .rst(bus.rst),

        .data_in  (bus.dat_mosi[7:0]),
        .data_out (txdata),
        .read     (txf_read),
        .write    (txf_write),
        .full     (txf_full),
        .empty    (txf_empty)
    );

    logic rxf_read, rxf_write, rxf_full, rxf_empty;
    wire [7:0] rxdata;
    FIFO rxfifo (
        .clk(bus.clk),
        .rst(bus.rst),

        .data_in  (),
        .data_out (rxdata),
        .read     (rxf_read),
        .write    (rxf_write),
        .full     (rxf_full),
        .empty    (rxf_empty)
    );

    // Bus control -- read/write to fifo
    always @(posedge bus.clk or posedge bus.rst) begin
        if(bus.rst) begin
        end else begin
            if(bus_request) begin
                // Addr 0: Data write/read for tx/rx
                if(bus.adr == 0) begin
                    if(bus.we) begin
                        txf_write = 1; // The fifo shouldnt do anything if full anyways
                        if(txf_full) begin
                            bus.rty = 1;
                            bus.ack = 0;
                            bus.dat_miso = 0;
                        end else begin
                            bus.rty = 0;
                            bus.ack = 1;
                            bus.dat_miso = 0;
                        end
                    end else begin
                        rxf_read = 1; // The fifo shouldnt do anything if empty anyways
                        if(rxf_empty) begin
                            bus.rty = 1;
                            bus.ack = 0;
                            bus.dat_miso = 0;
                        end else begin
                            bus.rty = 0;
                            bus.ack = 1;
                            bus.dat_miso = {24'h0, rxdata};
                        end
                    end
                
                // Addr 1: Read for FIFO status
                end else if(bus.adr == 1) begin
                    txf_write = 0;
                    rxf_read = 0;
                    if(bus.we) begin
                        bus.ack = 1;
                        bus.rty = 0;
                        bus.dat_miso = 0;
                    end else begin
                        bus.ack = 1;
                        bus.rty = 0;
                        bus.dat_miso = 32'({rxf_empty, rxf_full, txf_empty, txf_full});
                    end

                // Addr x: Nothing. Return 0
                end else begin
                    bus.ack = 1;
                    bus.rty = 0;
                    bus.dat_miso = 0;
                end
            end else begin
                bus.dat_miso = 0;
                txf_write = 0;
                rxf_read = 0;
                bus.rty = 0;
                bus.ack = 0;
            end
        end
    end

    // Generate UART clock
    reg clk_en = 0;
    reg uart_clk = 0;

    localparam int clkdiv_width = $clog2(CLK_FREQ/UART_BAUD)+1;
    localparam int toggle_val = (CLK_FREQ/(2*UART_BAUD))-1;
    reg [clkdiv_width-1:0] clk_counter;

    wire toggle = (clk_counter == clkdiv_width'(toggle_val));

    always @(posedge bus.clk or posedge bus.rst) begin
        if (bus.rst) begin
            clk_counter <= 0;
            uart_clk <= 0;
        end else begin
            if(clk_en) begin
                if(toggle) begin
                    uart_clk <= ~uart_clk;
                    clk_counter <= 0;
                end else begin
                    clk_counter <= clk_counter + 1;
                end
            end
        end
    end

    wire clkp = (toggle && !uart_clk);
    wire clkn = (toggle && uart_clk);

    // TX
    reg tx_busy = 0;
    reg [3:0] tx_count = 0;
    reg [10:0] tx_shift = 0;
    always @(posedge bus.clk or posedge bus.rst) begin
        if(bus.rst) begin
        end else begin
            if(!txf_empty && !tx_busy) begin
                txf_read <= 1;
            end

            if(txf_read) begin
                txf_read <= 0;
                tx_busy <= 1;
            end

            if(tx_busy && !clk_en) begin
                clk_en <= 1;
                tx_count <= 10;
                tx_shift <= {2'b10, txdata, 1'b1};
            end

            if(clkp) begin
                tx_shift <= {tx_shift[9:0], 1'b1};
                if(tx_count == 0) begin
                    tx_busy <= 0;
                    clk_en <= 0;
                end else if(tx_count > 0) begin
                    tx_count <= tx_count - 1;
                end
            end
        end
    end

    // assign uart.tx = !clk_en || tx_shift[10];
    assign uart.tx = bus_request;

    // // ACK Delay
    // reg [5:0] ack_delay = 6'h0;
    // always @(posedge bus.clk or posedge bus.rst) begin
    //     if(bus.rst) begin
    //         ack_delay <= 6'h0;
    //     end else begin
    //         if(bus_request)
    //             ack_delay <= 6'd40;
    //         else if((ack_delay > 0) && clkp)
    //             ack_delay <= ack_delay - 1;
    //     end
    // end

    assign debug = 8'({ clkp, clkn, clk_en, txf_read, tx_busy, uart.tx });

endmodule

module fifo_tb;

    bit clk = 1;
    bit rst = 0;

    initial forever #1 clk = ~clk;

    task reset();
        #0 rst = 1;
        #4 rst = 0;
    endtask

    reg [7:0] data = 0;
    reg read, write;

    FIFO #(
    ) fifo (
        .clk      (clk),
        .rst      (rst),

        .data_in  (data),
        .data_out (),
        .read     (read),
        .write    (write),
        .full     (),
        .empty    ()
    );

    task r();
        #2
        read  = 1;
        write = 0;
        #2
        read  = 0;
        write = 0;
    endtask

    task w();
        #2
        read  = 0;
        write = 1;
        #2
        read  = 0;
        write = 0;
        data  = data + 1;
    endtask

    initial begin
        $dumpfile("build/fifo.vcd");
        $dumpvars(0, uart_tb);

        reset();

        data = 8'hAA;
        w();
        w();
        w();
        w();
        w();
        w();
        w();
        w();
        w();
        w();
        w();
        r();
        r();
        r();
        w();
        w();
        w();
        w();
        r();
        r();
        r();
        r();
        r();
        r();
        r();
        r();
        r();
        r();
        r();

        #10 $finish();
    end

endmodule

module dummy_wb_master_uart #(
) (
    Wishbone_bus.M bus,
    output [7:0] debug
);

    reg [3:0] counter = 0;

    assign bus.adr = 32'h0;
    assign bus.dat_mosi = 32'h30 + 32'(counter);
    assign bus.we = 1;
    
    wire idle = (!bus.stall) && (!bus.cyc) && (!bus.ack) && (!bus.rty);

    reg[25:0] div = 0;

    always @(posedge bus.clk or posedge bus.rst) begin
        if(bus.rst) begin
            bus.cyc <= 0;
            bus.stb <= 0;

            counter <= 0;
        end else begin
            if(idle) begin
                div <= div + 1;
                if(div == 0) begin
                    bus.cyc <= 1;
                    bus.stb <= 1;
                end
            end else if(bus.ack || bus.rty) begin
                bus.cyc <= 0;
                counter <= counter + 1;
            end else if(bus.stb) begin
                bus.stb <= 0;
            end
        end
    end

    // assign debug = counter[7:0];
    // assign debug = {bus.cyc, bus.stall, bus.ack, bus.adr[4:0]};
    // assign debug = {bus.cyc, bus.dat_miso[6:0]};

endmodule

module uart_tb;

    bit clk = 1;
    bit rst = 0;

    initial forever #1 clk = ~clk;

    task reset();
        #0 rst = 1;
        #4 rst = 0;
    endtask

    Wishbone_bus bus(clk, rst);
    UART uart_wires();

    dummy_wb_master_uart master (
        .bus(bus.M),
        .debug()
    );

    UART_WB #(
        .CLK_FREQ(1_000_000)
    ) uart (
        .bus(bus.S),
        .uart(uart_wires.M),
        .debug()
    );

    task write(
        int addr = 0,
        int val  = 0
    );
        $display("WR: %4x = %4x", addr, val);
        #2
        bus.cyc = 1;
        bus.stb = 1;
        bus.we = 1;
        bus.adr = addr;
        bus.dat_mosi = val;
        #2
        bus.stb = 0;
        bus.we = 0;
        bus.adr = 0;
        bus.dat_mosi = 0;
    endtask

    task read(
        int addr = 0
    );
        #2
        bus.cyc = 1;
        bus.stb = 1;
        bus.we = 0;
        bus.adr = addr;
        #2
        bus.stb = 0;
        bus.we = 0;
        bus.adr = 0;
        $display("RD: %4x == %4x", addr, bus.dat_miso[7:0]);
    endtask

    initial begin
        $dumpfile("build/uart.vcd");
        $dumpvars(0, uart_tb);

        reset();

        // read(1);
        // write(0, 32'hAA);
        // read(1);
        // write(0, 32'h55);
        // read(1);
        // write(0, 32'hAA);
        // write(0, 32'h55);
        // write(0, 32'hAA);
        // write(0, 32'h55);
        // write(0, 32'hAA);
        // write(0, 32'h55);
        // write(0, 32'hAA);
        // write(0, 32'h55);
        // write(0, 32'hAA);
        // write(0, 32'h55);
        // read(1);
        // read(0);
        // read(0);
        // read(0);



        #10000 $finish();
    end

endmodule