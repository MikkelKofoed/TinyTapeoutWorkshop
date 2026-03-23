module tt_um_reaction_game (
    input  wire [7:0] ui_in,
    output wire [7:0] uo_out,
    input  wire [7:0] uio_in,
    output wire [7:0] uio_out,
    output wire [7:0] uio_oe,
    input  wire clk,
    input  wire rst_n
);

    // ============================================================
    // Simon-style input mapping used by the Wokwi test setup
    //
    // ui_in[2] = blue button   (reaction)
    // ui_in[3] = yellow button (start)
    // ============================================================
    wire btn_blue   = ui_in[2];
    wire btn_yellow = ui_in[3];

    // ============================================================
    // Internal signals from the reaction game core
    // ============================================================
    wire led_green;
    wire led_red;
    wire buzzer;
    wire [6:0] seg;
    wire [1:0] dig;

    // ============================================================
    // Instantiate the game core
    // ============================================================
    reaction_game game (
        .clk(clk),
        .rst_n(rst_n),
        .btn_yellow(btn_yellow),
        .btn_blue(btn_blue),
        .led_green(led_green),
        .led_red(led_red),
        .buzzer(buzzer),
        .seg(seg),
        .dig(dig)
    );

    // ============================================================
    // Output mapping
    //
    // uo_out[0] = red LED
    // uo_out[1] = green LED
    // uo_out[2] = unused
    // uo_out[3] = unused
    // uo_out[4] = buzzer
    // uo_out[5] = digit 1 enable
    // uo_out[6] = digit 2 enable
    // uo_out[7] = unused
    // ============================================================
    assign uo_out[0] = led_red;
    assign uo_out[1] = led_green;
    assign uo_out[2] = 1'b0;
    assign uo_out[3] = 1'b0;
    assign uo_out[4] = buzzer;
    assign uo_out[5] = dig[1];
    assign uo_out[6] = dig[0];
    assign uo_out[7] = 1'b0;

    // ============================================================
    // Bidirectional output mapping for 7-segment display
    //
    // uio_out[0] = segment A
    // uio_out[1] = segment B
    // uio_out[2] = segment C
    // uio_out[3] = segment D
    // uio_out[4] = segment E
    // uio_out[5] = segment F
    // uio_out[6] = segment G
    // uio_out[7] = unused
    // ============================================================
    assign uio_out[0] = seg[6];
    assign uio_out[1] = seg[5];
    assign uio_out[2] = seg[4];
    assign uio_out[3] = seg[3];
    assign uio_out[4] = seg[2];
    assign uio_out[5] = seg[1];
    assign uio_out[6] = seg[0];
    assign uio_out[7] = 1'b0;

    // Drive the segment outputs, leave uio[7] unused
    assign uio_oe[0] = 1'b1;
    assign uio_oe[1] = 1'b1;
    assign uio_oe[2] = 1'b1;
    assign uio_oe[3] = 1'b1;
    assign uio_oe[4] = 1'b1;
    assign uio_oe[5] = 1'b1;
    assign uio_oe[6] = 1'b1;
    assign uio_oe[7] = 1'b0;

endmodule
