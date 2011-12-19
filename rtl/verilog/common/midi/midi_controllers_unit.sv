module midi_controllers_unit (
	input iCLK,
	input iRST_n,
	input [17:0]SW,
// from midi_decoder
	input    		ctrl_cmd, 
	input  [7:0]	ctrl, 
	input  [7:0]	cur_data, 
	input  [7:0]	sysex_data[3], 
	input    		pitch_cmd,
	input    		sysex_cmd,
//	controller & status signals //	
	output [3:0]hex_disp[8],
	output [7:0]disp_data[64],
	output [7:0] o_index,
//	cpu signals //
	input 			N_adr_data_rdy,					// midi data ready from Nios
	input [8:0] N_adr,				// controller nr.
	output [7:0] N_synth_out_data,		// data byte
	input [7:0] N_synth_in_data,		// data byte
//	touch signals	 //
	input [7:0] slide_val,
	input [7:0] disp_val,
	input write_slide,
	
//		Controller Values		//
//	output reg signed[7:0] synth_data[64],
	output reg signed [7:0] env_buf[16][V_OSC],
	output reg signed [7:0] osc_buf[16][V_OSC],
//	output reg signed [7:0] mat_buf[16][V_OSC],
	output reg signed [7:0] mat_buf[32][V_OSC],
//	output reg signed [7:0] com_buf[16],
	output reg signed [7:0] com_buf[32],
	output reg [13:0]pitch_val = 8191,
	input N_save_sig,
	input N_load_sig
);

parameter 	VOICES;// Set in toplevel
parameter 	V_OSC; // oscs per Voice  // Set in toplevel
parameter V_WIDTH = utils::clogb2(VOICES);
parameter O_WIDTH = utils::clogb2(V_OSC);
parameter B_WIDTH = utils::clogb2(V_OSC)+3;

wire[7:0] midi_data[64];


////////	Ctrl registers  midi ctrl nr.   ////////
/*
parameter osc1_wf_nr = 3;
parameter osc1_ct_nr = 4;ctrl
parameter osc1_ft_nr = 5;
parameter osc1_lvl_nr = 6;
parameter osc1_mod_nr = 7;

parameter osc2_wf_nr = 8;
parameter osc2_ct_nr = 9;
parameter osc2_ft_nr = 10;
parameter osc2_lvl_nr = 11;
parameter osc2_mod_nr = 12;

// 		Mixer						//
parameter m_vol_nr = 13;

parameter osc1_feedb_nr = 14;
parameter osc2_feedb_nr = 15;

//		Pitch Bend					//

parameter pb_range_nr = 19;

//		Envelope     //

parameter r1_nr = 20; 
parameter l1_nr = 21;
parameter r2_nr = 22;
parameter l2_nr = 23;
parameter r3_nr = 24;
parameter l3_nr = 25;
parameter r4_nr = 26;
parameter l4_nr = 27;

parameter osc1_r1_nr = 28; 
parameter osc1_l1_nr = 29;
parameter osc1_r2_nr = 30;
parameter osc1_l2_nr = 31;
parameter osc1_r3_nr = 32;
parameter osc1_l3_nr = 33;
parameter osc1_r4_nr = 34;
parameter osc1_l4_nr = 35;

parameter osc2_r1_nr = 36; 
parameter osc2_l1_nr = 37;
parameter osc2_r2_nr = 38;
parameter osc2_l2_nr = 39;
parameter osc2_r3_nr = 40;
parameter osc2_l3_nr = 41;
parameter osc2_r4_nr = 42;
parameter osc2_l4_nr = 43;

parameter fb_r1_nr = 44; 
parameter fb_l1_nr = 45;
parameter fb_r2_nr = 46;
parameter fb_l2_nr = 47;
parameter fb_r3_nr = 48;
parameter fb_l3_nr = 49;
parameter fb_r4_nr = 50;
parameter fb_l4_nr = 51;

// 		Osc					//

parameter b_ct1_nr = 52;
parameter b_ft1_nr = 53;
parameter b_ct2_nr = 54;
parameter b_ft2_nr = 55;

parameter k_scale1 = 56;
parameter k_scale2 = 57;

parameter o_offset1 = 58;
parameter o_offset2 = 59;

/// Test
parameter mod_shift_nr = 16;
*/
/*
/////////////////////////////////////
// 0 -- b000
assign disp_data[0] = (!SW[16]) ? (env_buf[7'h00]):(synth_data[16]);// r[0][0]
assign disp_data[1] = (!SW[16]) ? (env_buf[7'h04]):(synth_data[0]);// l[0][0]					
assign disp_data[2] = (!SW[16]) ? (env_buf[7'h01]):(synth_data[17]);//r[0][1]		
assign disp_data[3] = (!SW[16]) ? (env_buf[7'h05]):(synth_data[1]);//l[0][1]					
assign disp_data[4] = (!SW[16]) ? (env_buf[7'h02]):(synth_data[18]);//r[0][2]					
assign disp_data[5] = (!SW[16]) ? (env_buf[7'h06]):(synth_data[2]);//l[0][2]					
assign disp_data[6] = (!SW[16]) ? (env_buf[7'h03]):(synth_data[19]);					
assign disp_data[7] = (!SW[16]) ? (env_buf[7'h07]):(synth_data[3]);					
// 1 -- b001
assign disp_data[8] = (!SW[16]) ? (env_buf[7'h10]):(synth_data[20]);
assign disp_data[9] = (!SW[16]) ? (env_buf[7'h14]):(synth_data[4]);					
assign disp_data[10] = (!SW[16]) ? (env_buf[7'h11]):(synth_data[21]);					
assign disp_data[11] = (!SW[16]) ? (env_buf[7'h15]):(synth_data[5]);					
assign disp_data[12] = (!SW[16]) ? (env_buf[7'h12]):(synth_data[22]);					
assign disp_data[13] = (!SW[16]) ? (env_buf[7'h16]):(synth_data[6]);					
assign disp_data[14] = (!SW[16]) ? (env_buf[7'h13]):(synth_data[23]);					
assign disp_data[15] = (!SW[16]) ? (env_buf[7'h17]):(synth_data[7]);					
// 2 -- b010
assign disp_data[16] = (!SW[16]) ? (env_buf[7'h08]):(synth_data[24]);					
assign disp_data[17] = (!SW[16]) ? (env_buf[7'h0C]):(synth_data[8]);					
assign disp_data[18] = (!SW[16]) ? (env_buf[7'h09]):(synth_data[25]);					
assign disp_data[19] = (!SW[16]) ? (env_buf[7'h0D]):(synth_data[9]);					
assign disp_data[20] = (!SW[16]) ? (env_buf[7'h0A]):(synth_data[26]);					
assign disp_data[21] = (!SW[16]) ? (env_buf[7'h0E]):(synth_data[10]);					
assign disp_data[22] = (!SW[16]) ? (env_buf[7'h0B]):(synth_data[27]);					
assign disp_data[23] = (!SW[16]) ? (env_buf[7'h0F]):(synth_data[11]);					
// 3 -- b011
assign disp_data[24] = (!SW[16]) ? (env_buf[7'h18]):(synth_data[28]);					
assign disp_data[25] = (!SW[16]) ? (env_buf[7'h1C]):(synth_data[12]);					
assign disp_data[26] = (!SW[16]) ? (env_buf[7'h19]):(synth_data[29]);					
assign disp_data[27] = (!SW[16]) ? (env_buf[7'h1D]):(synth_data[13]);					
assign disp_data[28] = (!SW[16]) ? (env_buf[7'h1A]):(synth_data[30]);					
assign disp_data[29] = (!SW[16]) ? (env_buf[7'h1E]):(synth_data[14]);					
assign disp_data[30] = (!SW[16]) ? (env_buf[7'hB]):(synth_data[31]);					
assign disp_data[31] = (!SW[16]) ? (env_buf[7'h1F]):(synth_data[15]);					
// 3 -- b100
assign disp_data[32] = (!SW[16]) ? (osc_buf[7'h00]):(synth_data[33]);					
assign disp_data[33] = (!SW[16]) ? (osc_buf[7'h01]):(synth_data[35]);					
assign disp_data[34] = (!SW[16]) ? (osc_buf[7'h02]):(synth_data[36]);					
assign disp_data[35] = (!SW[16]) ? (osc_buf[7'h03]):(synth_data[38]);					
assign disp_data[36] = (!SW[16]) ? (osc_buf[7'h04]):(synth_data[44]);
assign disp_data[37] = (!SW[16]) ? (osc_buf[7'h05]):(synth_data[47]);
assign disp_data[38] = (!SW[16]) ? (osc_buf[7'h06]):(synth_data[49]);
assign disp_data[39] = (!SW[16]) ? (osc_buf[7'h07]):(synth_data[41]);					
// 4 -- b101					
assign disp_data[40] = (!SW[16]) ? (osc_buf[7'h08]):(synth_data[43]);					
assign disp_data[41] = (!SW[16]) ? (com_buf[4'h0]):(synth_data[50]);					
assign disp_data[42] = (!SW[16]) ? (com_buf[4'h1]):(synth_data[51]);					
// 5 -- b110
assign disp_data[48] = (!SW[16]) ? (osc_buf[7'h10]):(synth_data[32]);					
assign disp_data[49] = (!SW[16]) ? (osc_buf[7'h11]):(synth_data[34]);					
assign disp_data[50] = (!SW[16]) ? (osc_buf[7'h12]):(synth_data[37]);					
assign disp_data[51] = (!SW[16]) ? (osc_buf[7'h13]):(synth_data[39]);					
assign disp_data[52] = (!SW[16]) ? (osc_buf[7'h14]):(synth_data[45]);
assign disp_data[53] = (!SW[16]) ? (osc_buf[7'h15]):(synth_data[46]);
assign disp_data[54] = (!SW[16]) ? (osc_buf[7'h16]):(synth_data[48]);
assign disp_data[55] = (!SW[16]) ? (osc_buf[7'h17]):(synth_data[40]);					
// 6 -- b111					
assign disp_data[56] = (!SW[16]) ? (osc_buf[7'h18]):(synth_data[42]);					
// ----------            --------------------        //
*/
/////////////////////////////////////
// 0 -- b000

assign disp_data[0] = (!SW[16]) ? (env_buf[4'h0][0]):(8'h00);// r[0][0]
assign disp_data[1] = (!SW[16]) ? (env_buf[4'h4][0]):(8'h00);// l[0][0]					
assign disp_data[2] = (!SW[16]) ? (env_buf[4'h1][0]):(8'h00);//r[0][1]		
assign disp_data[3] = (!SW[16]) ? (env_buf[4'h5][0]):(8'h00);//l[0][1]					
assign disp_data[4] = (!SW[16]) ? (env_buf[4'h2][0]):(8'h00);//r[0][2]					
assign disp_data[5] = (!SW[16]) ? (env_buf[4'h6][0]):(8'h00);//l[0][2]					
assign disp_data[6] = (!SW[16]) ? (env_buf[4'h3][0]):(8'h00);					
assign disp_data[7] = (!SW[16]) ? (env_buf[4'h7][0]):(8'h00);					
// 1 -- b001
assign disp_data[8] = (!SW[16]) ? (env_buf[4'h0][1]):(8'h00);
assign disp_data[9] = (!SW[16]) ? (env_buf[4'h4][1]):(8'h00);					
assign disp_data[10] = (!SW[16]) ? (env_buf[4'h1][1]):(8'h00);					
assign disp_data[11] = (!SW[16]) ? (env_buf[4'h5][1]):(8'h00);					
assign disp_data[12] = (!SW[16]) ? (env_buf[4'h2][1]):(8'h00);					
assign disp_data[13] = (!SW[16]) ? (env_buf[4'h6][1]):(8'h00);					
assign disp_data[14] = (!SW[16]) ? (env_buf[4'h3][1]):(8'h00);					
assign disp_data[15] = (!SW[16]) ? (env_buf[4'h7][1]):(8'h00);					
/*
// 2 -- b010
assign disp_data[16] = (!SW[16]) ? (env_buf[4'h8][0]):(8'h00);					
assign disp_data[17] = (!SW[16]) ? (env_buf[4'hC][0]):(8'h00);					
assign disp_data[18] = (!SW[16]) ? (env_buf[4'h9][0]):(8'h00);					
assign disp_data[19] = (!SW[16]) ? (env_buf[4'hD][0]):(8'h00);					
assign disp_data[20] = (!SW[16]) ? (env_buf[4'hA][0]):(8'h00);					
assign disp_data[21] = (!SW[16]) ? (env_buf[4'hE][0]):(8'h00);					
assign disp_data[22] = (!SW[16]) ? (env_buf[4'hB][0]):(8'h00);					
assign disp_data[23] = (!SW[16]) ? (env_buf[4'hF][0]):(8'h00);					
// 3 -- b011
assign disp_data[24] = (!SW[16]) ? (env_buf[4'h8][1]):(8'h00);					
assign disp_data[25] = (!SW[16]) ? (env_buf[4'hC][1]):(8'h00);					
assign disp_data[26] = (!SW[16]) ? (env_buf[4'h9][1]):(8'h00);					
assign disp_data[27] = (!SW[16]) ? (env_buf[4'hD][1]):(8'h00);					
assign disp_data[28] = (!SW[16]) ? (env_buf[4'hA][1]):(8'h00);					
assign disp_data[29] = (!SW[16]) ? (env_buf[4'hE][1]):(8'h00);					
assign disp_data[30] = (!SW[16]) ? (env_buf[7'hB][1]):(8'h00);					
assign disp_data[31] = (!SW[16]) ? (env_buf[4'hF][1]):(8'h00);					
// 2 -- b010
*/
assign disp_data[16] = (!SW[16]) ? (env_buf[4'h0][2]):(8'h00);					
assign disp_data[17] = (!SW[16]) ? (env_buf[4'h4][2]):(8'h00);					
assign disp_data[18] = (!SW[16]) ? (env_buf[4'h1][2]):(8'h00);					
assign disp_data[19] = (!SW[16]) ? (env_buf[4'h5][2]):(8'h00);					
assign disp_data[20] = (!SW[16]) ? (env_buf[4'h2][2]):(8'h00);					
assign disp_data[21] = (!SW[16]) ? (env_buf[4'h6][2]):(8'h00);					
assign disp_data[22] = (!SW[16]) ? (env_buf[4'h3][2]):(8'h00);					
assign disp_data[23] = (!SW[16]) ? (env_buf[4'h7][2]):(8'h00);					
// 3 -- b011
assign disp_data[24] = (!SW[16]) ? (env_buf[4'h0][3]):(8'h00);					
assign disp_data[25] = (!SW[16]) ? (env_buf[4'h4][3]):(8'h00);					
assign disp_data[26] = (!SW[16]) ? (env_buf[4'h1][3]):(8'h00);					
assign disp_data[27] = (!SW[16]) ? (env_buf[4'h5][3]):(8'h00);					
assign disp_data[28] = (!SW[16]) ? (env_buf[4'h2][3]):(8'h00);					
assign disp_data[29] = (!SW[16]) ? (env_buf[4'h6][3]):(8'h00);					
assign disp_data[30] = (!SW[16]) ? (env_buf[7'h3][3]):(8'h00);					
assign disp_data[31] = (!SW[16]) ? (env_buf[4'h7][3]):(8'h00);					
// 3 -- b100
assign disp_data[32] = (!SW[16]) ? (osc_buf[4'h0][0]):(8'h00);					
assign disp_data[33] = (!SW[16]) ? (osc_buf[4'h1][0]):(8'h00);					
assign disp_data[34] = (!SW[16]) ? (osc_buf[4'h2][0]):(8'h00);					
assign disp_data[35] = (!SW[16]) ? (osc_buf[4'h3][0]):(8'h00);					
assign disp_data[36] = (!SW[16]) ? (osc_buf[4'h4][0]):(8'h00);
assign disp_data[37] = (!SW[16]) ? (osc_buf[4'h5][0]):(8'h00);
assign disp_data[38] = (!SW[16]) ? (osc_buf[4'h6][0]):(8'h00);
assign disp_data[39] = (!SW[16]) ? (osc_buf[4'h7][0]):(8'h00);					
// 4 -- b101					
assign disp_data[40] = (!SW[16]) ? (osc_buf[4'h8][0]):(8'h00);					
assign disp_data[41] = (!SW[16]) ? (com_buf[4'h0]):(8'h00);					
assign disp_data[42] = (!SW[16]) ? (com_buf[4'h1]):(8'h00);					
// 5 -- b110
assign disp_data[48] = (!SW[16]) ? (osc_buf[4'h0][1]):(8'h00);					
assign disp_data[49] = (!SW[16]) ? (osc_buf[4'h1][1]):(8'h00);					
assign disp_data[50] = (!SW[16]) ? (osc_buf[4'h2][1]):(8'h00);					
assign disp_data[51] = (!SW[16]) ? (osc_buf[4'h3][1]):(8'h00);					
assign disp_data[52] = (!SW[16]) ? (osc_buf[4'h4][1]):(8'h00);
assign disp_data[53] = (!SW[16]) ? (osc_buf[4'h5][1]):(8'h00);
assign disp_data[54] = (!SW[16]) ? (osc_buf[4'h6][1]):(8'h00);
assign disp_data[55] = (!SW[16]) ? (osc_buf[4'h7][1]):(8'h00);					
// 6 -- b111					
assign disp_data[56] = (!SW[16]) ? (osc_buf[4'h8][1]):(8'h00);					
// ----------            --------------------        //


assign midi_data[0] = env_buf[4'h0][0];// r[0][0]
assign midi_data[1] = env_buf[4'h4][0];// l[0][0]					
assign midi_data[2] = env_buf[4'h1][0];//r[0][1]		
assign midi_data[3] = env_buf[4'h5][0];//l[0][1]					
assign midi_data[4] = env_buf[4'h2][0];//r[0][2]					
assign midi_data[5] = env_buf[4'h6][0];//l[0][2]					
assign midi_data[6] = env_buf[4'h3][0];					
assign midi_data[7] = env_buf[4'h7][0];					
// 1 -- b001
assign midi_data[8] = env_buf[4'h0][1];
assign midi_data[9] = env_buf[4'h4][1];					
assign midi_data[10] = env_buf[4'h1][1];					
assign midi_data[11] = env_buf[4'h5][1];					
assign midi_data[12] = env_buf[4'h2][1];					
assign midi_data[13] = env_buf[4'h6][1];					
assign midi_data[14] = env_buf[4'h3][1];					
assign midi_data[15] = env_buf[4'h7][1];					
// 2 -- b010
assign midi_data[16] = env_buf[4'h8][0];					
assign midi_data[17] = env_buf[4'hC][0];					
assign midi_data[18] = env_buf[4'h9][0];					
assign midi_data[19] = env_buf[4'hD][0];					
assign midi_data[20] = env_buf[4'hA][0];					
assign midi_data[21] = env_buf[4'hE][0];					
assign midi_data[22] = env_buf[4'hB][0];					
assign midi_data[23] = env_buf[4'hF][0];					
// 3 -- b011
assign midi_data[24] = env_buf[4'h8][1];					
assign midi_data[25] = env_buf[4'hC][1];					
assign midi_data[26] = env_buf[4'h9][1];					
assign midi_data[27] = env_buf[4'hD][1];					
assign midi_data[28] = env_buf[4'hA][1];					
assign midi_data[29] = env_buf[4'hE][1];					
assign midi_data[30] = env_buf[7'hB][1];					
assign midi_data[31] = env_buf[4'hF][1];					
// 3 -- b100
assign midi_data[32] = osc_buf[4'h0][0];					
assign midi_data[33] = osc_buf[4'h1][0];					
assign midi_data[34] = osc_buf[4'h2][0];					
assign midi_data[35] = osc_buf[4'h3][0];					
assign midi_data[36] = osc_buf[4'h4][0];
assign midi_data[37] = osc_buf[4'h5][0];
assign midi_data[38] = osc_buf[4'h6][0];
assign midi_data[39] = osc_buf[4'h7][0];					
// 4 -- b101					
assign midi_data[40] = osc_buf[4'h8][0];					
assign midi_data[41] = com_buf[4'h0];					
assign midi_data[42] = com_buf[4'h1];					
// 5 -- b110
assign midi_data[48] = osc_buf[4'h0][1];					
assign midi_data[49] = osc_buf[4'h1][1];					
assign midi_data[50] = osc_buf[4'h2][1];					
assign midi_data[51] = osc_buf[4'h3][1];					
assign midi_data[52] = osc_buf[4'h4][1];
assign midi_data[53] = osc_buf[4'h5][1];
assign midi_data[54] = osc_buf[4'h6][1];
assign midi_data[55] = osc_buf[4'h7][1];					
// 6 -- b111					
assign midi_data[56] = osc_buf[4'h8][1];					
// ----------            --------------------        //

/////////////	Fetch Controllers			/////////////
// 		Internal				//
	reg [7:0]cur_ctrl;
//	reg [7:0]cur_data;
	reg pitch_cmd_r;
	reg ctrl_cmd_r;
	reg sysex_cmd_r;
	reg [6:0]pitch_lsb;

	reg [7:0] pb_value;
	reg [7:0]r[2*V_OSC][3:0];//  2 extra values for feedback + ?
	reg signed [7:0]l[2*V_OSC][3:0];// 2 extra values for feedback + ?
	reg[7:0]osc_ct[V_OSC];  
	reg[7:0]osc_ft[V_OSC];  
	reg[7:0]base_ct[V_OSC]; // base freq coarse 
	reg[7:0]base_ft[V_OSC]; // base freq fine 
	reg[7:0]k_scale[V_OSC];
	reg[7:0]o_offs[V_OSC];
	reg signed[7:0]osc_lvl[V_OSC]; 
	reg signed[7:0]osc_mod[V_OSC]; 
	reg signed[7:0]m_vol;
	reg signed[7:0]osc_feedb[V_OSC]; 

	assign o_index = com_buf[4];
	wire[3:0]osc_inx = o_index[3:0];
	
	reg N_adr_data_rdy_r, N_load_sig_r, N_save_sig_r, write_slide_r; 
	reg [7:0] N_synth_in_data_r, s_adr_1,c_adr_1, s_adr_0, c_adr_0, s_dat_val, slide_val_r, data;
	reg [7:0] c_adr_1_r, c_adr_0_r;
	reg [8:0] N_adr_r;
	reg [7:0] disp_val_r;
	wire [O_WIDTH:0]a1;
	always @(posedge iCLK)begin
		ctrl_cmd_r <= ctrl_cmd;
		sysex_cmd_r <= sysex_cmd;
		pitch_cmd_r <= pitch_cmd;
		N_adr_data_rdy_r <= N_adr_data_rdy;
		N_synth_in_data_r <= N_synth_in_data;
		N_adr_r <= N_adr;
		N_load_sig_r <= N_load_sig;
		N_save_sig_r <= N_save_sig;
		write_slide_r <= write_slide;
		slide_val_r <= slide_val;
		s_adr_1 <= sysex_data[0];
		s_adr_0 <= sysex_data[1];
		s_dat_val <= sysex_data[2];
		disp_val_r <= disp_val;
		c_adr_1_r <= c_adr_1;
		c_adr_0_r <= c_adr_0;
//		data <= cur_data;
	end

	always @(posedge ctrl_cmd_r) cur_ctrl <= ctrl;

	always @(negedge ctrl_cmd_r) begin
			if(cur_ctrl == 46) begin c_adr_1 <= cur_data; end
			else if(cur_ctrl == 47) begin c_adr_0 <= cur_data; end
	end
	always @(posedge pitch_cmd_r)	pitch_lsb <= ctrl[6:0];

	always @(negedge pitch_cmd_r)	pitch_val <= {cur_data[6:0],pitch_lsb};

//	always @(negedge iRST_n	or posedge write_slide_r or posedge N_adr_data_rdy_r
//	always @(negedge iRST_n	or posedge N_adr_data_rdy_r
//			or posedge sysex_cmd_r )begin
	always @(negedge iRST_n
//			or posedge sysex_cmd_r or posedge write_slide_r)begin
			or posedge sysex_cmd_r or posedge write_slide or negedge ctrl_cmd_r)begin
		if (!iRST_n) begin 		
			for(a1=0;a1<V_OSC;a1++)begin
				env_buf[4'h0][a1] <= 8'h00;
				env_buf[4'h1][a1] <= 8'h00;
				env_buf[4'h2][a1] <= 8'h00;
				env_buf[4'h3][a1] <= 8'h00;
				env_buf[4'h4][a1] <= 8'h00;
				env_buf[4'h5][a1] <= 8'h00;
				env_buf[4'h6][a1] <= 8'h7f;
				env_buf[4'h7][a1] <= 8'h00;
				env_buf[4'h8][a1] <= 8'h00;
				env_buf[4'h9][a1] <= 8'h00;
				env_buf[4'hA][a1] <= 8'h00;
				env_buf[4'hB][a1] <= 8'h00;
				env_buf[4'hC][a1] <= 8'h00;
				env_buf[4'hD][a1] <= 8'h00;
				env_buf[4'hF][a1] <= 8'h00;		

				osc_buf[4'h0][a1] <= 8'h40;
				osc_buf[4'h1][a1] <= 8'h40;
				osc_buf[4'h2][a1] <= 8'h7f;
				osc_buf[4'h3][a1] <= 8'h00;
				osc_buf[4'h4][a1] <= 8'h00;
				osc_buf[4'h5][a1] <= 8'h00;
				osc_buf[4'h6][a1] <= 8'h00;
				osc_buf[4'h7][a1] <= 8'h40;
				osc_buf[4'h8][a1] <= 8'h40;
				osc_buf[4'h9][a1] <= 8'h00;
				osc_buf[4'hA][a1] <= 8'h00;
				osc_buf[4'hB][a1] <= 8'h00;
				osc_buf[4'hC][a1] <= 8'h00;
				osc_buf[4'hD][a1] <= 8'h00;
				osc_buf[4'hE][a1] <= 8'h00;
				osc_buf[4'hF][a1] <= 8'h00;

				mat_buf[4'h0][a1] <= 8'h00;
				mat_buf[4'h1][a1] <= 8'h00;
				mat_buf[4'h2][a1] <= 8'h00;
				mat_buf[4'h3][a1] <= 8'h00;
				mat_buf[4'h4][a1] <= 8'h00;
				mat_buf[4'h5][a1] <= 8'h00;
				mat_buf[4'h6][a1] <= 8'h00;
				mat_buf[4'h7][a1] <= 8'h00;
				mat_buf[4'h8][a1] <= 8'h00;
				mat_buf[4'h9][a1] <= 8'h00;
				mat_buf[4'hA][a1] <= 8'h00;
				mat_buf[4'hB][a1] <= 8'h00;
				mat_buf[4'hC][a1] <= 8'h00;
				mat_buf[4'hD][a1] <= 8'h00;
				mat_buf[4'hE][a1] <= 8'h00;
				mat_buf[4'hF][a1] <= 8'h00;
			end
			com_buf[4'h0] <= 8'h01;
			com_buf[4'h1] <= 8'd60;
			com_buf[4'h2] <= 8'h00;
			com_buf[4'h3] <= 8'h00;
			com_buf[4'h4] <= 8'h00;
			com_buf[4'h5] <= 8'h00;
			com_buf[4'h6] <= 8'h00;
			com_buf[4'h7] <= 8'h00;
			com_buf[4'h8] <= 8'h00;
			com_buf[4'h9] <= 8'h00;
			com_buf[4'hA] <= 8'h00;
			com_buf[4'hB] <= 8'h00;
			com_buf[4'hC] <= 8'h00;
			com_buf[4'hD] <= 8'h00;
			com_buf[4'hE] <= 8'h00;
			com_buf[4'hF] <= 8'h00;
		end	
/*		else if(write_slide_r)begin 
				case(disp_val_r[8:7])
					2'b00:	env_buf[disp_val_r[3:0]][disp_val_r[B_WIDTH:4]] <= slide_val_r;	
					2'b01:	osc_buf[disp_val_r[3:0]][disp_val_r[B_WIDTH:4]] <= slide_val_r;	
					2'b10:	com_buf[disp_val_r[3:0]] <= slide_val_r;	
					default:;
				endcase
		end	
*/
		else if(write_slide)begin 
			midi_data[disp_val] <= slide_val;
		end
		else if (sysex_cmd_r) begin
			case(s_adr_1)
				8'h00:	env_buf[s_adr_0[3:0]][s_adr_0[B_WIDTH:4]+osc_inx] <= s_dat_val;
				8'h01:	osc_buf[s_adr_0[3:0]][s_adr_0[B_WIDTH:4]+osc_inx] <= s_dat_val;
				8'h02:	mat_buf[s_adr_0[3:0]][s_adr_0[B_WIDTH:4]+osc_inx] <= s_dat_val;
				8'h03:	mat_buf[(s_adr_0[3:0]+16)][s_adr_0[B_WIDTH:4]+osc_inx] <= s_dat_val;
				8'h04:	com_buf[s_adr_0[3:0]] <= s_dat_val;
				default:; 
			endcase
		end	
		else if (!ctrl_cmd_r) begin
			case(c_adr_1_r)
				8'h00:	env_buf[c_adr_0_r[3:0]][c_adr_0_r[B_WIDTH:4]+osc_inx] <= cur_data;
				8'h01:	osc_buf[c_adr_0_r[3:0]][c_adr_0_r[B_WIDTH:4]+osc_inx] <= cur_data;
				8'h02:	mat_buf[c_adr_0_r[3:0]][c_adr_0_r[B_WIDTH:4]+osc_inx] <= cur_data;
				8'h03:	mat_buf[(c_adr_0_r[3:0]+16)][c_adr_0_r[B_WIDTH:4]+osc_inx] <= cur_data;
				8'h04:	com_buf[c_adr_0_r[3:0]] <= cur_data;
				default:; 
			endcase
		end	

/*		else if(N_adr_data_rdy_r)begin
			if(N_load_sig_r)begin
				case(N_adr_r[8:7])
					2'b00:	env_buf[N_adr_r[3:0]][N_adr_r[B_WIDTH:4]] <= N_synth_in_data_r;	
					2'b01:	osc_buf[N_adr_r[3:0]][N_adr_r[B_WIDTH:4]] <= N_synth_in_data_r;	
					2'b10:	com_buf[N_adr_r[3:0]] <= N_synth_in_data_r;	
					default:;
				endcase
			end
		end
*/	end
/*
	always @(posedge N_adr_data_rdy_r)begin
//	if(N_adr_data_rdy_r)begin
		if(N_save_sig_r)begin
			case(N_adr_r[8:7])
				2'b00:	N_synth_out_data <= env_buf[N_adr_r[3:0]][N_adr_r[B_WIDTH:4]];	
				2'b01:	N_synth_out_data <= osc_buf[N_adr_r[3:0]][N_adr_r[B_WIDTH:4]];	
				2'b10:	N_synth_out_data <= com_buf[N_adr_r[3:0]];	
				default:;
			endcase
		end
		else N_synth_out_data <= 8'h00;	
//		end	
	end
*/	
		


endmodule
