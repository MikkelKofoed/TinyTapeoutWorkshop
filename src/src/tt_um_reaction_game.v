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
    // Input mapping
    // ui_in[0] = yellow button (start)
    // ui_in[1] = blue button (reaction)
    // Remaining inputs are currently unused
    // ============================================================
    wire btn_yellow = ui_in[0];
    wire btn_blue   = ui_in[1];

    // ============================================================
    // Internal signals from the reaction game core
    // ============================================================
    wire led_green;
    wire led_red;
    wire buzzer;
    wire [6:0] seg;
    wire [1:0] dig;

    // ============================================================
    // Instantiate the core game logic
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
    // uo_out:
    //   [0] = green LED
    //   [1] = red LED
    //   [2] = buzzer
    //   [7:3] = unused for now
    //
    // uio:
    //   currently unused in this simple wrapper
    // ============================================================
    assign uo_out[0] = led_green;
    assign uo_out[1] = led_red;
    assign uo_out[2] = buzzer;
    assign uo_out[7:3] = 5'b00000;

    // No bidirectional IO used yet
    assign uio_out = 8'b00000000;
    assign uio_oe  = 8'b00000000;

endmodule
