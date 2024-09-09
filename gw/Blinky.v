module Blinky #(
    parameter CLK_FREQ = 200_000_000,
    parameter LED_FREQ = 1
) (
    input wire clk,
    input wire rst,
    output reg [7:0] leds
);

    integer toggle_val = (CLK_FREQ/LED_FREQ)-1;
    reg [$clog2(CLK_FREQ/LED_FREQ):0] counter;

    initial begin
        counter <= 0;
        leds <= 0;
    end

    always @(posedge clk or posedge rst) begin
        if(rst) begin
            counter <= 0;
            leds <= 0;
        end else begin
            if(counter == toggle_val) begin
                counter <= 0;
                leds <= leds + 1;
            end else begin
                counter <= counter + 1;
            end
        end
    end
endmodule