module display(
	input VGA_CLK,
	input	sys_clk,
	input [7:0]scan_code1,
	input [7:0]scan_code2,
	input [7:0]scan_code3,
	input [7:0]scan_code4,
	input [7:0]disp_data[94],
	input [7:0]status_data[12],
	input DLY2,
	output SYNC,	
	output HS,
	output VS,
	output inDisplayArea,
	output inLcdDisplay,	
	output HD,	
	output VD,	
	output DEN,	
	output [9:0] VGA_R,
	output [9:0] VGA_G,
	output [9:0] VGA_B,
	//	output [3:0]color,
	input [9:0] N_adr,				// data addr.
	input [2:0]	N_adr_data_rdy,	// 2'b01 = read from synth/save to disk; 2'b11 = write to synth/load from disk; bit 2 >= to char_disp2 mem 
	input [7:0] N_synth_in_data,		// data byte from nios to synth
	input [3:0]chr_3,
	input [3:0]lne,
	input [3:0]col,
	input [3:0]row,
	input [7:0] slide_val
);				

	parameter key_y_offset = 370;
	assign  SYNC=1;	

///////////   Color Settings //////	
	wire 	[3:0]color;	


	wire [9:0]color_R[15:0];	
	wire [9:0]color_G[15:0];	
	wire [9:0]color_B[15:0];	
	assign color_R[0] = 9'h000; assign color_G[0] = 9'h000; assign color_B[0] = 9'h000;  // Background	
//	assign color_R[1] = 9'h1f0; assign color_G[1] = 9'h1f0; assign color_B[1] = 9'h000;	 // Text Background (yellow)	
	assign color_R[1] = 9'h010; assign color_G[1] = 9'h120; assign color_B[1] = 9'h100;	 // Text Background	
	assign color_R[2] = 9'h010; assign color_G[2] = 9'h0f0; assign color_B[2] = 9'h0f0;	 // Text2 Background	
	assign color_R[3] = 9'h1f0; assign color_G[3] = 9'h1f0; assign color_B[3] = 9'h1f0;  // White
	assign color_R[4] = 9'h1f0; assign color_G[4] = 9'h1f0; assign color_B[4] = 9'h1f0;  // Cursor
	assign color_R[5] = 9'h1ff; assign color_G[5] = 9'h086; assign color_B[5] = 9'h006;  // marker		
//	assign color_R[5] = 9'h010; assign color_G[5] = 9'h0f0; assign color_B[5] = 9'h170;  // Text (blue)	
	assign color_R[6] = 9'h000; assign color_G[6] = 9'h000; assign color_B[6] = 9'h000;  // Text		
	assign color_R[7] = 9'h000; assign color_G[7] = 9'h010; assign color_B[7] = 9'h010;  // Text2		
	assign color_R[8] = 9'h100; assign color_G[8] = 9'h130; assign color_B[8] = 9'h1f0;  // slider		
	assign color_R[9] = 9'h010; assign color_G[9] = 9'h020; assign color_B[9] = 9'h0f0;  // Black	
	
	assign VGA_R = color_R[color];
	assign VGA_G = color_G[color];
	assign VGA_B = color_B[color];	


	
	
///////640X480 VGA-Timing-generater///////
	wire [11:0] CounterX_org;
	wire [11:0] CounterY_org;

`ifdef _LTM_Graphics	         
	wire [11:0] CounterX = CounterX_org;
	wire [11:0] CounterY = CounterY_org;
`endif
`ifdef _VEEK_Graphics	         
	wire [11:0] CounterX = 800 - CounterX_org;
	wire [11:0] CounterY = 600 - CounterY_org;
`endif	
	TCON	u11b			(	//	Host Side
		.oCurrent_X( CounterX_org ),
		.oCurrent_Y( CounterY_org ),
//	VGA Side
		.oVGA_HS(HS),
		.oVGA_VS(VS),
		.oinDisplayArea(inDisplayArea),
		.oHD(HD),
		.oVD(VD),
		.oDEN(DEN),
//	Control Signal
		.iCLK(VGA_CLK),
		.iRST_N(DLY2),
		.oLCD_BLANK(inLcdDisplay)
	);
	wire Char_ACT;
	wire intextarea;
	
	wire Char_ACT2;
	wire intextarea2;
	
	char_disp char_gen(
		// Input Ports
		.counterX ( CounterX ),
		.counterY (CounterY ),
		.ram_Adr (char_adr),
		.ram_Data (char_data),
		.clk	(VGA_CLK ),
		.wclk	( sys_clk ),
		.write_Ram(w_char),
		//	input signed [<msb>:<lsb>] <port_name>,
		// Output Ports
		.char_bit(Char_ACT),
		.intextarea(intextarea)
		);						
							
	char_disp char_gen2(
		// Input Ports
		.counterX ( CounterX ),
		.counterY (((CounterY<=320) ? 0 : (CounterY - 320))),
		.ram_Adr (N_adr),
		.ram_Data (N_synth_in_data),
		.clk	( VGA_CLK ),
		.wclk	( N_adr_data_rdy[2] ),
		.write_Ram(w_char),
		//	input signed [<msb>:<lsb>] <port_name>,
		// Output Ports
		.char_bit(Char_ACT2),
		.intextarea(intextarea2)
		);						
							
	wire [9:0]char_adr = {line,chr};
	wire [7:0] char_data;
	wire w_char = 1;
	reg [9:0]chr_indx;
	wire [5:0]chr = chr_indx[5:0];
	wire [3:0]line = chr_indx[9:6];
	wire [3:0]data_var = chr_indx[5:2];

	function [7:0]char_buffer;
		input [7:0]indx;
		input [3:0]lne;
		begin
			string text_data0 = "                                                ";
			string text_data1 = " R1  L1  R2  L2  R3  L3  R4  L4 PBr VOL  Cancel ";
			string text_data2 = "                                    Load nr:    ";
			string text_data3 = "                                    Save        ";
			string text_data4 = "                                        Confirm ";
			string text_data5 = " CT  FT LVL MOD  FB Ksc OFS pan Bct Bft Mi  FBi ";
			string text_data6 = " Active keys                            Confirm ";
			string text_data7 = "   !!!  Note Off ERROR !!!                      ";
			string text_data8 = "aKY onx h_x h_y r_x r_y chr lne eCR sRL  x   y  ";
			case (lne) 
				0 :	char_buffer = text_data0[indx];
				1 :	char_buffer = text_data1[indx];
				2 :	char_buffer = text_data2[indx];
				3 :	char_buffer = text_data3[indx];
				4 :	char_buffer = text_data4[indx];
				5 :	char_buffer = text_data5[indx];
				6 :	char_buffer = text_data6[indx];
				7 :	char_buffer = text_data7[indx];
				8 :	char_buffer = text_data8[indx];
				default : char_buffer = " ";
			endcase
		end
	endfunction

	parameter WIDTH=8;	

	task cnv_var;
		input [WIDTH-1:0] inx,data;
		output [WIDTH-1:0] var_str;
		string numbers = "0123456789";
		byte var_data[4];
		var_data[3] = " ";
		var_data[2] = (numbers[(data-((data/100)*100)-((data-((data/100)*100))/10)*10)]);
		var_data[1] = ((data <= 9)  ? ("-") : (numbers[((data-((data/100)*100))/10)]));
		var_data[0] = ((data <= 99) ? ("-") : (numbers[(data/100)]));
		var_str = var_data[inx];
	endtask

	wire [7:0]var_str;
	reg [7:0]itostr;
	reg tgle;	
		
	always @(posedge sys_clk)begin
		if (tgle)begin chr_indx <= chr_indx+1; end
		tgle <= ~tgle; 
//		char_adr <= {line,chr};
		cnv_var(chr[1:0],itostr,var_str);
		if(line == 0) begin
			char_data <= char_buffer(chr,1);
		end
		else if(line == 1)begin
			if(chr < (8*4))begin
				itostr <= disp_data[{3'b000,data_var}];
				char_data <= var_str;
			end
			else if (chr < (10*4))begin
				itostr <= disp_data[{5'b10111,data_var[1:0]}];
				char_data <= var_str;
			end
		end
		else if(line == 2)begin
			if (chr < 32)begin
				itostr <= disp_data[{4'b0001,data_var[2:0]}];
				char_data <= var_str;
			end else begin
				char_data <= char_buffer(chr,0);			
			end
		end
		else if(line == 3) begin
			if (chr < 32)begin
				itostr <= disp_data[{3'b001,data_var}];
				char_data <= var_str;
			end else if(chr < 11*4)begin
				char_data <= char_buffer(chr,2);			
			end else if(chr < 12*4)begin
				itostr <= status_data[11];
				char_data <= var_str;		
			end
		end			
		else if(line == 4)begin
			if(chr < 32)begin
				itostr <= disp_data[{4'b0011,data_var[2:0]}];
				char_data <= var_str;
			end else begin
				char_data <= char_buffer(chr,3);			
			end
		end			
		else if(line == 5)begin
			char_data <= char_buffer(chr,(0));
		end			
		else if(line == 6)begin
			char_data <= char_buffer(chr,(5));
		end			
		else if(line == 7 )begin
			if(chr < (12*4))begin
				itostr <= disp_data[{3'b010,data_var}];				
				char_data <= var_str;
			end
		end			
		else if(line == 8)begin
			if(chr < (12*4))begin
				itostr <= disp_data[{3'b011,data_var}];				
				char_data <= var_str;
			end
		end
		else if(line == 9)begin
			if(chr < (12*4))begin
				itostr <= disp_data[{3'b100,data_var}];				
				char_data <= var_str;
			end
		end
		else if(line == 10)begin
			if(chr < (12*4))begin
				itostr <= disp_data[{3'b101,data_var}];				
				char_data <= var_str;
			end
		end
		else if(line == 11 )begin
			char_data <= char_buffer(chr,(0));
		end			
		else if(line == 12)begin
			if( chr <=11 || chr >= 39)begin
				char_data <= char_buffer(chr,(6));
			end
			else if (chr <= 15) begin
				itostr <= status_data[0];
				char_data <= var_str;
			end
		end		
		else if(line == 13 && (status_data[1] >= 64))begin
			char_data <= char_buffer(chr,(7));
		end			
		else if(line == 14 )begin
			char_data <= char_buffer(chr,(8));
		end			
		else if(line == 15)begin
			if(chr < (12*4))begin
				itostr <= status_data[{3'b000,data_var}];
				char_data <= var_str;
			end
		end			
		else 
			char_data <= " ";
	end
/////////Channel-1 Trigger////////
/*	wire L_5_tr=(scan_code1==8'h37)?1:0;//-5
	wire L_6_tr=(scan_code1==8'h39)?1:0;//-6		
	wire L_7_tr=(scan_code1==8'h3b)?1:0;//-7		
	wire M_1_tr=(scan_code1==8'h3c)?1:0;//1		
	wire M_2_tr=(scan_code1==8'h3e)?1:0;//2		
	wire M_3_tr=(scan_code1==8'h40)?1:0;//3		
	wire M_4_tr=(scan_code1==8'h41)?1:0;//4		
	wire M_5_tr=(scan_code1==8'h43)?1:0;//5		
	wire M_6_tr=(scan_code1==8'h45)?1:0;//6		
	wire M_7_tr=(scan_code1==8'h47)?1:0;//7		
	wire H_1_tr=(scan_code1==8'h48)?1:0;//+1		
	wire H_2_tr=0;//+2
	wire H_3_tr=0;//+3
	wire H_4_tr=0;//+4
	wire H_5_tr=0;//+5
	wire Hu4_tr=0;//((!get_gate) && (scan_code==8'h15))?1:0;//+#4
	wire Hu2_tr=0;//((!get_gate) && (scan_code==8'h1d))?1:0;//+#2
	wire Hu1_tr=(scan_code1==8'h49)?1:0;//+#1
	wire Mu6_tr=(scan_code1==8'h46)?1:0;//#6
	wire Mu5_tr=(scan_code1==8'h44)?1:0;//#5
	wire Mu4_tr=(scan_code1==8'h42)?1:0;//#4
	wire Mu2_tr=(scan_code1==8'h3f)?1:0;//#2
	wire Mu1_tr=(scan_code1==8'h3d)?1:0;//#1
	wire Lu6_tr=(scan_code1==8'h3a)?1:0;//-#6
	wire Lu5_tr=(scan_code1==8'h38)?1:0;//-#5
	wire Lu4_tr=(scan_code1==8'h36)?1:0;//-#4
//	assign sound1=scan_code1;
////////Channel-2 Trigger////////
	wire L2_5_tr=(scan_code2==8'h37)?1:0;//-5
	wire L2_6_tr=(scan_code2==8'h39)?1:0;//-6		
	wire L2_7_tr=(scan_code2==8'h3b)?1:0;//-7		
	wire M2_1_tr=(scan_code2==8'h3c)?1:0;//1		
	wire M2_2_tr=(scan_code2==8'h3e)?1:0;//2		
	wire M2_3_tr=(scan_code2==8'h40)?1:0;//3		
	wire M2_4_tr=(scan_code2==8'h41)?1:0;//4		
	wire M2_5_tr=(scan_code2==8'h43)?1:0;//5		
	wire M2_6_tr=(scan_code2==8'h45)?1:0;//6		
	wire M2_7_tr=(scan_code2==8'h47)?1:0;//7		
	wire H2_1_tr=(scan_code2==8'h48)?1:0;//+1		
	wire H2_2_tr=0;//+2
	wire H2_3_tr=0;//+3
	wire H2_4_tr=0;//+4
	wire H2_5_tr=0;//+5
	wire H2u4_tr=0;//((!get_gate) && (scan_code==8'h15))?1:0;//+#4
	wire H2u2_tr=0;//((!get_gate) && (scan_code==8'h1d))?1:0;//+#2
	wire H2u1_tr=(scan_code2==8'h49)?1:0;//+#1
	wire M2u6_tr=(scan_code2==8'h46)?1:0;//#6
	wire M2u5_tr=(scan_code2==8'h44)?1:0;//#5
	wire M2u4_tr=(scan_code2==8'h42)?1:0;//#4
	wire M2u2_tr=(scan_code2==8'h3f)?1:0;//#2
	wire M2u1_tr=(scan_code2==8'h3d)?1:0;//#1
	wire L2u6_tr=(scan_code2==8'h3a)?1:0;//-#6
	wire L2u5_tr=(scan_code2==8'h38)?1:0;//-#5
	wire L2u4_tr=(scan_code2==8'h36)?1:0;//-#4

//	assign sound2=scan_code2;
/////////Channel-3 Trigger////////
	wire L3_5_tr=(scan_code3==8'h37)?1:0;//-5
	wire L3_6_tr=(scan_code3==8'h39)?1:0;//-6		
	wire L3_7_tr=(scan_code3==8'h3b)?1:0;//-7		
	wire M3_1_tr=(scan_code3==8'h3c)?1:0;//1		
	wire M3_2_tr=(scan_code3==8'h3e)?1:0;//2		
	wire M3_3_tr=(scan_code3==8'h40)?1:0;//3		
	wire M3_4_tr=(scan_code3==8'h41)?1:0;//4		
	wire M3_5_tr=(scan_code3==8'h43)?1:0;//5		
	wire M3_6_tr=(scan_code3==8'h45)?1:0;//6		
	wire M3_7_tr=(scan_code3==8'h47)?1:0;//7		
	wire H3_1_tr=(scan_code3==8'h48)?1:0;//+1		
	wire H3_2_tr=0;//+2
	wire H3_3_tr=0;//+3
	wire H3_4_tr=0;//+4
	wire H3_5_tr=0;//+5
	wire H3u4_tr=0;//((!get_gate) && (scan_code==8'h15))?1:0;//+#4
	wire H3u2_tr=0;//((!get_gate) && (scan_code==8'h1d))?1:0;//+#2
	wire H3u1_tr=(scan_code3==8'h49)?1:0;//+#1
	wire M3u6_tr=(scan_code3==8'h46)?1:0;//#6
	wire M3u5_tr=(scan_code3==8'h44)?1:0;//#5
	wire M3u4_tr=(scan_code3==8'h42)?1:0;//#4
	wire M3u2_tr=(scan_code3==8'h3f)?1:0;//#2
	wire M3u1_tr=(scan_code3==8'h3d)?1:0;//#1
	wire L3u6_tr=(scan_code3==8'h3a)?1:0;//-#6
	wire L3u5_tr=(scan_code3==8'h38)?1:0;//-#5
	wire L3u4_tr=(scan_code3==8'h36)?1:0;//-#4
	
//	assign sound3=scan_code3;
/////////Channel-4 Trigger////////
	wire L4_5_tr=(scan_code4==8'h37)?1:0;//-5
	wire L4_6_tr=(scan_code4==8'h39)?1:0;//-6		
	wire L4_7_tr=(scan_code4==8'h3b)?1:0;//-7		
	wire M4_1_tr=(scan_code4==8'h3c)?1:0;//1		
	wire M4_2_tr=(scan_code4==8'h3e)?1:0;//2		
	wire M4_3_tr=(scan_code4==8'h40)?1:0;//3		
	wire M4_4_tr=(scan_code4==8'h41)?1:0;//4		
	wire M4_5_tr=(scan_code4==8'h43)?1:0;//5		
	wire M4_6_tr=(scan_code4==8'h45)?1:0;//6		
	wire M4_7_tr=(scan_code4==8'h47)?1:0;//7		
	wire H4_1_tr=(scan_code4==8'h48)?1:0;//+1		
	wire H4_2_tr=0;//+2
	wire H4_3_tr=0;//+3
	wire H4_4_tr=0;//+4
	wire H4_5_tr=0;//+5
	wire H4u4_tr=0;//((!get_gate) && (scan_code==8'h15))?1:0;//+#4
	wire H4u2_tr=0;//((!get_gate) && (scan_code==8'h1d))?1:0;//+#2
	wire H4u1_tr=(scan_code4==8'h49)?1:0;//+#1
	wire M4u6_tr=(scan_code4==8'h46)?1:0;//#6
	wire M4u5_tr=(scan_code4==8'h44)?1:0;//#5
	wire M4u4_tr=(scan_code4==8'h42)?1:0;//#4
	wire M4u2_tr=(scan_code4==8'h3f)?1:0;//#2
	wire M4u1_tr=(scan_code4==8'h3d)?1:0;//#1
	wire L4u6_tr=(scan_code4==8'h3a)?1:0;//-#6
	wire L4u5_tr=(scan_code4==8'h38)?1:0;//-#5
	wire L4u4_tr=(scan_code4==8'h36)?1:0;//-#4

//	assign sound4=scan_code4;
///////////White Key///////////
	wire L_5;
	wire L_6;
	wire L_7;
	wire M_1;
	wire M_2;
	wire M_3;
	wire M_4;
	wire M_5;
	wire M_6;
	wire M_7;
	wire H_1;
	wire H_2;
	wire H_3;
	wire H_4;
	wire H_5;
	bar_white bar1(
 		.CounterX(CounterX),
 		.L_5(L_5),
 		.L_6(L_6),
 		.L_7(L_7),
 		.M_1(M_1),
 		.M_2(M_2),
 		.M_3(M_3),
 		.M_4(M_4),
 		.M_5(M_5),
 		.M_6(M_6),
 		.M_7(M_7),
 		.H_1(H_1),
 		.H_2(H_2),
 		.H_3(H_3),
 		.H_4(H_4),
 		.H_5(H_5)
	);
	wire [11:0]xdeta=30-8;

	wire [11:0]xd_t =xdeta+2;
	wire [11:0]x_org=(
		(L_5)?11+xd_t*0:( //+5
		(L_6)?11+xd_t*1:( //+4
		(L_7)?11+xd_t*2:( //+3
		(M_1)?11+xd_t*3:( //+2
		(M_2)?11+xd_t*4:( //+1
		(M_3)?11+xd_t*5:( //7
		(M_4)?11+xd_t*6:( //6
		(M_5)?11+xd_t*7:( //5
		(M_6)?11+xd_t*8:( //4
		(M_7)?11+xd_t*9:( //3
		(H_1)?11+xd_t*10:(//2
		(H_2)?11+xd_t*11:(//1
		(H_3)?11+xd_t*12:(//-7
		(H_4)?11+xd_t*13:(//-6
		(H_5)?11+xd_t*14:xd_t*14//-5		
		))))))))))))))
	);

/////////White-key play////////
	wire [11:0]white_y=(
		((L4_5_tr|L3_5_tr|L2_5_tr|L_5_tr)&&(L_5))?110:(
		((L4_6_tr|L3_6_tr|L2_6_tr|L_6_tr)&&(L_6))?110:(
		((L4_7_tr|L3_7_tr|L2_7_tr|L_7_tr)&&(L_7))?110:(
		((M4_1_tr|M3_1_tr|M2_1_tr|M_1_tr)&&(M_1))?110:(
		((M4_2_tr|M3_2_tr|M2_2_tr|M_2_tr)&&(M_2))?110:(
		((M4_3_tr|M3_3_tr|M2_3_tr|M_3_tr)&&(M_3))?110:(
		((M4_4_tr|M3_4_tr|M2_4_tr|M_4_tr)&&(M_4))?110:(
		((M4_5_tr|M3_5_tr|M2_5_tr|M_5_tr)&&(M_5))?110:(
		((M4_6_tr|M3_6_tr|M2_6_tr|M_6_tr)&&(M_6))?110:(
		((M4_7_tr|M3_7_tr|M2_7_tr|M_7_tr)&&(M_7))?110:(
		((H4_1_tr|H3_1_tr|H2_1_tr|H_1_tr)&&(H_1))?110:(
		((H4_2_tr|H3_2_tr|H2_2_tr|H_2_tr)&&(H_2))?110:(
		((H4_3_tr|H3_3_tr|H2_3_tr|H_3_tr)&&(H_3))?110:(
		((H4_4_tr|H3_4_tr|H2_4_tr|H_4_tr)&&(H_4))?110:(	
		((H4_5_tr|H3_5_tr|H2_5_tr|H_5_tr)&&(H_5))?110:100
		))))))))))))))
	);	

////////White-key display//////				
	wire white_bar;
	bar_big b0(
		.org_x(x_org),
		.bar_space(white_bar),
		.org_y(key_y_offset),
		.y(CounterY),
		.x(CounterX),
		.line_y(white_y),
		.line_x(xdeta)
	);


////////Blank key/////////
	wire Hu4;
	wire Hu2;
	wire Hu1;
	wire Mu6;
	wire Mu5;
	wire Mu4;
	wire Mu2;
	wire Mu1;
	wire Lu6;
	wire Lu5;
	wire Lu4;
	bar_blank bar_blank1(
		.CounterX(CounterX),
		.Hu4(Hu4),
		.Hu2(Hu2),
		.Hu1(Hu1),
		.Mu6(Mu6),
		.Mu5(Mu5),
		.Mu4(Mu4),
		.Mu2(Mu2),
		.Mu1(Mu1),
		.Lu6(Lu6),
		.Lu5(Lu5),
		.Lu4(Lu4)
	);
	wire [11:0]bxdeta=30-8;

	wire [11:0]bxd_t =bxdeta+2;
	wire [11:0]bx_org=(
		(Lu4)?bxd_t*0:( //+5
		(Lu5)?bxd_t*1:( //+3
		(Lu6)?bxd_t*2:( //+2
		(Mu1)?bxd_t*4:( //7
		(Mu2)?bxd_t*5:( //6
		(Mu4)?bxd_t*7:( //5
		(Mu5)?bxd_t*8:( //3
		(Mu6)?bxd_t*9:(//2
		(Hu1)?bxd_t*11:(//-7
		(Hu2)?bxd_t*12:(//-6
		(Hu4)?bxd_t*14:bxd_t*14//-5
		))))))))))
		);
		
/////////Blank-key play////////
	wire [11:0] blank_y	=(
		((H4u4_tr|H3u4_tr|H2u4_tr|Hu4_tr)&&(Hu4))?60:(
		((H4u2_tr|H3u2_tr|H2u2_tr|Hu2_tr)&&(Hu2))?60:(		
		((H4u1_tr|H3u1_tr|H2u1_tr|Hu1_tr)&&(Hu1))?60:(		
		((M4u6_tr|M3u6_tr|M2u6_tr|Mu6_tr)&&(Mu6))?60:(		
		((M4u5_tr|M3u5_tr|M2u5_tr|Mu5_tr)&&(Mu5))?60:(		
		((M4u4_tr|M3u4_tr|M2u4_tr|Mu4_tr)&&(Mu4))?60:(		
		((M4u2_tr|M3u2_tr|M2u2_tr|Mu2_tr)&&(Mu2))?60:(		
		((M4u1_tr|M3u1_tr|M2u1_tr|Mu1_tr)&&(Mu1))?60:(		
		((L4u6_tr|L3u6_tr|L2u6_tr|Lu6_tr)&&(Lu6))?60:(		
		((L4u5_tr|L3u5_tr|L2u5_tr|Lu5_tr)&&(Lu5))?60:(		
		((L4u4_tr|L3u4_tr|L2u4_tr|Lu4_tr)&&(Lu4))?60:50
		))))))))))
	);	
			
////////Blank-key display//////
	wire blank_bar;
	bar_big b2(
		.org_x(bx_org),
		.bar_space(blank_bar),
		.org_y(key_y_offset),
		.x(CounterX),
		.y(CounterY),
		.line_y(blank_y),
		.line_x(xdeta)
	);
*/
	wire white;
	wire black;
	wire textbackg;
	wire textbackg2;
	wire slider_act;

	parameter org_x = 100;
	parameter org_y = 283;
	parameter line_x = 600;
	parameter line_y = 10;
	parameter s_line_x = 20;
//parameter s_org_x = 300;

	wire [11:0] s_org_x = org_x+ ((line_x * slide_val)>>7);
 
	wire slider=(
		(CounterX>=s_org_x) && (CounterX<=(s_org_x+s_line_x)) &&
		(CounterY>=org_y) && (CounterY<=(org_y+line_y)) 
	)?1:0;

	wire drag_space=(
		(CounterX>=org_x) && (CounterX<=(org_x+line_x)) &&
		(CounterY>=org_y) && (CounterY<=(org_y+line_y)) 
	)?1:0;



/////////VGA data out///////
// cursor //
	wire cur = (CounterX >= (chr_3 * 4*16) && CounterX < ((chr_3+1) *4*16)
					&& (CounterY >= lne *16) && (CounterY <= (lne +1)*16)) ? 1:0;

	wire marker = (CounterX >= (col * 4*16) && CounterX < ((col+1) *4*16)
					&& (CounterY >= row *16) && (CounterY <= (row +1)*16)) ? 1:0;

//	wire w_key 		=~blank_bar &  white_bar;
//	wire key_		= blank_bar |  white_bar;
//	assign	white = (drag_space | w_key) & inLcdDisplay;
//	assign 	black	= ~w_key & key_ & inLcdDisplay;
	assign	white = drag_space  & inLcdDisplay;
	assign 	black	= 1'b0;//~w_key & key_ & inLcdDisplay;
	assign	textbackg 	= intextarea  & inLcdDisplay;
	assign	textbackg2 	= intextarea2 & inLcdDisplay;
	assign	slider_act 	= slider & inLcdDisplay;
	assign color=(     // color of element text = 5, curser = 4, white key=3,black key=2,key=1,background=0;
		( black ) ? 9 :(
		( slider_act ) ? 8 :(
		( Char_ACT2 ) ? 7 :(
		( Char_ACT ) ? 6 :(
		( marker ) ? 5 :(
		( cur )? 4 :(
		( white )? 3 :(
		( textbackg2 )? 2:(
		( textbackg )?1:0
		))))))))
	);

endmodule
