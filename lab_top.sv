`include "config.svh"

module lab_top
# (
    parameter  clk_mhz       = 50,
               w_key         = 4,
               w_sw          = 8,
               w_led         = 8,
               w_digit       = 8,
               w_gpio        = 100,

               screen_width  = 480,
               screen_height = 272,

               w_red         = 5,
               w_green       = 5,
               w_blue        = 5,

               w_x           = $clog2 ( screen_width  ),
               w_y           = $clog2 ( screen_height )
)
(
    input                        clk,
    input                        slow_clk,
    input                        rst,

    // Keys, switches, LEDs

    input        [w_key   - 1:0] key,
    input        [w_sw    - 1:0] sw,
    output logic [w_led   - 1:0] led,

    // A dynamic seven-segment display

    output logic [          7:0] abcdefgh,
    output logic [w_digit - 1:0] digit,

    // Graphics

    input        [w_x     - 1:0] x,
    input        [w_y     - 1:0] y,

    output logic [w_red   - 1:0] red,
    output logic [w_green - 1:0] green,
    output logic [w_blue  - 1:0] blue,

    // Microphone, sound output and UART

    input        [         23:0] mic,
    output       [         15:0] sound,

    input                        uart_rx,
    output                       uart_tx,

    // // General-purpose Input/Output

    inout        [w_gpio  - 1:0] gpio
);

    assign led        = '0;
    assign abcdefgh   = '0;
    assign digit      = '0;
    assign uart_tx = 0;
    assign sound = 0;

//note recognition here
    logic [23:0] prev_mic;
    logic [19:0] counter;
    logic [19:0] distance;

    always_ff @ (posedge clk or posedge rst)
        if (rst)
        begin
            prev_mic <= '0;
            counter  <= '0;
            distance <= '0;
        end
        else
        begin
            prev_mic <= mic;

            if (  prev_mic [$left ( prev_mic )] == 1'b1
                & mic      [$left ( mic      )] == 1'b0 )
            begin
               distance <= counter;
               counter  <= 20'h0;
            end
            else if (counter != ~ 20'h0)
            begin
               counter <= counter + 20'h1;
            end
        end

    
    localparam freq_100_C  = 13081,
               freq_100_Cs = 13859,
               freq_100_D  = 14683,
               freq_100_Ds = 15556,
               freq_100_E  = 8241,
               freq_100_F  = 8731,
               freq_100_Fs = 9250,
               freq_100_G  = 9800,
               freq_100_Gs = 10383,
               freq_100_A  = 11000,
               freq_100_As = 11654,
               freq_100_B  = 12347;

    //------------------------------------------------------------------------

    function check_freq (input [18:0] freq_100, input [18:0] freq_100_input);

       check_freq = (freq_100_input > freq_100 * 97 / 100) & 
                    (freq_100_input < freq_100 * 103 / 100);

    endfunction

    //------------------------------------------------------------------------

    function [18:0] dist_to_freq(input [19:0] distance);

        dist_to_freq = clk_mhz * 1000 * 1000 / distance * 100;

    endfunction

    //------------------------------------------------------------------------

    logic [18:0] freq_100_input;
    assign freq_100_input = dist_to_freq(distance);
    logic is_E;
    assign is_E =  check_freq(freq_100_E, freq_100_input) |
            check_freq(freq_100_E * 2, freq_100_input) |
            check_freq(freq_100_E * 4, freq_100_input);

    //frequnecy filtering
    logic d_E;  // Delayed frequnecy

    always_ff @ (posedge clk or posedge rst)
        if (rst)
            d_E <= 0;
        else
            d_E <= is_E;

    logic  [17:0] t_cnt;           // Threshold counter
    logic  [18:0] t_E;  // Thresholded frequnecy

    always_ff @ (posedge clk or posedge rst)
        if (rst)
            t_cnt <= 0;
        else
            if (is_E == d_E)
                t_cnt <= t_cnt + 1;
            else
                t_cnt <= 0;

    always_ff @ (posedge clk or posedge rst)
        if (rst)
            t_E <= 0;
        else
            if (& t_cnt)
                t_E <= d_E;

//drawing here
    always_comb begin
        red = 0;
        green = 0;
        blue = 0;

        //strings and frets
        if (y >= 31 & y < 34 |
            y >= 73 & y < 76 |
            y >= 115 & y < 118 |
            y >= 157 & y < 160 |
            y >= 199 & y < 202 |
            y >= 241 & y < 244 |
            x >= (screen_width - 1) / 2 - 1 & x <= (screen_width - 1) / 2 + 3 | 
            x >= (screen_width - 1) / 4 - 2 & x <= (screen_width - 1) / 4 + 2 |
            x >= ((screen_width - 1) / 4) * 3 + 3 & x <= ((screen_width - 1) / 4) * 3 + 7) begin
            green = 30;
        end

        // if ((x - (screen_width - 1) / 8 + 1) * (x - (screen_width - 1) / 8 + 1) + 
        //     (y - 32) * (y - 32) <= 81) begin
        //         blue = 30;
        //         green = 0;
        //     end
        //     else begin
        //         blue = 0;
        //     end
    
        if(t_E) begin
            if(y >= 241 & y < 244) begin
                blue = 30;
            end
            else begin
                blue = 0;
            end
        end
    end

endmodule