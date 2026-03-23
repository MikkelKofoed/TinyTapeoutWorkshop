module reaction_game (
    input  wire clk,
    input  wire rst_n,

    input  wire btn_yellow,   // start button
    input  wire btn_blue,     // reaction button

    output reg  led_green,
    output reg  led_red,
    output wire buzzer,

    output reg  [6:0] seg,    // a,b,c,d,e,f,g
    output reg  [1:0] dig     // digit select for 2-digit display
);

    // ============================================================
    // Adjust this if your clock is not 1 MHz
    // ============================================================
    localparam integer CLK_HZ        = 10_000;
    localparam integer TICK_10MS_MAX = CLK_HZ / 100;      // 0.01 s tick
    localparam integer DISP_DIV_MAX  = CLK_HZ / 1000;     // display refresh ~1 kHz

    // ============================================================
    // State definitions
    // ============================================================
    localparam [2:0]
        S_IDLE  = 3'd0,
        S_WAIT  = 3'd1,
        S_GO    = 3'd2,
        S_SHOW  = 3'd3,
        S_EARLY = 3'd4;

    reg [2:0] state;

    // ============================================================
    // Button synchronization and edge detection
    // ============================================================
    reg [1:0] y_sync, b_sync;
    reg y_prev, b_prev;

    wire y_now  = y_sync[1];
    wire b_now  = b_sync[1];
    wire y_rise = (y_now && !y_prev);
    wire b_rise = (b_now && !b_prev);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            y_sync <= 2'b00;
            b_sync <= 2'b00;
            y_prev <= 1'b0;
            b_prev <= 1'b0;
        end else begin
            y_sync <= {y_sync[0], btn_yellow};
            b_sync <= {b_sync[0], btn_blue};

            y_prev <= y_sync[1];
            b_prev <= b_sync[1];
        end
    end

    // ============================================================
    // Free running counter used for pseudo-random delay and buzzer tone
    // ============================================================
    reg [31:0] free_counter;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            free_counter <= 32'd0;
        else
            free_counter <= free_counter + 32'd1;
    end

    // ============================================================
    // 10 ms tick generator
    // ============================================================
    reg [31:0] tick_div;
    reg tick_10ms;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tick_div  <= 32'd0;
            tick_10ms <= 1'b0;
        end else begin
            if (tick_div == TICK_10MS_MAX - 1) begin
                tick_div  <= 32'd0;
                tick_10ms <= 1'b1;
            end else begin
                tick_div  <= tick_div + 32'd1;
                tick_10ms <= 1'b0;
            end
        end
    end

    // ============================================================
    // Delay and reaction time counters
    // wait_target_ticks: 200..500 => 2.00 s to 5.00 s
    // reaction_ticks: hundredths of a second (0..99)
    // ============================================================
    reg [8:0] wait_target_ticks;
    reg [8:0] wait_count_ticks;
    reg [6:0] reaction_ticks;
    reg [6:0] shown_ticks;

    // pseudo-random delay: 200 + (0..60)*5 = 200..500
    wire [5:0] rand6 = free_counter[7:2];
    wire [8:0] next_wait_target = 9'd200 + ({3'd0, rand6} * 9'd5);

    // ============================================================
    // Main state machine
    // ============================================================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state            <= S_IDLE;
            wait_target_ticks<= 9'd200;
            wait_count_ticks <= 9'd0;
            reaction_ticks   <= 7'd0;
            shown_ticks      <= 7'd0;
        end else begin
            case (state)
                S_IDLE: begin
                    wait_count_ticks <= 9'd0;
                    reaction_ticks   <= 7'd0;
                    shown_ticks      <= 7'd0;

                    if (y_rise) begin
                        wait_target_ticks <= next_wait_target;
                        state <= S_WAIT;
                    end
                end

                S_WAIT: begin
                    if (b_rise) begin
                        // Early press detected
                        shown_ticks <= 7'd0;
                        state <= S_EARLY;
                    end else if (tick_10ms) begin
                        if (wait_count_ticks >= wait_target_ticks) begin
                            reaction_ticks <= 7'd0;
                            state <= S_GO;
                        end else begin
                            wait_count_ticks <= wait_count_ticks + 9'd1;
                        end
                    end
                end

                S_GO: begin
                    if (b_rise) begin
                        // Stop timer and store result
                        shown_ticks <= reaction_ticks;
                        state <= S_SHOW;
                    end else if (tick_10ms) begin
                        if (reaction_ticks < 7'd99)
                            reaction_ticks <= reaction_ticks + 7'd1;
                    end
                end

                S_SHOW: begin
                    // Restart game with yellow button
                    if (y_rise) begin
                        wait_target_ticks <= next_wait_target;
                        wait_count_ticks  <= 9'd0;
                        reaction_ticks    <= 7'd0;
                        shown_ticks       <= 7'd0;
                        state <= S_WAIT;
                    end
                end

                S_EARLY: begin
                    // Restart game with yellow button
                    if (y_rise) begin
                        wait_target_ticks <= next_wait_target;
                        wait_count_ticks  <= 9'd0;
                        reaction_ticks    <= 7'd0;
                        shown_ticks       <= 7'd0;
                        state <= S_WAIT;
                    end
                end

                default: begin
                    state <= S_IDLE;
                end
            endcase
        end
    end

    // ============================================================
    // Outputs: LEDs and buzzer
    // ============================================================
    assign buzzer = (state == S_GO) ? free_counter[11] : 1'b0;

    always @(*) begin
        led_green = 1'b0;
        led_red   = 1'b0;

        case (state)
            S_GO:    led_green = 1'b1;
            S_EARLY: led_red   = 1'b1;
            default: begin end
        endcase
    end

    // ============================================================
    // Display value selection
    // ============================================================
    reg [3:0] tens;
    reg [3:0] ones;

    always @(*) begin
        case (state)
            S_IDLE: begin
                tens = 4'd0;
                ones = 4'd0;
            end

            S_WAIT: begin
                tens = 4'hF;   // blank
                ones = 4'hF;
            end

            S_GO: begin
                tens = reaction_ticks / 10;
                ones = reaction_ticks % 10;
            end

            S_SHOW: begin
                tens = shown_ticks / 10;
                ones = shown_ticks % 10;
            end

            S_EARLY: begin
                tens = 4'hE;   // display "EE"
                ones = 4'hE;
            end

            default: begin
                tens = 4'hF;
                ones = 4'hF;
            end
        endcase
    end

    // ============================================================
    // Display multiplexing
    // Assumes active LOW digit select and active HIGH segments
    // Adjust if your hardware differs
    // ============================================================
    reg [31:0] disp_div;
    reg disp_sel;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            disp_div <= 32'd0;
            disp_sel <= 1'b0;
        end else begin
            if (disp_div == DISP_DIV_MAX - 1) begin
                disp_div <= 32'd0;
                disp_sel <= ~disp_sel;
            end else begin
                disp_div <= disp_div + 32'd1;
            end
        end
    end

    // ============================================================
    // 7-segment encoding
    // ============================================================
    function [6:0] seg7_encode;
        input [3:0] val;
        begin
            case (val)
                4'd0: seg7_encode = 7'b1111110;
                4'd1: seg7_encode = 7'b0110000;
                4'd2: seg7_encode = 7'b1101101;
                4'd3: seg7_encode = 7'b1111001;
                4'd4: seg7_encode = 7'b0110011;
                4'd5: seg7_encode = 7'b1011011;
                4'd6: seg7_encode = 7'b1011111;
                4'd7: seg7_encode = 7'b1110000;
                4'd8: seg7_encode = 7'b1111111;
                4'd9: seg7_encode = 7'b1111011;
                4'hE: seg7_encode = 7'b1001111; // E
                4'hF: seg7_encode = 7'b0000000; // blank
                default: seg7_encode = 7'b0000001; // dash
            endcase
        end
    endfunction

    always @(*) begin
        if (disp_sel == 1'b0) begin
            seg = seg7_encode(ones);
            dig = 2'b10;
        end else begin
            seg = seg7_encode(tens);
            dig = 2'b01;
        end
    end

endmodule
