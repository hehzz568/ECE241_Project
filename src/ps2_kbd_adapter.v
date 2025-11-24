module ps2_kbd_adapter(
    input  wire clk,          // CLOCK_50 (50MHz)
    input  wire reset,        // active-high
    inout  wire PS2_CLK,
    inout  wire PS2_DAT,
    output reg  [7:0] key_code,
    output reg        make_pulse
);

    wire [7:0] rcv_data;
    wire       rcv_en;
    reg        send_cmd;
    reg  [7:0] cmd_byte;
    wire       cmd_sent, cmd_timeout;

    PS2_Controller U_PS2 (
        .CLOCK_50(clk),
        .reset(reset),
        .PS2_CLK(PS2_CLK),
        .PS2_DAT(PS2_DAT),
        .received_data(rcv_data),
        .received_data_en(rcv_en),
        .send_command(send_cmd),
        .the_command(cmd_byte),
        .command_was_sent(cmd_sent),
        .error_communication_timed_out(cmd_timeout)
    );


    localparam S_IDLE=0, S_PULSE=1, S_WAIT=2, S_DONE=3;
    reg [1:0] ist;
    always @(posedge clk) begin
        if (reset) begin
            ist <= S_IDLE;
            send_cmd <= 1'b0;
            cmd_byte <= 8'hF4;
        end else case (ist)
            S_IDLE:  begin send_cmd<=1'b1; ist<=S_PULSE; end
            S_PULSE: begin send_cmd<=1'b0; ist<=S_WAIT;  end
            S_WAIT:  if (cmd_sent || cmd_timeout) ist<=S_DONE;
            default: ;
        endcase
    end


    reg break_f, ext_f;
    always @(posedge clk) begin
        if (reset) begin
            key_code <= 8'h00;
            make_pulse <= 1'b0;
            break_f <= 1'b0; ext_f <= 1'b0;
        end else begin
            make_pulse <= 1'b0;
            if (rcv_en) begin
                if (rcv_data==8'hE0) ext_f<=1'b1;
                else if (rcv_data==8'hF0) break_f<=1'b1;
                else begin
                    if (!break_f) begin
                        key_code <= rcv_data;  
                        make_pulse <= 1'b1;     // 1 clk 
                    end
                    break_f <= 1'b0; ext_f <= 1'b0;
                end
            end
        end
    end
endmodule
