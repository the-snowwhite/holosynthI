module touch(
	input iRST_n,
	input sys_clk,
	// Input Port(s)
	input [7:0]x_in,
	input [9:0]y_in,
	input new_coord_r,
	input penirq_n,
	input transmit_en,
	input [7:0]disp_data[94],
	input sys_real,
	input [7:0]sys_real_dat,
	input  N_adr_9,				// disp write clk
	input 		  		prg_ch_cmd, 
	input reg  [7:0]	prg_ch_data, 

	// Output Port(s)
	output reg [3:0]chr_3,
	output reg [3:0]lne,
	output reg [3:0]col,
	output reg [3:0]row,
	output reg [7:0]disp_val,
	output [7:0]touch_status_data[10],
	output reg[7:0] slide_val,
	output reg write_slide,
	output reg N_save_sig,
	output reg N_load_sig,
	output reg[7:0]N_sound_nr
);

`ifdef _LTM_Graphics	         
	wire[7:0] x = x_in;
	wire[7:0] y = y;
`endif
`ifdef _VEEK_Graphics	         
	wire[7:0] x = x_in;
	wire[7:0] y = ((y_in * 5) >> 2);
`endif


parameter x_off = 7;
parameter y_off = 16;

assign touch_status_data[0] = hit_x;
assign touch_status_data[1] = hit_y;
assign touch_status_data[2] = rel_x;
assign touch_status_data[3] = rel_y;
assign touch_status_data[4] = chr_3;
assign touch_status_data[5] = lne;
assign touch_status_data[6] = edit_chr;
//assign touch_status_data[7] = slide_val;
assign touch_status_data[7] = sys_real_dat_r;
assign touch_status_data[8] = x;
assign touch_status_data[9] = N_sound_nr;

reg write_nr_pressed = 1'b0;
reg [7:0]hit_y, hit_x, rel_x, rel_y, t1_x,t2_x;

//reg [7:0]disk_saved_snd_nr = 2;

//reg [7:0]y_pressed,old_y;
reg [7:0] delta_x_abs_r;

wire delta_hit_x_pos = (x >= hit_x);
//wire delta_t2_x_pos = (t2_x >= t1_x) ? 1'b1:1'b0;

wire delta_y_pos = (y >= hit_y);

wire [7:0] delta_hit_x_abs = (delta_hit_x_pos) ? x - hit_x : hit_x - x;
//wire [7:0] delta_t2_x_abs = (delta_t2_x_pos) ? t2_x - t1_x : t1_x - t2_x;

wire [7:0] delta_y_abs = (delta_y_pos) ? y - hit_y : hit_y - y;

assign cur_chr_3 = (hit_x-x_off)/19;
assign cur_lne = (hit_y-x_off)>>3;


wire drag = ((delta_hit_x_abs >=3) && (delta_y_abs >=9));

wire in_textarea = (hit_x <=240 && hit_y <=134);

wire minus_hit = ((hit_x >= 20 && hit_x <= 39)
			&& (hit_y >= 155 && hit_y <= 168));
wire plus_hit = ((hit_x >= 221 && hit_x <= 240)
			&& (hit_y >= 155 && hit_y <= 168));
wire slide_bar_hit = ((hit_x >= 40 && hit_x <= 220)
			&& (hit_y >= 155 && hit_y <= 168));

wire save_pressed =	((hit_y >=44 && hit_y <=50) && // write line
							(hit_x >= 178 && hit_x <=196));	// write pressed

wire load_pressed =	((hit_y >=35 && hit_y <=42) && // write line
							(hit_x >= 178 && hit_x <=196));	// write pressed
reg N_save_sig_1, N_load_sig_1;							

wire cancel = ((hit_y >=9 && hit_y <=22) && // write line
							(hit_x >= 205 && hit_x <=237));	// cancel pressed

wire confirm = ((hit_y >=107 && hit_y <=113) && // write line
							(hit_x >= 206 && hit_x <=236));	// confirm pressed

wire [7:0] slide_scale = (((hit_x - 40)<<7)/180);

	reg [7:0] edit_chr;
	reg [3:0] penirq_cnt, end_cnt;
	reg penirq_cnt_en, penirq_n_r, transmit_en_r, prg_ch_cmd_r, prg_ch_cmd_r2;
	
	wire sample_hit = (penirq_cnt == 3'd3);
	
	reg sample_hit_r, transmit_en_dly, end_cnt_max_r, penirq_cnt_max_r, start_p_cnt_r;
	reg in_textarea_r, cancel_r, load_pressed_r, save_pressed_r, confirm_r, plus_hit_r, minus_hit_r, drag_r,slide_bar_hit_r;
	reg [3:0] cur_chr_3_r, cur_lne_r;

	reg load, diskop;
	

	
	wire end_cnt_max = (end_cnt >= 8) ? 1'b1 : 1'b0;
	wire penirq_cnt_max = (end_cnt >= 6) ? 1'b1 : 1'b0;

	wire [3:0] cur_x, cur_chr_3, cur_y, cur_lne;
	
	wire start_p_cnt = transmit_en_r && !transmit_en_dly;	
	reg [7:0]sys_real_dat_r, prg_ch_data_r;
	
	always @(posedge sys_real) sys_real_dat_r <= sys_real_dat;
	
	always @(posedge sys_clk) begin
		sample_hit_r <= sample_hit;
		penirq_n_r <= penirq_n;
		transmit_en_r <= transmit_en;
		transmit_en_dly <= transmit_en_r;
		end_cnt_max_r <= end_cnt_max;
		penirq_cnt_max_r <= penirq_cnt_max;
		cur_chr_3_r <= cur_chr_3;
		cur_lne_r <= cur_lne;
		start_p_cnt_r <= start_p_cnt;
		in_textarea_r <= in_textarea;
		cancel_r <= cancel;
		load_pressed_r <= load_pressed;
		save_pressed_r <= save_pressed;
		confirm_r <= confirm;
		plus_hit_r <= plus_hit;
		minus_hit_r <= minus_hit;
		drag_r <= drag;
		slide_bar_hit_r <= slide_bar_hit;
		prg_ch_cmd_r <= prg_ch_cmd;
		prg_ch_cmd_r2 <= prg_ch_cmd_r;
	end
	
//	always @(posedge prg_ch_cmd_r) prg_ch_data_r <= prg_ch_data;

	always @(negedge transmit_en_r)begin
		rel_x <= x;
		rel_y <= y;
	end

	always @(negedge iRST_n or posedge sample_hit_r)begin
		if (!iRST_n)begin
			hit_x <= 0; hit_y <= 0;
		end else begin
			if(sample_hit_r) begin
				hit_x <= x; hit_y <= y;		
			end
		end
	end
	
	always @(negedge iRST_n or posedge start_p_cnt_r or posedge sample_hit_r or posedge sample_hit_r) begin
		if (!iRST_n)begin
			penirq_cnt_en <= 1'b0;
		end else begin 
			if (start_p_cnt_r )begin
				penirq_cnt_en <= ~sample_hit_r;
			end
			else if(sample_hit_r) penirq_cnt_en <= ~sample_hit_r; 
		end
	end	

	always @(negedge iRST_n or negedge penirq_n_r or negedge transmit_en_r)begin
		if (!iRST_n)begin
			penirq_cnt <= 4'd0;
		end else begin 
			if (transmit_en_r == 0) begin penirq_cnt <= 4'd0;end 
			else if(penirq_cnt_max_r == 0)penirq_cnt <= penirq_cnt + 1;
		end
	end	

	always @(negedge iRST_n or posedge sys_clk or posedge transmit_en_r)begin
		if (!iRST_n)begin
			end_cnt <= 3'd0;
		end else begin
			if(transmit_en_r)begin end_cnt <= 3'd0;end 
			else if (end_cnt_max_r == 0) end_cnt <= end_cnt +1;
		end
	end


	
	always @(posedge sys_clk)begin
		if(penirq_cnt == 4 && in_textarea_r)begin
			case(cur_lne_r)
				1: begin if(cur_chr_3_r <=7)disp_val <= cur_chr_3_r;
						else if (cur_chr_3_r <=9)disp_val <= cur_chr_3_r +8'd84;
					end
				2: if(cur_chr_3_r <=7)disp_val <= cur_chr_3_r+8'd8;
				3: if(cur_chr_3_r<=7)disp_val <= cur_chr_3_r+8'd16;
				4: if(cur_chr_3_r<=7)disp_val <= cur_chr_3_r+8'd24;
				7: if(cur_chr_3_r<=8'd11)disp_val <= cur_chr_3_r+8'd32;
				8: if(cur_chr_3_r<=8'd11)disp_val <= cur_chr_3_r+8'd48;
				9: if(cur_chr_3_r<=8'd11)disp_val <= cur_chr_3_r+8'd64;
				10: if(cur_chr_3_r<=8'd11)disp_val <= cur_chr_3_r+8'd80;
				default: disp_val <= 8'hff; 
			endcase
		end
		else if (disp_val != 8'hff && penirq_cnt == 4'd5) edit_chr <= disp_data[disp_val];
	end


	always @(negedge iRST_n or posedge sys_clk)begin
		if (!iRST_n)begin
			chr_3 <= 4'd0;
			lne <= 4'd0;
			N_load_sig <= 1'b0;N_save_sig <= 1'b0;diskop <= 1'b0;
		end
		else begin 
			if(!prg_ch_cmd && prg_ch_cmd_r)begin N_sound_nr <= prg_ch_data;N_load_sig <= 1'b1;end
			else if(!prg_ch_cmd_r && prg_ch_cmd_r2) N_load_sig <= 1'b0; 
			else if(diskop)begin
				if(end_cnt == 1)begin
					if(confirm_r)begin
						if(load) N_load_sig <= 1'b1;
						else N_save_sig <= 1'b1;
					 col <= 11; row <= 12;
					end
					else if(cancel_r)begin diskop <= 1'b0;chr_3 <= cur_chr_3_r;lne <= cur_lne_r;
													 col <= 11; row <= 0; end
					else if (slide_bar_hit_r && (slide_scale < 128)) slide_val <= slide_scale;
					else if (minus_hit_r && (slide_val != 0))
						slide_val <= slide_val - 1;
					else if (plus_hit_r && slide_val < 127)
						slide_val <= slide_val + 1;		
				end
				if(end_cnt == 2)begin
					if(N_load_sig || N_save_sig)begin
						N_load_sig <= 1'b0;N_save_sig <= 1'b0;diskop <= 1'b0;
					end
				end
				else if(slide_bar_hit_r || plus_hit_r || minus_hit_r) N_sound_nr <= slide_val;
			end
			else begin
				if (end_cnt == 1)begin
					if(in_textarea_r)begin 
						if(disp_val != 8'hff )begin
							chr_3 <= cur_chr_3_r;
							lne <= cur_lne_r;
							slide_val <= edit_chr;
						end
						if(cancel_r)begin diskop  <= 1'b0;chr_3 <= cur_chr_3_r;lne <= cur_lne_r;end
						if(load_pressed_r)begin diskop <= 1'b1; load <= 1'b1;chr_3 <= 11;lne <= 3;
														slide_val <= N_sound_nr; col <= 9; row <= 3;end
						if(save_pressed_r)begin diskop <= 1'b1; load <= 1'b0;chr_3 <= 11;lne <= 3;
														slide_val <= N_sound_nr; col <= 9; row <= 4;end	
					end
					else if (slide_bar_hit_r && (slide_scale < 128)) slide_val <= slide_scale;
					else if (minus_hit_r && (slide_val != 0))
						slide_val <= slide_val - 1;
					else if (plus_hit_r && slide_val < 127)
						slide_val <= slide_val + 1;		
				end
				else if(end_cnt == 2) begin if(slide_bar_hit_r || plus_hit_r || minus_hit_r) write_slide <= 1'b1;end
				else if(end_cnt == 4) begin if(slide_bar_hit_r || plus_hit_r || minus_hit_r) write_slide <= 1'b0;end
			end
		end
	end
	
/*	always @(negedge iRST_n or posedge sys_clk or negedge transmit_en_r)begin
		if (!iRST_n)begin
			write_slide <= 1'b0;
			N_sound_nr <= 8'h00;
		end
		else begin 
			if (!transmit_en_r)begin
				if (plus_hit || minus_hit)begin 
					write_slide <= ((~N_save_sig_1 & ~N_load_sig_1) & transmit_en_dly);
					if (N_save_sig_1 || N_load_sig_1) begin
						N_sound_nr <= slide_val;
					end
				end
			end
			else begin
				if (end_cnt == 1)begin
					if ((!N_save_sig_1 && !N_save_sig) && (!N_load_sig_1 && !N_load_sig)
					&& (in_textarea && no_drag))begin
						chr_3 <= cur_chr_3;
						lne <= cur_lne;
					end
					else if(N_save_sig_1 && !N_save_sig)begin
						chr_3 <= 4'd11;
						lne <= 4'd11;
					end
					else if(N_load_sig_1 && !N_load_sig)begin
						chr_3 <= 4'd11;
						lne <= 4'd09;
					end
					else if (N_save_sig || N_load_sig)begin
						chr_3 <= cur_chr_3;
						lne <= cur_lne;
					end		
				end
				if (end_cnt == 2)begin
					if(N_save_sig_1 || N_load_sig_1)
						slide_val <= N_sound_nr;
					else 
						slide_val <= edit_chr;
				end
				if (end_cnt == 3)begin
					if (slide_bar_hit && (slide_scale < 128)) slide_val <= slide_scale;
					else if (minus_hit && (slide_val != 0))
						slide_val <= slide_val - 1;
					else if (plus_hit && slide_val < 127)
						slide_val <= slide_val + 1;		
				end
				if(end_cnt == 4)begin
					if (slide_bar_hit)begin
						if(N_save_sig_1 || N_load_sig_1)
							write_slide <= 1'b1;							
					end
				end
				if(end_cnt == 5)begin
					write_slide <= 1'b0;
				end
			end
		end
	end


	
	always@(posedge save_pressed or posedge N_adr_9 or posedge cancel or posedge confirm)begin
		if(cancel || N_adr_9) begin N_save_sig <= 1'b0; N_save_sig_1 <= 1'b0;end
		else if(save_pressed) N_save_sig_1 <= 1'b1;
		else if(confirm) N_save_sig <= N_save_sig_1;
	end

	always@(posedge load_pressed or posedge N_adr_9 or posedge cancel or posedge confirm)begin
		if(cancel || N_adr_9) begin N_load_sig <= 1'b0; N_load_sig_1 <= 1'b0;end
		else if(load_pressed) N_load_sig_1 <= 1'b1;
		else if(confirm) N_load_sig <= N_load_sig_1;
	end
*/
endmodule
