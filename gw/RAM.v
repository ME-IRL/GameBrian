module RAM (
    input wire clk,
    input wire rst,
    input wire [15:0] addr,
    input wire [7:0] mosi,
    output wire [7:0] miso,
    input wire write
);
    reg [7:0] ram [0:15];
    assign miso = ram[addr[3:0]];

    integer i;
    initial begin
        for(i=0; i<16; i=i+1) begin
            ram[i] = 8'h0;
        end
    end

    always @(posedge write or posedge rst) begin
        if(rst) begin
            for(i=0; i<16; i=i+1) begin
                ram[i] = 8'h0;
            end
        end else begin
            ram[addr[3:0]] <= mosi;
        end
    end
endmodule