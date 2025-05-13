# Synthesis and Place & Route settings

set_device GW1NR-LV9QN88PC6/I5 -name GW1NR-9 -device_version C

set_option -synthesis_tool gowinsynthesis
set_option -output_base_name fpga_project
set_option -top_module board_specific_top
set_option -verilog_std sysv2017

set_option -use_mspi_as_gpio 1
set_option -use_sspi_as_gpio 1
add_file -type verilog r:/Applications/Gowin/basics-graphics-music/labs/3_music/my_proj/Butterfly.v
add_file -type verilog r:/Applications/Gowin/basics-graphics-music/labs/3_music/my_proj/DelayBuffer.v
add_file -type verilog r:/Applications/Gowin/basics-graphics-music/labs/3_music/my_proj/FFT.v
add_file -type verilog r:/Applications/Gowin/basics-graphics-music/labs/3_music/my_proj/lab_top.sv
add_file -type verilog r:/Applications/Gowin/basics-graphics-music/labs/3_music/my_proj/Multiply.v
add_file -type verilog r:/Applications/Gowin/basics-graphics-music/labs/3_music/my_proj/SdfUnit.v
add_file -type verilog r:/Applications/Gowin/basics-graphics-music/labs/3_music/my_proj/SdfUnit2.v
add_file -type verilog r:/Applications/Gowin/basics-graphics-music/labs/3_music/my_proj/Twiddle.v
add_file -type verilog r:/Applications/Gowin/basics-graphics-music/boards/tang_nano_9k_lcd_480_272_tm1638/board_specific_top.sv
add_file -type verilog r:/Applications/Gowin/basics-graphics-music/boards/tang_nano_9k_lcd_480_272_tm1638/gowin_rpll.v
add_file -type verilog r:/Applications/Gowin/basics-graphics-music/peripherals/audio_pwm.sv
add_file -type verilog r:/Applications/Gowin/basics-graphics-music/peripherals/digilent_pmod_mic3_spi_receiver.sv
add_file -type verilog r:/Applications/Gowin/basics-graphics-music/peripherals/hub75e_led_matrix.sv
add_file -type verilog r:/Applications/Gowin/basics-graphics-music/peripherals/i2s_audio_out.sv
add_file -type verilog r:/Applications/Gowin/basics-graphics-music/peripherals/imitate_reset_on_power_up.sv
add_file -type verilog r:/Applications/Gowin/basics-graphics-music/peripherals/inmp441_mic_i2s_receiver.sv
add_file -type verilog r:/Applications/Gowin/basics-graphics-music/peripherals/inmp441_mic_i2s_receiver_alt.sv
add_file -type verilog r:/Applications/Gowin/basics-graphics-music/peripherals/inmp441_mic_i2s_receiver_new.sv
add_file -type verilog r:/Applications/Gowin/basics-graphics-music/peripherals/lcd_480_272.sv
add_file -type verilog r:/Applications/Gowin/basics-graphics-music/peripherals/lcd_480_272_ml6485.sv
add_file -type verilog r:/Applications/Gowin/basics-graphics-music/peripherals/lcd_800_480.sv
add_file -type verilog r:/Applications/Gowin/basics-graphics-music/peripherals/sigma_delta_dac.v
add_file -type verilog r:/Applications/Gowin/basics-graphics-music/peripherals/slow_clk_gen.sv
add_file -type verilog r:/Applications/Gowin/basics-graphics-music/peripherals/tm1638_board.sv
add_file -type verilog r:/Applications/Gowin/basics-graphics-music/peripherals/tm1638_registers.sv
add_file -type verilog r:/Applications/Gowin/basics-graphics-music/peripherals/tm1638_using_graphics.sv
add_file -type verilog r:/Applications/Gowin/basics-graphics-music/peripherals/tm1638_virtual_switches.sv
add_file -type verilog r:/Applications/Gowin/basics-graphics-music/peripherals/vga.sv
add_file -type verilog r:/Applications/Gowin/basics-graphics-music/labs/common/convert.sv
add_file -type verilog r:/Applications/Gowin/basics-graphics-music/labs/common/counter_with_enable.sv
add_file -type verilog r:/Applications/Gowin/basics-graphics-music/labs/common/seven_segment_display.sv
add_file -type verilog r:/Applications/Gowin/basics-graphics-music/labs/common/shift_reg.sv
add_file -type verilog r:/Applications/Gowin/basics-graphics-music/labs/common/strobe_gen.sv
add_file -type verilog r:/Applications/Gowin/basics-graphics-music/labs/common/tb_lcd_display.sv
add_file -type cst r:/Applications/Gowin/basics-graphics-music/boards/tang_nano_9k_lcd_480_272_tm1638/board_specific.cst
add_file -type sdc r:/Applications/Gowin/basics-graphics-music/boards/tang_nano_9k_lcd_480_272_tm1638/board_specific.sdc
run all
