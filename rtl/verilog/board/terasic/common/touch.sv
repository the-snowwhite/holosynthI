module touch(
	input iRST_n,
	input sys_clk,
	// Input Port(s)
	input [7:0]x,
	input [7:0]y,
	input new_coord_r,
	input penirq_n,
	input transmit_en,
	input [7:0]disp_data[64],
	input  N_adr_9,				// end transfer sig

	// Output Port(s)
	output reg [3:0]chr_3,
	output reg [3:0]lne,
	output reg [7:0]disp_val,
	output [7:0]touch_status_data[10],
	output reg[7:0] slide_val,
	output reg write_slide,
	output reg N_save_sig,
	output reg N_load_sig,
	output reg[7:0]N_sound_nr
);

parameter x_off = 7;
parameter y_off = 16;

assign touch_status_data[0] = hit_x;
assign touch_status_data[1] = hit_y;
assign touch_status_data[2] = rel_x;
assign touch_status_data[3] = rel_y;
assign touch_status_data[4] = chr_3;
assign touch_status_data[5] = lne;
assign touch_status_data[6] = edit_chr;
assign touch_status_data[7] = slide_val;
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

assign cur_h_x = (hit_x-x_off)/19;
assign cur_h_y = (hit_y-x_off)/8;


wire no_drag = ((delta_hit_x_abs <=3) && (delta_y_abs <=9));

wire in_textarea = (hit_x <=240 && hit_y <=134);

wire minus_hit = ((hit_x >= 20 && hit_x <= 39)
			&& (hit_y >= 155 && hit_y <= 168));
wire plus_hit = ((hit_x >= 221 && hit_x <= 240)
			&& (hit_y >= 155 && hit_y <= 168));
wire slide_bar_hit = ((hit_x >= 40 && hit_x <= 220)
			&& (hit_y >= 155 && hit_y <= 168));

wire write_pressed =	((hit_y >=95 && hit_y <=101) && // write line
							(hit_x >= 178 && hit_x <=200));	// write pressed

wire load_pressed =	((hit_y >=78 && hit_y <=85) && // write line
							(hit_x >= 178 && hit_x <=200));	// write pressed
reg N_save_sig_1, N_load_sig_1;							

wire cancel = ((hit_y >=94 && hit_y <=101) && // write line
							(hit_x >= 94 && hit_x <=121));	// cancel pressed

wire confirm = ((hit_y >=94 && hit_y <=101) && // write line
							(hit_x >= 137 && hit_x <=172));	// confirm pressed

wire [7:0] slide_scale = (((x - 40)<<7)/180);

	reg [7:0] edit_chr;

	always @(posedge sys_clk)begin
		case(lne)
			1: if(chr_3 <=7)disp_val <= chr_3;
			2: if(chr_3 <=7)disp_val <= chr_3+8'd8;
			3: if(chr_3<=7)disp_val <= chr_3+8'd16;
			4: if(chr_3<=7)disp_val <= chr_3+8'd24;
			7: begin 
					if(chr_3<=8'd8)disp_val <= chr_3+8'd32;
					else if (chr_3>=8'd10)disp_val <= chr_3+8'd31;
				end
			8: if(chr_3<=8'd8)disp_val <= chr_3+8'd48;
			default: disp_val <= 8'h00; 
		endcase
		edit_chr <= disp_data[disp_val];
	end


reg [7:0]t_cnt;
reg [2:0]cont_cnt;
reg cont_max_dly1,cont_max_dly2;

reg transmit_en_dly1;

always@(posedge sys_clk) transmit_en_dly1 <= transmit_en;

	always @(negedge penirq_n or negedge transmit_en)begin
		if(!transmit_en)begin t_cnt <= 0;end 
		else if(t_cnt <=7) t_cnt <= t_cnt +1;
	end
	always @(negedge penirq_n or negedge transmit_en)begin
		if(!transmit_en)begin cont_cnt <= 0;end 
		else if (t_cnt_max) cont_cnt <= cont_cnt +1;
	end

	wire t_cnt_max = (t_cnt == 8) ? 1'b1 : 1'b0;

	always @(negedge iRST_n or negedge penirq_n or negedge transmit_en)begin
	if (!iRST_n)begin
		write_slide <= 1'b0;
		N_sound_nr <= 8'h00;
	end
	else begin 
		if (!transmit_en)begin
			if (plus_hit || minus_hit)begin 
				write_slide <= ((~N_save_sig_1 & ~N_load_sig_1) & transmit_en_dly1);
//				if ((N_save_sig_1 || N_load_sig_1)&& (slide_scale < 128) )begin
				if (N_save_sig_1 || N_load_sig_1) begin
					N_sound_nr <= slide_val;
				end
			end
		end
		else begin
//			write_slide <= 1'b0;
			if (t_cnt == 7)begin
				hit_x <= x; hit_y <= y;		
			end
			if (cont_cnt == 1)begin
				if ((!N_save_sig_1 && !N_save_sig) && (!N_load_sig_1 && !N_load_sig)
					&& (in_textarea && no_drag))begin
					chr_3 <= cur_h_x;
					lne <= cur_h_y;
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
					chr_3 <= cur_h_x;
					lne <= cur_h_y;
				end		
			end
			if (cont_cnt == 2)begin
				if(N_save_sig_1 || N_load_sig_1)
					slide_val <= N_sound_nr;
				else 
					slide_val <= edit_chr;
			end
			if (cont_cnt == 3)begin
				if (slide_bar_hit && (slide_scale < 128)) slide_val <= slide_scale;
				else if (minus_hit && (slide_val != 0))
	//			else if (minus_hit)
					slide_val <= slide_val - 1;
				else if (plus_hit && slide_val < 127)
	//			else if (plus_hit)
					slide_val <= slide_val + 1;		
			end
			if(cont_cnt == 4)begin
				if (slide_bar_hit)begin
//					write_slide <= (~N_save_sig_1 | ~N_load_sig_1);
					if(N_save_sig_1 || N_load_sig_1)
						write_slide <= 1'b1;							
//						N_sound_nr <= slide_val;
				end
			end
			if(cont_cnt == 5)begin
				write_slide <= 1'b0;
				end
			end
		end
	end


	
	wire cont_cnt_max = (cont_cnt == 7) ? 1'b1 : 1'b0;

	wire [3:0] cur_x, cur_h_x, cur_y, cur_h_y;
							
	always@(posedge write_pressed or posedge N_adr_9 or posedge cancel or posedge confirm)begin
		if(cancel || N_adr_9) begin N_save_sig <= 1'b0; N_save_sig_1 <= 1'b0;end
		else if(write_pressed) N_save_sig_1 <= 1'b1;
		else if(confirm) N_save_sig <= N_save_sig_1;
	end

	always@(posedge load_pressed or posedge N_adr_9 or posedge cancel or posedge confirm)begin
		if(cancel || N_adr_9) begin N_load_sig <= 1'b0; N_load_sig_1 <= 1'b0;end
		else if(load_pressed) N_load_sig_1 <= 1'b1;
		else if(confirm) N_load_sig <= N_load_sig_1;
	end

	always @(negedge transmit_en)begin
		rel_x <= x;
		rel_y <= y;
	end

endmodule
