// vga_timing_640x480.v
module vga_timing_640x480(
    input  wire clk, input wire reset,
    output reg  [9:0] x,
    output reg  [9:0] y,
    output wire       hs,     
    output wire       vs,     
    output wire       blank_n 
);
    // 640x480@60Hz
    localparam H_VISIBLE=640, H_FRONT=16, H_SYNC=96, H_BACK=48, H_TOTAL=800;
    localparam V_VISIBLE=480, V_FRONT=10, V_SYNC=2,  V_BACK=33, V_TOTAL=525;

    reg [9:0] hc, vc;
    always @(posedge clk or posedge reset) begin
        if (reset) begin hc<=0; vc<=0; x<=0; y<=0; end
        else begin
            if (hc==H_TOTAL-1) begin hc<=0; vc <= (vc==V_TOTAL-1)? 10'd0 : vc+10'd1; end
            else hc <= hc + 10'd1;

            
            if (hc < H_VISIBLE) x <= hc; else x <= 10'd0;
            if (vc < V_VISIBLE) y <= vc; else y <= 10'd0;
        end
    end
    assign hs = ~((hc >= H_VISIBLE+H_FRONT) && (hc < H_VISIBLE+H_FRONT+H_SYNC));
    assign vs = ~((vc >= V_VISIBLE+V_FRONT) && (vc < V_VISIBLE+V_FRONT+V_SYNC));
    assign blank_n = (hc < H_VISIBLE) && (vc < V_VISIBLE);
endmodule
