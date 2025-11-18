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
        input [4:0] sel;
        begin
            case (sel)
                5'd0:  shape = 64'h0000000000000301; // small L
                5'd1:  shape = 64'h0000000000000103;
                5'd2:  shape = 64'h0000000000000302;
                5'd3:  shape = 64'h0000000000000203;
                5'd4:  shape = 64'h0000000000030101; // big L
                5'd5:  shape = 64'h0000000000000107;
                5'd6:  shape = 64'h0000000000020203;
                5'd7:  shape = 64'h0000000000000704;
                5'd8:  shape = 64'h0000000000000303; // 2x2
                5'd9:  shape = 64'h0000000000070707; // 3x3
                5'd10: shape = 64'h0000000000000007; // 1x3
                5'd11: shape = 64'h0000000000010101; // 3x1
                5'd12: shape = 64'h000000000000000F; // 1x4
                5'd13: shape = 64'h0000000001010101; // 4x1
                5'd14: shape = 64'h0000000000000707; // 2x3
                5'd15: shape = 64'h0000000000030303; // 3x22
                5'd16: shape = 64'h000000000000001F; // 1x5
                5'd17: shape = 64'h0000000101010101; // 5x1
                5'd18: shape = 64'h0000000000000207; // T
                5'd19: shape = 64'h0000000000000702; // T
                5'd20: shape = 64'h0000000000000701; // flat L 
                5'd21: shape = 64'h0000000000010103; // flat L 
                5'd22: shape = 64'h0000000000000407; // flat L 
                5'd23: shape = 64'h0000000000030202; // flat L 
                5'd24: shape = 64'h0000000000000603; // Z
                5'd25: shape = 64'h0000000000010302; // Z
                5'd26: shape = 64'h0000000000000603; // Z
                5'd27: shape = 64'h0000000000010302; // Z
                5'd28: shape = 64'h0000000000000306; // S
                5'd29: shape = 64'h0000000000020301; // S
                5'd30: shape = 64'h0000000000000306; // S
                5'd31: shape = 64'h0000000000020301; // S

                default: shape = 64'h0000000000000001; // 1x1 fallback (should rarely happen)
            endcase
        end
    endfunction



    always @(posedge clk or posedge reset) begin
        if (reset) begin
            block1 <= 64'b0;
            block2 <= 64'b0;
            block3 <= 64'b0;
        end else if (generate_new) begin

            block1 <= shape(lfsr[4:0]);
            block2 <= shape(lfsr[9:5]);
            block3 <= shape(lfsr[14:10]);
        end
    end


endmodule
