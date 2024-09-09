module SPI #(
    parameter CLK_FREQ = 200_000_000,
    parameter SPI_FREQ = 200_000
) (
    input wire clk,
    input wire rst,
    input wire [15:0] addr,
    input wire [7:0] mosi,
    output wire [7:0] miso,
    input wire write,

    output wire sd_cs,
    output wire sd_sck,
    output wire sd_mosi,
    input wire sd_miso,
    input wire sd_det,

    output wire [7:0] debug
);
    // DATA and CONTROL registers
    reg [7:0] spi_data;
    reg [7:0] spi_ctrl;

    initial begin
        spi_data <= 8'h0;
        spi_ctrl <= 8'h2;
    end

    // Read
    assign miso = addr[0] ? {!sd_det, spi_ctrl[6:0]} : spi_data;

    // Clock division (Get 200kHz)
    reg clk200;
    integer toggle_val = (CLK_FREQ/SPI_FREQ/2)-1;
    reg [$clog2(CLK_FREQ/SPI_FREQ/2):0] counter;
    initial begin
        counter <= 0;
        clk200 <= 0;
    end

    always @(posedge clk or posedge rst) begin
        if(rst) begin
            counter <= 0;
            clk200 <= 0;
        end else begin
            if(counter == toggle_val) begin
                counter <= 0;
                clk200 <= !clk200;
            end else begin
                counter <= counter+1;
            end
        end
    end

    // Busy / idle status
    wire busy = spi_ctrl[0];
    reg sBusy;
    initial sBusy <= 0;

    assign sd_cs = spi_ctrl[1];
    assign sd_sck = sBusy ? clk200 : 0;
    assign sd_mosi = sBusy ? spi_data[7] : 1;

    // Edge detection
    wire neg = (counter == 0) && !clk200;
    wire pos = (counter == 0) && clk200;

    reg prev_write;
    always @(posedge clk) begin
        prev_write <= write;
    end
    wire wr_pos = !prev_write && write;

    // Shift
    reg [2:0] send_counter;
    reg in_buf;

    always @(posedge clk or posedge rst) begin
        if(rst) begin
            spi_data <= 8'h0;
            spi_ctrl <= 8'h2;
            send_counter <= 3'b000;
            in_buf <= 0;
            sBusy <= 0;
        end else if(write) begin
            if(addr[0])
                spi_ctrl <= mosi;
            else
                spi_data <= mosi;
        end else if(neg) begin
            sBusy <= busy;
            if(sBusy) begin
                spi_data <= {spi_data[6:0], in_buf};
                send_counter <= send_counter + 1;
                if(send_counter == 3'b111) begin
                    spi_ctrl <= {spi_ctrl[7:1], 1'b0};
                    sBusy <= 0;
                end
            end
        end else if(pos && sBusy) begin
            in_buf <= sd_miso;
        end
    end

    // assign debug = {clk200, write, busy, sBusy, sd_cs, sd_sck, sd_mosi, sd_miso};

endmodule