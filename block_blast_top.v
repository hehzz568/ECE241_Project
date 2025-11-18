// block_blast_top.v  — top
module block_blast_top (
    input  wire        CLOCK_50,

    // VGA (DE1-SoC: 8-bit/colour, HS/VS/BLANK_N/SYNC_N/CLK)
    output wire [7:0]  VGA_R,
    output wire [7:0]  VGA_G,
    output wire [7:0]  VGA_B,
    output wire        VGA_HS,
    output wire        VGA_VS,
    output wire        VGA_BLANK_N,
    output wire        VGA_SYNC_N,
    output wire        VGA_CLK,

    // PS/2
    inout  wire        PS2_CLK,
    inout  wire        PS2_DAT,

    input  wire [9:0]  SW,
    input  wire [3:0]  KEY,
    output wire [9:0]  LEDR,
    output wire [6:0]  HEX0, HEX1, HEX2, HEX3, HEX4, HEX5
);

    wire reset_n = KEY[0];
    wire reset   = ~reset_n;

    // Pixel clock
    wire clk_pix;
    clock_divider #(.DIVISOR(2)) u_pixclk (
        .clk_in (CLOCK_50),
        .reset  (reset),
        .clk_out(clk_pix)
    );
    assign VGA_CLK    = clk_pix;
    assign VGA_SYNC_N = 1'b0;

    // Game clock (~50 Hz if DIVISOR=1_000_000) 
    wire clk_game;
    clock_divider #(.DIVISOR(1_000_000)) u_gameclk (
        .clk_in (CLOCK_50),
        .reset  (reset),
        .clk_out(clk_game)
    );

    // PS/2 keyboard (50 MHz domain)
    wire [7:0] scan_code;
    wire       make_pulse;
    ps2_kbd_adapter u_kbd (
        .clk        (CLOCK_50),
        .reset      (reset),
        .PS2_CLK    (PS2_CLK),
        .PS2_DAT    (PS2_DAT),
        .key_code   (scan_code),
        .make_pulse (make_pulse)
    );

    // --- Event toggles in 50 MHz domain
    reg tgl_L, tgl_R, tgl_U, tgl_D, tgl_P, tgl_ROT, tgl_1, tgl_2, tgl_3;
    always @(posedge CLOCK_50 or posedge reset) begin
        if (reset) begin
            {tgl_L,tgl_R,tgl_U,tgl_D,tgl_P,tgl_ROT,tgl_1,tgl_2,tgl_3} <= 9'b0;
        end else if (make_pulse) begin
            case (scan_code)
                8'h6B, 8'h1C: tgl_L   <= ~tgl_L;    // Left  / 'A'
                8'h74, 8'h23: tgl_R   <= ~tgl_R;    // Right / 'D'
                8'h75, 8'h1D: tgl_U   <= ~tgl_U;    // Up    / 'W'
                8'h72, 8'h1B: tgl_D   <= ~tgl_D;    // Down  / 'S'
                8'h29:        tgl_P   <= ~tgl_P;    // Space (place)
                8'h2D:        tgl_ROT <= ~tgl_ROT;  // 'R'   (rotate)
                8'h16:        tgl_1   <= ~tgl_1;    // '1'
                8'h1E:        tgl_2   <= ~tgl_2;    // '2'
                8'h26:        tgl_3   <= ~tgl_3;    // '3'
                default: ; // ignore others
            endcase
        end
    end

    // --- Synchronize toggles into clk_game and edge-detect (one-tick pulses)
    reg [1:0] sL, sR, sU, sD, sP, sROT, s1_sync, s2_sync, s3_sync;
    always @(posedge clk_game or posedge reset) begin
        if (reset) begin
            sL<=0; sR<=0; sU<=0; sD<=0; sP<=0; sROT<=0; s1_sync<=0; s2_sync<=0; s3_sync<=0;
        end else begin
            sL      <= {sL[0],      tgl_L   };
            sR      <= {sR[0],      tgl_R   };
            sU      <= {sU[0],      tgl_U   };
            sD      <= {sD[0],      tgl_D   };
            sP      <= {sP[0],      tgl_P   };
            sROT    <= {sROT[0],    tgl_ROT };
            s1_sync <= {s1_sync[0], tgl_1   };
            s2_sync <= {s2_sync[0], tgl_2   };
            s3_sync <= {s3_sync[0], tgl_3   };
        end
    end

    wire move_l    = sL[1]      ^ sL[0];
    wire move_r    = sR[1]      ^ sR[0];
    wire move_u    = sU[1]      ^ sU[0];
    wire move_d    = sD[1]      ^ sD[0];
    wire place     = sP[1]      ^ sP[0];
    wire rotate    = sROT[1]    ^ sROT[0];
    wire sel1      = s1_sync[1] ^ s1_sync[0];
    wire sel2      = s2_sync[1] ^ s2_sync[0];
    wire sel3      = s3_sync[1] ^ s3_sync[0];

    // Game logic 
    wire [63:0] grid;
    wire [7:0]  score;
    wire        game_over;
    wire [63:0] blk1, blk2, blk3;
    wire [2:0]  blk1_x, blk1_y, blk2_x, blk2_y, blk3_x, blk3_y;

    game_logic u_game (
        .clk          (clk_game),
        .reset        (reset),
        .move_left    (move_l),
        .move_right   (move_r),
        .move_up      (move_u),
        .move_down    (move_d),
        .rotate_block (1'b0),
        .place_block  (place),
        .sel1         (sel1),
        .sel2         (sel2),
        .sel3         (sel3),
        .game_grid    (grid),
        .score        (score),
        .game_over    (game_over),
        .block1       (blk1), .block2(blk2), .block3(blk3),
        .block1_x     (blk1_x), .block1_y(blk1_y),
        .block2_x     (blk2_x), .block2_y(blk2_y),
        .block3_x     (blk3_x), .block3_y(blk3_y)
    );

    // VGA render
    vga_controller u_vga (
        .clk         (clk_pix),
        .reset       (reset),
        .game_grid   (grid),
        .block1      (blk1), .block2(blk2), .block3(blk3),
        .block1_x    (blk1_x), .block1_y(blk1_y),
        .block2_x    (blk2_x), .block2_y(blk2_y),
        .block3_x    (blk3_x), .block3_y(blk3_y),
        .score       (score),
        .game_over   (game_over),
        .vga_r       (VGA_R),
        .vga_g       (VGA_G),
        .vga_b       (VGA_B),
        .vga_hs      (VGA_HS),
        .vga_vs      (VGA_VS),
        .vga_blank_n (VGA_BLANK_N)
    );

    // LED/HEX
    assign LEDR[0]   = ~reset;        // reset_n indicator
    assign LEDR[1]   = game_over;     // game over
    assign LEDR[9:2] = {SW[7:0]};     // passthrough

    // score to HEX (rename to avoid clash with s1/s2 sync regs)
    wire [3:0] dig0 = score % 10;
    wire [3:0] dig1 = (score / 10)  % 10;
    wire [3:0] dig2 = (score / 100) % 10;
    hex7 u_hex0(.val(dig0), .seg(HEX0));
    hex7 u_hex1(.val(dig1), .seg(HEX1));
    hex7 u_hex2(.val(dig2), .seg(HEX2));
    assign HEX3 = 7'h7F;
    assign HEX4 = 7'h7F;
    assign HEX5 = 7'h7F;

endmodule


