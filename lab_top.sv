`include "config.svh"

module lab_top # (
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

    // General-purpose Input/Output

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

    function check_freq (input [18:0] freq_100, input [18:0] freq_100_input, input [4:0] thresh);

       check_freq = (freq_100_input > freq_100 * (100 - thresh) / 100) & 
                    (freq_100_input < freq_100 * (100 + thresh) / 100);

    endfunction

    function [18:0] dist_to_freq(input [19:0] distance);

        dist_to_freq = clk_mhz * 1000 * 1000 / distance * 100;

    endfunction

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
    
    //on black/white notesheet, positions of notes(total 8)
    localparam [18:0]   x_0 = 45, 
                        x_1 = x_0 + 55,
                        x_2 = x_1 + 55,
                        x_3 = x_2 + 55,
                        x_4 = x_3 + 55,
                        x_5 = x_4 + 55,
                        x_6 = x_5 + 55,
                        x_7 = x_6 + 55;
    //on black/white notesheet, positions of possible notes
    localparam [18:0]   y_0 = 65, 
                        y_1 = 78, 
                        y_2 = 92, 
                        y_3 = 105, 
                        y_4 = 119, 
                        y_5 = 133, 
                        y_6 = 147, 
                        y_7 = 161,
                        y_8 = 175,
                        y_9 = 189,
                        y_10 = 203,
                        y_11 = 217;
    //on black/white notesheet, just for drawing ellispes
    localparam [18:0]   a = 5,
                        b = 4;
    //on black/white notesheet, possible 12 notes to draw
    localparam [11:0]   C =   12'b0000_0000_0001,
                        D =   12'b0000_0000_0010,
                        E =   12'b0000_0000_0100,
                        F =   12'b0000_0000_1000,
                        G =   12'b0000_0001_0000,
                        A =   12'b0000_0010_0000,
                        B =   12'b0000_0100_0000,
                        C_h = 12'b0000_1000_0000,
                        D_h = 12'b0001_0000_0000,
                        E_h = 12'b0010_0000_0000,
                        F_h = 12'b0100_0000_0000,
                        G_h = 12'b1000_0000_0000;
    logic [4:0] cur_note;
    logic [11:0] notes;
    logic [18:0] cur_y_0, cur_y_1, cur_y_2, cur_y_3, cur_y_4, cur_y_5, cur_y_6, cur_y_7;
    logic [18:0] cur_x_0, cur_x_1, cur_x_2, cur_x_3, cur_x_4, cur_x_5, cur_x_6, cur_x_7;//delete?(war?)
    //these two are to check if a new note is played, then draw that next to prev note(up to 8 notes)
    logic [18:0] y_to_assign;
    logic [18:0] prev_y_to_assign;
    logic current_state;
//drawing here
    always_comb begin
        if(key[0]) begin
            current_state = 0;
        end else if(key[1]) begin
            current_state = 1;
        end

        //6 strings with 4 frets
        if(current_state == 0) begin
            red = 0;
            green = 0;
            blue = 0;

            //fret_0 is if open string is played, fret_i if i-th fret is played
            fret_0[0] = check_freq(freq_100_E, t_freq_100_input, 3);
            fret_0[1] = check_freq(freq_100_A, t_freq_100_input, 3);
            fret_0[2] = check_freq(freq_100_D, t_freq_100_input, 4);
            fret_0[3] = check_freq(freq_100_G * 2, t_freq_100_input, 4);
            fret_0[4] = check_freq(freq_100_B * 2, t_freq_100_input, 4);
            fret_0[5] = check_freq(freq_100_E * 4, t_freq_100_input, 4);

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

            //strings and frets drawing
            if (y >= 31 & y < 34 |
                y >= 73 & y < 76 |
                y >= 115 & y < 118 |
                y >= 157 & y < 160 |
                y >= 199 & y < 202 |
                y >= 241 & y < 244 |
                x >= (screen_width - 1) / 2 - 2 & x <= (screen_width - 1) / 2 + 4 | 
                x >= (screen_width - 1) / 4 - 3 & x <= (screen_width - 1) / 4 + 3 |
                x >= ((screen_width - 1) / 4) * 3 + 2 & x <= ((screen_width - 1) / 4) * 3 + 8) begin
                green = 63;
            end

            //drawing played string/fret blue
            if(|fret_0) begin
                if (fret_0[0]) begin
                    if (y >= 31 & y < 34) begin
                        blue = 30;
                    end else begin
                        blue = 0;
                    end
                end
                if (fret_0[1]) begin
                    if (y >= 73 & y < 76) begin
                        blue = 30;
                    end else begin
                        blue = 0;
                    end
                end
                if (fret_0[2]) begin
                    if (y >= 115 & y < 118) begin
                        blue = 30;
                    end else begin
                        blue = 0;
                    end
                end
                if (fret_0[3]) begin
                    if (y >= 157 & y < 160) begin
                        blue = 30;
                    end else begin
                        blue = 0;
                    end
                end
                if (fret_0[4]) begin
                    if (y >= 199 & y < 202) begin
                        blue = 30;
                    end else begin
                        blue = 0;
                    end
                end
                if (fret_0[5]) begin
                    if (y >= 241 & y < 244) begin
                        blue = 30;
                    end else begin
                        blue = 0;
                    end
                end
            //from here and so we just draw circles, and not painting the whole string
            end else if(|fret_1) begin
                if (fret_1[0]) begin
                    if ((x - (screen_width - 1) / 8 + 1) * (x - (screen_width - 1) / 8 + 1) + 
                        (y - 32) * (y - 32) <= 81) begin
                            blue = 30;
                            green = 0;
                        end
                    else begin
                        blue = 0;
                    end
                end
                if (fret_1[1]) begin
                    if ((x - (screen_width - 1) / 8 + 1) * (x - (screen_width - 1) / 8 + 1) + 
                        (y - 74) * (y - 74) <= 81) begin
                            blue = 30;
                            green = 0;
                        end
                    else begin
                        blue = 0;
                    end
                end
                if (fret_1[2]) begin
                    if ((x - (screen_width - 1) / 8 + 1) * (x - (screen_width - 1) / 8 + 1) + 
                        (y - 116) * (y - 116) <= 81) begin
                            blue = 30;
                            green = 0;
                        end
                    else begin
                        blue = 0;
                    end
                end
                if (fret_1[3]) begin
                    if ((x - (screen_width - 1) / 8 + 1) * (x - (screen_width - 1) / 8 + 1) + 
                        (y - 158) * (y - 158) <= 81) begin
                            blue = 30;
                            green = 0;
                        end
                    else begin
                        blue = 0;
                    end
                end
                if (fret_1[4]) begin
                    if ((x - (screen_width - 1) / 8 + 1) * (x - (screen_width - 1) / 8 + 1) + 
                        (y - 200) * (y - 200) <= 81) begin
                            blue = 30;
                            green = 0;
                        end
                    else begin
                        blue = 0;
                    end
                end
                if (fret_1[5]) begin
                    if ((x - (screen_width - 1) / 8 + 1) * (x - (screen_width - 1) / 8 + 1) + 
                        (y - 242) * (y - 242) <= 81) begin
                            blue = 30;
                            green = 0;
                        end
                    else begin
                        blue = 0;
                    end
                end
            end else if(|fret_2) begin
                if (fret_2[0]) begin
                    if ((x - (screen_width - 1) / 8 * 3 + 1) * (x - (screen_width - 1) / 8 * 3 + 1) + 
                        (y - 32) * (y - 32) <= 81) begin
                            blue = 30;
                            green = 0;
                        end
                    else begin
                        blue = 0;
                    end
                end
                if (fret_2[1]) begin
                    if ((x - (screen_width - 1) / 8 * 3 + 1) * (x - (screen_width - 1) / 8 * 3 + 1) + 
                        (y - 74) * (y - 74) <= 81) begin
                            blue = 30;
                            green = 0;
                        end
                    else begin
                        blue = 0;
                    end
                end
                if (fret_2[2]) begin
                    if ((x - (screen_width - 1) / 8 * 3 + 1) * (x - (screen_width - 1) / 8 * 3 + 1) + 
                        (y - 116) * (y - 116) <= 81) begin
                            blue = 30;
                            green = 0;
                        end
                    else begin
                        blue = 0;
                    end
                end
                if (fret_2[3]) begin
                    if ((x - (screen_width - 1) / 8 * 3 + 1) * (x - (screen_width - 1) / 8 * 3 + 1) + 
                        (y - 158) * (y - 158) <= 81) begin
                            blue = 30;
                            green = 0;
                        end
                    else begin
                        blue = 0;
                    end
                end
                if (fret_2[4]) begin
                    if ((x - (screen_width - 1) / 8 * 3 + 1) * (x - (screen_width - 1) / 8 * 3 + 1) + 
                        (y - 200) * (y - 200) <= 81) begin
                            blue = 30;
                            green = 0;
                        end
                    else begin
                        blue = 0;
                    end
                end
                if (fret_2[5]) begin
                    if ((x - (screen_width - 1) / 8 * 3 + 1) * (x - (screen_width - 1) / 8 * 3 + 1) + 
                        (y - 242) * (y - 242) <= 81) begin
                            blue = 30;
                            green = 0;
                        end
                    else begin
                        blue = 0;
                    end
                end
            end else if(|fret_3) begin
                if (fret_3[0]) begin
                    if ((x - (screen_width - 1) / 8 * 5 + 1) * (x - (screen_width - 1) / 8 * 5 + 1) + 
                        (y - 32) * (y - 32) <= 81) begin
                            blue = 30;
                            green = 0;
                        end
                    else begin
                        blue = 0;
                    end
                end
                if (fret_3[1]) begin
                    if ((x - (screen_width - 1) / 8 * 5 + 1) * (x - (screen_width - 1) / 8 * 5 + 1) + 
                        (y - 74) * (y - 74) <= 81) begin
                            blue = 30;
                            green = 0;
                        end
                    else begin
                        blue = 0;
                    end
                end
                if (fret_3[2]) begin
                    if ((x - (screen_width - 1) / 8 * 5 + 1) * (x - (screen_width - 1) / 8 * 5 + 1) + 
                        (y - 116) * (y - 116) <= 81) begin
                            blue = 30;
                            green = 0;
                        end
                    else begin
                        blue = 0;
                    end
                end
                if (fret_3[3]) begin
                    if ((x - (screen_width - 1) / 8 * 5 + 1) * (x - (screen_width - 1) / 8 * 5 + 1) + 
                        (y - 158) * (y - 158) <= 81) begin
                            blue = 30;
                            green = 0;
                        end
                    else begin
                        blue = 0;
                    end
                end
                if (fret_3[4]) begin
                    if ((x - (screen_width - 1) / 8 * 5 + 1) * (x - (screen_width - 1) / 8 * 5 + 1) + 
                        (y - 200) * (y - 200) <= 81) begin
                            blue = 30;
                            green = 0;
                        end
                    else begin
                        blue = 0;
                    end
                end
                if (fret_3[5]) begin
                    if ((x - (screen_width - 1) / 8 * 5 + 1) * (x - (screen_width - 1) / 8 * 5 + 1) + 
                        (y - 242) * (y - 242) <= 81) begin
                            blue = 30;
                            green = 0;
                        end
                    else begin
                        blue = 0;
                    end
                end
            end else if(|fret_4) begin
                if (fret_4[0]) begin
                    if ((x - (screen_width - 1) / 8 * 7 + 1) * (x - (screen_width - 1) / 8 * 7 + 1) + 
                        (y - 32) * (y - 32) <= 81) begin
                            blue = 30;
                            green = 0;
                        end
                    else begin
                        blue = 0;
                    end
                end
                if (fret_4[1]) begin
                    if ((x - (screen_width - 1) / 8 * 7 + 1) * (x - (screen_width - 1) / 8 * 7 + 1) + 
                        (y - 74) * (y - 74) <= 81) begin
                            blue = 30;
                            green = 0;
                        end
                    else begin
                        blue = 0;
                    end
                end
                if (fret_4[2]) begin
                    if ((x - (screen_width - 1) / 8 * 7 + 1) * (x - (screen_width - 1) / 8 * 7 + 1) + 
                        (y - 116) * (y - 116) <= 81) begin
                            blue = 30;
                            green = 0;
                        end
                    else begin
                        blue = 0;
                    end
                end
                if (fret_4[3]) begin
                    if ((x - (screen_width - 1) / 8 * 7 + 1) * (x - (screen_width - 1) / 8 * 7 + 1) + 
                        (y - 158) * (y - 158) <= 81) begin
                            blue = 30;
                            green = 0;
                        end
                    else begin
                        blue = 0;
                    end
                end
                if (fret_4[4]) begin
                    if ((x - (screen_width - 1) / 8 * 7 + 1) * (x - (screen_width - 1) / 8 * 7 + 1) + 
                        (y - 200) * (y - 200) <= 81) begin
                            blue = 30;
                            green = 0;
                        end
                    else begin
                        blue = 0;
                    end
                end
                if (fret_4[5]) begin
                    if ((x - (screen_width - 1) / 8 * 7 + 1) * (x - (screen_width - 1) / 8 * 7 + 1) + 
                        (y - 242) * (y - 242) <= 81) begin
                            blue = 30;
                            green = 0;
                        end
                    else begin
                        blue = 0;
                    end
                end
            end else if(t_freq_100_input == 0) begin
                blue = 0;
            end

        // here goes notesheet
        end else begin
            //this is to reset the drawn notes
            if(key[2]) begin
                cur_note = 0;
                cur_y_0 = 0;
                cur_y_1 = 0;
                cur_y_2 = 0;
                cur_y_3 = 0;
                cur_y_4 = 0;
                cur_y_5 = 0;
                cur_y_6 = 0;
                cur_y_7 = 0;
                y_to_assign = 0;
                prev_y_to_assign = 0;
            end

            red = 31;
            green = 63;
            blue = 31;

            notes = 0;
            notes[0] = check_freq(freq_100_C * 2, t_freq_100_input, 4);
            notes[1] = check_freq(freq_100_D * 2, t_freq_100_input, 4);
            notes[2] = check_freq(freq_100_E * 4, t_freq_100_input, 4);
            notes[3] = check_freq(freq_100_F * 4, t_freq_100_input, 4);
            notes[4] = check_freq(freq_100_G * 4, t_freq_100_input, 4);
            notes[5] = check_freq(freq_100_A * 4, t_freq_100_input, 4);
            notes[6] = check_freq(freq_100_B * 4, t_freq_100_input, 4);
            notes[7] = check_freq(freq_100_C * 4, t_freq_100_input, 4);
            notes[8] = check_freq(freq_100_D * 4, t_freq_100_input, 4);
            notes[9] = check_freq(freq_100_E * 8, t_freq_100_input, 4);
            notes[10] = check_freq(freq_100_F * 8, t_freq_100_input, 4);
            notes[11] = check_freq(freq_100_G * 8, t_freq_100_input, 4);

            if(|notes) begin
                case(notes) 
                    C: y_to_assign = y_11;
                    D: y_to_assign = y_10;
                    E: y_to_assign = y_9;
                    F: y_to_assign = y_8;
                    G: y_to_assign = y_7;
                    A: y_to_assign = y_6;
                    B: y_to_assign = y_5;
                    C_h: y_to_assign = y_4;
                    D_h: y_to_assign = y_3;
                    E_h: y_to_assign = y_2;
                    F_h: y_to_assign = y_1;
                    G_h: y_to_assign = y_0;
                    default: y_to_assign = 0;
                endcase
            end

            //cur_note is an index, where to put the new note
            case(cur_note)
                0: cur_y_0 = y_to_assign;
                1: cur_y_1 = y_to_assign;
                2: cur_y_2 = y_to_assign;
                3: cur_y_3 = y_to_assign;
                4: cur_y_4 = y_to_assign;
                5: cur_y_5 = y_to_assign;
                6: cur_y_6 = y_to_assign;
                7: cur_y_7 = y_to_assign;
                default: cur_note = cur_note;
            endcase

            if(prev_y_to_assign !== y_to_assign) begin
                if(cur_note <= 7)
                    cur_note = cur_note + 1;
                prev_y_to_assign = y_to_assign;
            end

            //drawing 5 horizontal lines and 2 vertical lines
            if (y >= 78  & y < 80  & x >= 10 & x <= 468 |
                y >= 105 & y < 107 & x >= 10 & x <= 468 |
                y >= 133 & y < 135 & x >= 10 & x <= 468 |
                y >= 161 & y < 163 & x >= 10 & x <= 468 |
                y >= 189 & y < 191 & x >= 10 & x <= 468 | 
                x >= 468 & x <= 472 & y >= 78 & y < 191 |
                x >= 10  & x <= 14 & y >= 78 & y < 191) begin
                red = 0;
                green = 0;
                blue = 0;
            end

            //here we check if cur_y_i is set, then we draw an ellipse(note) on corresponding x_i
            if ((cur_y_0 !== 0) & ((x - x_0)*(x - x_0)/(a*a) + (y - cur_y_0)*(y-cur_y_0)/(b*b) <= 9) |
                (cur_y_1 !== 0) & ((x - x_1)*(x - x_1)/(a*a) + (y - cur_y_1)*(y-cur_y_1)/(b*b) <= 9) |
                (cur_y_2 !== 0) & ((x - x_2)*(x - x_2)/(a*a) + (y - cur_y_2)*(y-cur_y_2)/(b*b) <= 9) |
                (cur_y_3 !== 0) & ((x - x_3)*(x - x_3)/(a*a) + (y - cur_y_3)*(y-cur_y_3)/(b*b) <= 9) |
                (cur_y_4 !== 0) & ((x - x_4)*(x - x_4)/(a*a) + (y - cur_y_4)*(y-cur_y_4)/(b*b) <= 9) |
                (cur_y_5 !== 0) & ((x - x_5)*(x - x_5)/(a*a) + (y - cur_y_5)*(y-cur_y_5)/(b*b) <= 9) |
                (cur_y_6 !== 0) & ((x - x_6)*(x - x_6)/(a*a) + (y - cur_y_6)*(y-cur_y_6)/(b*b) <= 9) |
                (cur_y_7 !== 0) & ((x - x_7)*(x - x_7)/(a*a) + (y - cur_y_7)*(y-cur_y_7)/(b*b) <= 9) ) begin
                red = 0;
                green = 0;
                blue = 0;
            end
        end
    end
endmodule