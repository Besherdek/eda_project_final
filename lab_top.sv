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

    function check_freq (input [18:0] freq_100, input [18:0] freq_100_input, input [4:0] thresh);

       check_freq = (freq_100_input > freq_100 * (100 - thresh) / 100) & 
                    (freq_100_input < freq_100 * (100 + thresh) / 100);

    endfunction

    //------------------------------------------------------------------------

    function [18:0] dist_to_freq(input [19:0] distance);

        dist_to_freq = clk_mhz * 1000 * 1000 / distance * 100;

    endfunction

    //------------------------------------------------------------------------

    logic [18:0] freq_100_input;
    assign freq_100_input = dist_to_freq(distance);

    //frequnecy filtering
    logic [18:0] d_freq_100_input;

    always_ff @ (posedge clk or posedge rst)
        if (rst)
            d_freq_100_input <= 0;
        else
            d_freq_100_input <= freq_100_input;

    logic  [18:0] t_cnt;           // Threshold counter
    logic  [18:0] t_freq_100_input;  // Thresholded frequnecy

    always_ff @ (posedge clk or posedge rst)
        if (rst)
            t_cnt <= 0;
        else
            if (freq_100_input == d_freq_100_input)
                t_cnt <= t_cnt + 1;
            else
                t_cnt <= 0;

    always_ff @ (posedge clk or posedge rst)
        if (rst)
            t_freq_100_input <= 0;
        else
            if (& t_cnt)
                t_freq_100_input <= d_freq_100_input;


    logic [5:0] fret_0;
    logic [5:0] fret_1;
    logic [5:0] fret_2;
    logic [5:0] fret_3;
    logic [5:0] fret_4;

    always_comb begin 
        fret_0[0] = check_freq(freq_100_E, t_freq_100_input, 3);
        fret_0[1] = check_freq(freq_100_A, t_freq_100_input, 3);
        fret_0[2] = check_freq(freq_100_D, t_freq_100_input, 4);
        fret_0[3] = check_freq(freq_100_G * 2, t_freq_100_input, 3);
        fret_0[4] = check_freq(freq_100_B * 2, t_freq_100_input, 3);
        fret_0[5] = check_freq(freq_100_E * 4, t_freq_100_input, 3);

        if(!(|fret_0)) begin
            fret_1[0] = check_freq(freq_100_F, t_freq_100_input, 3);
            fret_1[1] = check_freq(freq_100_As, t_freq_100_input, 3);
            fret_1[2] = check_freq(freq_100_Ds, t_freq_100_input, 3);
            fret_1[3] = check_freq(freq_100_Gs * 2, t_freq_100_input, 3);
            fret_1[4] = check_freq(freq_100_C * 2, t_freq_100_input, 3);
            fret_1[5] = check_freq(freq_100_F * 4, t_freq_100_input, 5);

            if(!(|fret_1)) begin
                fret_2[0] = check_freq(freq_100_Fs, t_freq_100_input, 3);
                fret_2[1] = check_freq(freq_100_B, t_freq_100_input, 3);
                fret_2[2] = check_freq(freq_100_E * 2, t_freq_100_input, 3);
                fret_2[3] = check_freq(freq_100_A * 2, t_freq_100_input, 3);
                fret_2[4] = check_freq(freq_100_Cs * 2, t_freq_100_input, 3);
                fret_2[5] = check_freq(freq_100_Fs * 4, t_freq_100_input, 5);
                
                if(!(|fret_2)) begin
                    fret_3[0] = check_freq(freq_100_G, t_freq_100_input, 3);
                    fret_3[1] = check_freq(freq_100_C, t_freq_100_input, 3);
                    fret_3[2] = check_freq(freq_100_F * 2, t_freq_100_input, 3);
                    fret_3[3] = check_freq(freq_100_As * 2, t_freq_100_input, 3);
                    fret_3[4] = check_freq(freq_100_D * 2, t_freq_100_input, 3);
                    fret_3[5] = check_freq(freq_100_G * 4, t_freq_100_input, 5);
                    
                    if(!(|fret_3)) begin
                        fret_4[0] = check_freq(freq_100_Gs, t_freq_100_input, 3);
                        fret_4[1] = check_freq(freq_100_Cs, t_freq_100_input, 3);
                        fret_4[2] = check_freq(freq_100_Fs * 2, t_freq_100_input, 3);
                        fret_4[3] = check_freq(freq_100_B * 2, t_freq_100_input, 3);
                        fret_4[4] = check_freq(freq_100_Ds * 2, t_freq_100_input, 5);
                        fret_4[5] = check_freq(freq_100_Gs * 4, t_freq_100_input, 5);
                    end
                end
            end
        end
    end

//drawing here
    // always_comb begin
    //     red = 0;
    //     green = 0;
    //     blue = 0;

    //     //strings and frets
    //     if (y >= 31 & y < 34 |
    //         y >= 73 & y < 76 |
    //         y >= 115 & y < 118 |
    //         y >= 157 & y < 160 |
    //         y >= 199 & y < 202 |
    //         y >= 241 & y < 244 |
    //         x >= (screen_width - 1) / 2 - 1 & x <= (screen_width - 1) / 2 + 3 | 
    //         x >= (screen_width - 1) / 4 - 2 & x <= (screen_width - 1) / 4 + 2 |
    //         x >= ((screen_width - 1) / 4) * 3 + 3 & x <= ((screen_width - 1) / 4) * 3 + 7) begin
    //         green = 30;
    //     end


    //     if(|fret_0) begin
    //         if (fret_0[0]) begin
    //             if (y >= 31 & y < 34) begin
    //                 blue = 30;
    //             end else begin
    //                 blue = 0;
    //             end
    //         end
    //         if (fret_0[1]) begin
    //             if (y >= 73 & y < 76) begin
    //                 blue = 30;
    //             end else begin
    //                 blue = 0;
    //             end
    //         end
    //         if (fret_0[2]) begin
    //             if (y >= 115 & y < 118) begin
    //                 blue = 30;
    //             end else begin
    //                 blue = 0;
    //             end
    //         end
    //         if (fret_0[3]) begin
    //             if (y >= 157 & y < 160) begin
    //                 blue = 30;
    //             end else begin
    //                 blue = 0;
    //             end
    //         end
    //         if (fret_0[4]) begin
    //             if (y >= 199 & y < 202) begin
    //                 blue = 30;
    //             end else begin
    //                 blue = 0;
    //             end
    //         end
    //         if (fret_0[5]) begin
    //             if (y >= 241 & y < 244) begin
    //                 blue = 30;
    //             end else begin
    //                 blue = 0;
    //             end
    //         end
    //     end else if(|fret_1) begin
    //         if (fret_1[0]) begin
    //             if ((x - (screen_width - 1) / 8 + 1) * (x - (screen_width - 1) / 8 + 1) + 
    //                 (y - 32) * (y - 32) <= 81) begin
    //                     blue = 30;
    //                     green = 0;
    //                 end
    //             else begin
    //                 blue = 0;
    //             end
    //         end
    //         if (fret_1[1]) begin
    //             if ((x - (screen_width - 1) / 8 + 1) * (x - (screen_width - 1) / 8 + 1) + 
    //                 (y - 74) * (y - 74) <= 81) begin
    //                     blue = 30;
    //                     green = 0;
    //                 end
    //             else begin
    //                 blue = 0;
    //             end
    //         end
    //         if (fret_1[2]) begin
    //             if ((x - (screen_width - 1) / 8 + 1) * (x - (screen_width - 1) / 8 + 1) + 
    //                 (y - 116) * (y - 116) <= 81) begin
    //                     blue = 30;
    //                     green = 0;
    //                 end
    //             else begin
    //                 blue = 0;
    //             end
    //         end
    //         if (fret_1[3]) begin
    //             if ((x - (screen_width - 1) / 8 + 1) * (x - (screen_width - 1) / 8 + 1) + 
    //                 (y - 158) * (y - 158) <= 81) begin
    //                     blue = 30;
    //                     green = 0;
    //                 end
    //             else begin
    //                 blue = 0;
    //             end
    //         end
    //         if (fret_1[4]) begin
    //             if ((x - (screen_width - 1) / 8 + 1) * (x - (screen_width - 1) / 8 + 1) + 
    //                 (y - 200) * (y - 200) <= 81) begin
    //                     blue = 30;
    //                     green = 0;
    //                 end
    //             else begin
    //                 blue = 0;
    //             end
    //         end
    //         if (fret_1[5]) begin
    //             if ((x - (screen_width - 1) / 8 + 1) * (x - (screen_width - 1) / 8 + 1) + 
    //                 (y - 242) * (y - 242) <= 81) begin
    //                     blue = 30;
    //                     green = 0;
    //                 end
    //             else begin
    //                 blue = 0;
    //             end
    //         end
    //     end else if(|fret_2) begin
    //         if (fret_2[0]) begin
    //             if ((x - (screen_width - 1) / 8 * 3 + 1) * (x - (screen_width - 1) / 8 * 3 + 1) + 
    //                 (y - 32) * (y - 32) <= 81) begin
    //                     blue = 30;
    //                     green = 0;
    //                 end
    //             else begin
    //                 blue = 0;
    //             end
    //         end
    //         if (fret_2[1]) begin
    //             if ((x - (screen_width - 1) / 8 * 3 + 1) * (x - (screen_width - 1) / 8 * 3 + 1) + 
    //                 (y - 74) * (y - 74) <= 81) begin
    //                     blue = 30;
    //                     green = 0;
    //                 end
    //             else begin
    //                 blue = 0;
    //             end
    //         end
    //         if (fret_2[2]) begin
    //             if ((x - (screen_width - 1) / 8 * 3 + 1) * (x - (screen_width - 1) / 8 * 3 + 1) + 
    //                 (y - 116) * (y - 116) <= 81) begin
    //                     blue = 30;
    //                     green = 0;
    //                 end
    //             else begin
    //                 blue = 0;
    //             end
    //         end
    //         if (fret_2[3]) begin
    //             if ((x - (screen_width - 1) / 8 * 3 + 1) * (x - (screen_width - 1) / 8 * 3 + 1) + 
    //                 (y - 158) * (y - 158) <= 81) begin
    //                     blue = 30;
    //                     green = 0;
    //                 end
    //             else begin
    //                 blue = 0;
    //             end
    //         end
    //         if (fret_2[4]) begin
    //             if ((x - (screen_width - 1) / 8 * 3 + 1) * (x - (screen_width - 1) / 8 * 3 + 1) + 
    //                 (y - 200) * (y - 200) <= 81) begin
    //                     blue = 30;
    //                     green = 0;
    //                 end
    //             else begin
    //                 blue = 0;
    //             end
    //         end
    //         if (fret_2[5]) begin
    //             if ((x - (screen_width - 1) / 8 * 3 + 1) * (x - (screen_width - 1) / 8 * 3 + 1) + 
    //                 (y - 242) * (y - 242) <= 81) begin
    //                     blue = 30;
    //                     green = 0;
    //                 end
    //             else begin
    //                 blue = 0;
    //             end
    //         end
    //     end else if(|fret_3) begin
    //         if (fret_3[0]) begin
    //             if ((x - (screen_width - 1) / 8 * 5 + 1) * (x - (screen_width - 1) / 8 * 5 + 1) + 
    //                 (y - 32) * (y - 32) <= 81) begin
    //                     blue = 30;
    //                     green = 0;
    //                 end
    //             else begin
    //                 blue = 0;
    //             end
    //         end
    //         if (fret_3[1]) begin
    //             if ((x - (screen_width - 1) / 8 * 5 + 1) * (x - (screen_width - 1) / 8 * 5 + 1) + 
    //                 (y - 74) * (y - 74) <= 81) begin
    //                     blue = 30;
    //                     green = 0;
    //                 end
    //             else begin
    //                 blue = 0;
    //             end
    //         end
    //         if (fret_3[2]) begin
    //             if ((x - (screen_width - 1) / 8 * 5 + 1) * (x - (screen_width - 1) / 8 * 5 + 1) + 
    //                 (y - 116) * (y - 116) <= 81) begin
    //                     blue = 30;
    //                     green = 0;
    //                 end
    //             else begin
    //                 blue = 0;
    //             end
    //         end
    //         if (fret_3[3]) begin
    //             if ((x - (screen_width - 1) / 8 * 5 + 1) * (x - (screen_width - 1) / 8 * 5 + 1) + 
    //                 (y - 158) * (y - 158) <= 81) begin
    //                     blue = 30;
    //                     green = 0;
    //                 end
    //             else begin
    //                 blue = 0;
    //             end
    //         end
    //         if (fret_3[4]) begin
    //             if ((x - (screen_width - 1) / 8 * 5 + 1) * (x - (screen_width - 1) / 8 * 5 + 1) + 
    //                 (y - 200) * (y - 200) <= 81) begin
    //                     blue = 30;
    //                     green = 0;
    //                 end
    //             else begin
    //                 blue = 0;
    //             end
    //         end
    //         if (fret_3[5]) begin
    //             if ((x - (screen_width - 1) / 8 * 5 + 1) * (x - (screen_width - 1) / 8 * 5 + 1) + 
    //                 (y - 242) * (y - 242) <= 81) begin
    //                     blue = 30;
    //                     green = 0;
    //                 end
    //             else begin
    //                 blue = 0;
    //             end
    //         end
    //     end else if(|fret_4) begin
    //         if (fret_4[0]) begin
    //             if ((x - (screen_width - 1) / 8 * 7 + 1) * (x - (screen_width - 1) / 8 * 7 + 1) + 
    //                 (y - 32) * (y - 32) <= 81) begin
    //                     blue = 30;
    //                     green = 0;
    //                 end
    //             else begin
    //                 blue = 0;
    //             end
    //         end
    //         if (fret_4[1]) begin
    //             if ((x - (screen_width - 1) / 8 * 7 + 1) * (x - (screen_width - 1) / 8 * 7 + 1) + 
    //                 (y - 74) * (y - 74) <= 81) begin
    //                     blue = 30;
    //                     green = 0;
    //                 end
    //             else begin
    //                 blue = 0;
    //             end
    //         end
    //         if (fret_4[2]) begin
    //             if ((x - (screen_width - 1) / 8 * 7 + 1) * (x - (screen_width - 1) / 8 * 7 + 1) + 
    //                 (y - 116) * (y - 116) <= 81) begin
    //                     blue = 30;
    //                     green = 0;
    //                 end
    //             else begin
    //                 blue = 0;
    //             end
    //         end
    //         if (fret_4[3]) begin
    //             if ((x - (screen_width - 1) / 8 * 7 + 1) * (x - (screen_width - 1) / 8 * 7 + 1) + 
    //                 (y - 158) * (y - 158) <= 81) begin
    //                     blue = 30;
    //                     green = 0;
    //                 end
    //             else begin
    //                 blue = 0;
    //             end
    //         end
    //         if (fret_4[4]) begin
    //             if ((x - (screen_width - 1) / 8 * 7 + 1) * (x - (screen_width - 1) / 8 * 7 + 1) + 
    //                 (y - 200) * (y - 200) <= 81) begin
    //                     blue = 30;
    //                     green = 0;
    //                 end
    //             else begin
    //                 blue = 0;
    //             end
    //         end
    //         if (fret_4[5]) begin
    //             if ((x - (screen_width - 1) / 8 * 7 + 1) * (x - (screen_width - 1) / 8 * 7 + 1) + 
    //                 (y - 242) * (y - 242) <= 81) begin
    //                     blue = 30;
    //                     green = 0;
    //                 end
    //             else begin
    //                 blue = 0;
    //             end
    //         end
    //     end else if(t_freq_100_input == 0) begin
    //         blue = 0;
    //     end
    // end

    logic [18:0] x_o;
    logic [18:0] y_o;
    logic [18:0] a;
    logic [18:0] b;
    always_comb begin
        red = 31;
        green = 63;
        blue = 31;

        //strings and frets
        if (y >= 68 & y < 70 & x >= 5 & x <= 474 |
            y >= 96 & y < 98 & x >= 5 & x <= 474 |
            y >= 124 & y < 126 & x >= 5 & x <= 474|
            y >= 152 & y < 154 & x >= 5 & x <= 474|
            y >= 180 & y < 182 & x >= 5 & x <= 474| 
            x >= 474 & x <= 478 & y >= 68 & y <= 182| 
            x >= 2 & x <= 5 & y >= 68 & y <= 182 )
            begin //added line for C
            red = 0;
            green = 0;
            blue = 0;
        end
        x_o = (screen_width - 1) / 12;
        y_o = 82;
        a = 4;
        b = 6;
        if ((x - x_o)*(x - x_o)/(b*b) + (y - y_o)*(y-y_o)/(a*a) <= 9) begin
            red = 0;
            green = 0;
            blue = 0;
        end   
    end 
        


endmodule