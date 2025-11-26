// Clock Divider
module clock_divider #(
    parameter DIVISOR = 2
) (
    input  wire clk_in,
    input  wire reset,
    output reg clk_out
);

    localparam COUNTER_WIDTH = $clog2(DIVISOR);
    reg [COUNTER_WIDTH-1:0] counter;
    
    always @(posedge clk_in or posedge reset) begin
        if (reset) begin
            counter <= 0;
            clk_out <= 0;
        end else begin
            if (counter >= (DIVISOR/2 - 1)) begin
                clk_out <= ~clk_out;
                counter <= 0;
            end else begin
                counter <= counter + 1;
            end
        end
    end

endmodule

