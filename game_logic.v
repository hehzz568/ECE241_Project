// game_logic.v
module game_logic(
    input  wire clk, input wire reset,
    input  wire move_left, move_right, move_up, move_down,
    input  wire rotate_block, place_block,
    input  wire sel1, sel2, sel3,
    output reg  [63:0] game_grid,
    output reg  [7:0]  score,
    output reg         game_over,
    output reg  [63:0] block1, block2, block3,
    output reg  [2:0]  block1_x, block1_y,
    output reg  [2:0]  block2_x, block2_y,
    output reg  [2:0]  block3_x, block3_y
);
    wire gen_new = (block1==64'b0 && block2==64'b0 && block3==64'b0);
    wire [63:0] nb1, nb2, nb3;
    block_generator U(
        .clk(clk), .reset(reset), .generate_new(gen_new),
        .block1(nb1), .block2(nb2), .block3(nb3)
    );

    reg [1:0] sel; // 1..3
    always @(posedge clk or posedge reset) begin
        if (reset) sel<=1;
        else if (sel1) sel<=1;
        else if (sel2) sel<=2;
        else if (sel3) sel<=3;
    end

    function automatic [63:0] rotate90(input [63:0] b);
    integer r, c;
    reg [63:0] out;
    reg [6:0] idx_old, idx_new;
		begin
        out = 64'b0;

        // Rotate within the top-left 4×4 area of the 8×8 block
			for (r = 0; r < 4; r = r + 1) begin
					for (c = 0; c < 4; c = c + 1) begin
						idx_old = r*8 + c;
						if (b[idx_old]) begin
                    // 4×4 rotation: (r, c) -> (c, 3 - r)
                    idx_new = (c)*8 + (3 - r);
                    out[idx_new] = 1'b1;
						end
					end
			end

			rotate90 = out;
		end
		endfunction


    function automatic can_place(
        input [63:0] b, input [2:0] x, input [2:0] y, input [63:0] grid
    );
        integer r,c; reg ok; reg [6:0] idx;
        begin
            ok=1;
            for (r=0;r<8;r=r+1)
                for (c=0;c<8;c=c+1)
                    if (b[r*8+c]) begin
                        if (x+c>=8 || y+r>=8) ok=0;
                        else begin idx=(y+r)*8+(x+c); if (grid[idx]) ok=0; end
                    end
            can_place=ok;
        end
    endfunction

    function automatic [63:0] paint(
        input [63:0] b, input [2:0] x, input [2:0] y, input [63:0] grid
    );
        integer r,c; reg [63:0] g; reg [6:0] idx;
        begin
            g = grid;
            for (r=0;r<8;r=r+1)
                for (c=0;c<8;c=c+1)
                    if (b[r*8+c]) begin
                        idx=(y+r)*8+(x+c); g[idx]=1'b1;
                    end
            paint = g;
        end
    endfunction

    task automatic clear_lines(
        input  [63:0] grid_in,
        output [63:0] grid_out,
        output [7:0]  add
    );
        integer r,c; reg full; reg [63:0] g;
        begin
            g = grid_in; add = 8'd0;

            // rows
            for (r=0;r<8;r=r+1) begin
                full=1;
                for (c=0;c<8;c=c+1) if (!g[r*8+c]) full=0;
                if (full) begin
                    add = add + 8'd1;
                    for (c=0;c<8;c=c+1) g[r*8+c] = 1'b0;
                end
            end

            // columns
            for (c=0;c<8;c=c+1) begin
                full=1;
                for (r=0;r<8;r=r+1) if (!g[r*8+c]) full=0;
                if (full) begin
                    add = add + 8'd1;
                    for (r=0;r<8;r=r+1) g[r*8+c] = 1'b0;
                end
            end

            grid_out = g;
        end
    endtask


    reg [63:0] tmp_grid;
    reg [63:0] cleared_grid;
    reg [7:0]  gain;

    always @(posedge clk or posedge reset) begin
    if (reset) begin
        game_grid <= 64'b0;
        score     <= 8'b0;
        game_over <= 1'b0;

        // start with no blocks, generator + gen_new will fill them
        block1    <= 64'b0;
        block2    <= 64'b0;
        block3    <= 64'b0;

        block1_x  <= 3'd0; block1_y <= 3'd0;
        block2_x  <= 3'd3; block2_y <= 3'd0;
        block3_x  <= 3'd0; block3_y <= 3'd3;
    end else begin

                if (sel==1) begin
            // use can_place with empty grid so movement respects block size
            if (move_left  && block1_x > 0 &&
                can_place(block1, block1_x-3'd1, block1_y, 64'b0))
                block1_x <= block1_x-3'd1;

            if (move_right && block1_x < 7 &&
                can_place(block1, block1_x+3'd1, block1_y, 64'b0))
                block1_x <= block1_x+3'd1;

            if (move_up    && block1_y > 0 &&
                can_place(block1, block1_x, block1_y-3'd1, 64'b0))
                block1_y <= block1_y-3'd1;

            if (move_down  && block1_y < 7 &&
                can_place(block1, block1_x, block1_y+3'd1, 64'b0))
                block1_y <= block1_y+3'd1;

            // if (rotate_block && can_place(rotate90(block1), block1_x, block1_y, 64'b0)) block1 <= rotate90(block1);

            if (place_block && can_place(block1,block1_x,block1_y,game_grid)) begin
                tmp_grid   = paint(block1,block1_x,block1_y,game_grid);
                clear_lines(tmp_grid, cleared_grid, gain);
                game_grid <= cleared_grid;  
                score     <= score + gain;
                block1    <= 64'b0;
            end

        end else if (sel==2) begin
            if (move_left  && block2_x > 0 &&
                can_place(block2, block2_x-3'd1, block2_y, 64'b0))
                block2_x <= block2_x-3'd1;

            if (move_right && block2_x < 7 &&
                can_place(block2, block2_x+3'd1, block2_y, 64'b0))
                block2_x <= block2_x+3'd1;

            if (move_up    && block2_y > 0 &&
                can_place(block2, block2_x, block2_y-3'd1, 64'b0))
                block2_y <= block2_y-3'd1;

            if (move_down  && block2_y < 7 &&
                can_place(block2, block2_x, block2_y+3'd1, 64'b0))
                block2_y <= block2_y+3'd1;

            // if (rotate_block && can_place(rotate90(block2), block2_x, block2_y, 64'b0)) block2 <= rotate90(block2);

            if (place_block && can_place(block2,block2_x,block2_y,game_grid)) begin
                tmp_grid   = paint(block2,block2_x,block2_y,game_grid);
                clear_lines(tmp_grid, cleared_grid, gain);
                game_grid <= cleared_grid;
                score     <= score + gain;
                block2    <= 64'b0;
            end

        end else begin // sel==3
            if (move_left  && block3_x > 0 &&
                can_place(block3, block3_x-3'd1, block3_y, 64'b0))
                block3_x <= block3_x-3'd1;

            if (move_right && block3_x < 7 &&
                can_place(block3, block3_x+3'd1, block3_y, 64'b0))
                block3_x <= block3_x+3'd1;

            if (move_up    && block3_y > 0 &&
                can_place(block3, block3_x, block3_y-3'd1, 64'b0))
                block3_y <= block3_y-3'd1;

            if (move_down  && block3_y < 7 &&
                can_place(block3, block3_x, block3_y+3'd1, 64'b0))
                block3_y <= block3_y+3'd1;

            // if (rotate_block && can_place(rotate90(block3), block3_x, block3_y, 64'b0)) block3 <= rotate90(block3);

            if (place_block && can_place(block3,block3_x,block3_y,game_grid)) begin
                tmp_grid   = paint(block3,block3_x,block3_y,game_grid);
                clear_lines(tmp_grid, cleared_grid, gain);
                game_grid <= cleared_grid;
                score     <= score + gain;
                block3    <= 64'b0;
            end
        end


        if (gen_new) begin
            block1   <= nb1; 
            block2   <= nb2; 
            block3   <= nb3;
            block1_x <= 3'd0; block1_y <= 3'd0;
            block2_x <= 3'd3; block2_y <= 3'd0;
            block3_x <= 3'd0; block3_y <= 3'd3;

            if (!can_place(nb1,0,0,game_grid) &&
                !can_place(nb2,3,0,game_grid) &&
                !can_place(nb3,0,3,game_grid))
                game_over <= 1'b1;
				end
			end
		end

endmodule
