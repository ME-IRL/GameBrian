module ClkDiv #(
    parameter IN_FREQ,
    parameter OUT_FREQ,
    parameter SYNC_NEG = 1
) (
    input  wire clk,
    input  wire rst,
    output reg  clk_out
);
    integer toggle_val = (IN_FREQ/(2*OUT_FREQ))-1;
    reg [$clog2(IN_FREQ/OUT_FREQ):0] counter;

    initial begin
        counter <= 0;
        clk_out <= 1;
    end

    wire corrected_clk = clk ^ SYNC_NEG;

    always @(negedge corrected_clk or posedge rst) begin
        if(rst) begin
            counter <= 0;
        end else begin
            if(counter == toggle_val) begin
                counter <= 0;
                clk_out <= !clk_out;
            end else
                counter <= counter + 1;
        end
    end
endmodule


module Blinky #(
    parameter CLK_FREQ = 200_000_000,
    parameter LED_FREQ = 1
) (
    input wire clk,
    input wire rst,
    output reg [7:0] leds
);

    wire led_clk;
    ClkDiv #(
        .IN_FREQ (CLK_FREQ),
        .OUT_FREQ(LED_FREQ*2),
    ) ledclk (
        .clk(clk),
        .rst(rst),
        .clk_out(led_clk)
    );

    initial leds <= 8'h0;
    always @(posedge led_clk or posedge rst) begin
        if(rst)
            leds <= 0;
        else
            leds <= leds + 1;
    end

endmodule