// block_generator.v — generate 3 pseudo-random blocks
module block_generator(
    input  wire clk,
    input  wire reset,          // only clears current blocks
    input  wire generate_new,   // pulse when you want new blocks
    output reg [63:0] block1,
    output reg [63:0] block2,
    output reg [63:0] block3
);
    reg [15:0] lfsr = 16'hACE1;

    always @(posedge clk) begin
        lfsr <= { lfsr[14:0],
                  lfsr[15] ^ lfsr[13] ^ lfsr[12] ^ lfsr[10] };
    end

    function [63:0] shape;
    input [2:0] sel;
			begin
				case (sel)
          3'd0: shape = 64'h0000000000000F00; // 1×4 horizontal
          3'd1: shape = 64'h0000000000000606; // 2×2 square
          3'd2: shape = 64'h0000000002020202; // 4×1 vertical
          3'd3: shape = 64'h0000000000070101; // big L
          3'd4: shape = 64'h0000000000020207; // T
          3'd5: shape = 64'h0000000000000700; // 1×3 horizontal
          3'd6: shape = 64'h0000000000020202; // 3×1 vertical
          3'd7: shape = 64'h0000000000000301; // small L
          default: shape = 64'h0;
				endcase
			end
		endfunction



    // Hold / clear the current triple, update only on generate_new
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            block1 <= 64'b0;
            block2 <= 64'b0;
            block3 <= 64'b0;
        end else if (generate_new) begin
            block1 <= shape(lfsr[2:0]);
            block2 <= shape(lfsr[5:3]);
            block3 <= shape(lfsr[8:6]);
        end
    end

endmodule
