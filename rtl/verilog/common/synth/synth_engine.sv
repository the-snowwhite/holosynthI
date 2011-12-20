module synth_engine (
	input			tCLK_271_4285,
	input			iCLK_16_9,
	input 		iRST_N,
	output			oAUD_DATA,
	output			oAUD_LRCK,
	output	reg		oAUD_BCK,
// buttons & switches	
	input   [17:0]	switch,
	input   [4:1]	button,
// -- Sound control -- //
	input   			clock_25,
	input   			sys_clk,
// from midi_decoder
	input  key_on[VOICES],
	input [7:0]	key_val[VOICES],
	input [7:0] vel_on[VOICES],
// from midi_controller_unit
	input signed [7:0] env_buf[16][V_OSC],
	input signed [7:0] osc_buf[16][V_OSC],
	input signed [7:0] mat_buf[32][V_OSC],
	input signed [7:0] com_buf[32],
	input [13:0] pitch_val,
// from env gen
	output reg voice_free[VOICES]
	);	

parameter	AUDIO_CLK		=	271428571;	//	271.428571 MHz
parameter	REF_CLK			=	16964286;	//	16.964286	MHz
parameter	SAMPLE_RATE		=	44110;		//	48		KHz
parameter	DATA_WIDTH		=	16;			//	16		Bits
parameter	CHANNEL_NUM		=	2;			//	Dual Channel


parameter 	VOICES;
parameter 	V_OSC; // oscs per Voice
parameter 	V_ENVS; // envs per Voice
parameter V_WIDTH = utils::clogb2(VOICES);
parameter O_WIDTH = utils::clogb2(V_OSC);
parameter E_WIDTH = utils::clogb2(V_ENVS);

//-----		Wires		-----//
	
//---	Env gen	---//
	wire 	[V_WIDTH-1:0]e_voice_sel;
	wire	[E_WIDTH-1:0]e_env_sel; // 2 env's 
	wire signed [7:0]level_mul;

//---	CLK Generator	---//

//wire	LRCK_1X;
//wire	LRCK_8X;
//wire	sCLK_XV;
//wire	sCLK_2XV;
wire	sCLK_XVXOSC;
wire	sCLK_XVXENVS;
	


wire [7:0]active_keys;
wire [7:0]off_note_error;


reg		[3:0]	SEL_Cont;

////////////	AUD_CLK Generator	//////////////

synth_clk_gen #(.VOICES(VOICES),.V_OSC(V_OSC),.V_ENVS(V_ENVS)) synth_clk_gen_inst
(
	.iRST_N(iRST_N) ,	// input  iRST_N_sig
	.tCLK(tCLK_271_4285) ,	// input  tclk_sig
	.iCLK_16_9(iCLK_16_9) ,	// input  iCLK_16_9_sig
	.LRCK_1X(oAUD_LRCK) ,	// output  LRCK_1X_sig
//	.LRCK_8X(LRCK_8X) ,	// output  LRCK_8X_sig
//	.sCLK_XV(sCLK_XV) ,	// output  sCLK_XV_sig
//	.sCLK_2XV(sCLK_2XV) ,	// output  sCLK_2XV_sig
	.sCLK_XVXOSC(sCLK_XVXOSC) ,	// output  sCLK_XVXOSC_sig
	.sCLK_XVXENVS(sCLK_XVXENVS) ,	// output  sCLK_2XVXOSC_sig
	.oAUD_BCK(oAUD_BCK) 	// output  oAUD_BCK_sig
);


////////////		SoundOut		///////////////
	reg signed [15:0]sound_o;
	wire signed [15:0]rsound_o;
	always@(negedge oAUD_BCK or negedge iRST_N)begin
		if(!iRST_N)
			SEL_Cont	<=	0;
		else begin
			SEL_Cont	<=	SEL_Cont+1;
			if(SEL_Cont == 4'hf) sound_o <= rsound_o;
		end
	end

	assign	oAUD_DATA	=	sound_o[~SEL_Cont];

////////// Reg Inputs //////////////
	wire [V_WIDTH:0] v1;
	wire [O_WIDTH:0] o1,oi1;
	
	wire rkey_on[VOICES];	
	reg [7:0]rkey_val[VOICES];
	wire	xxxx_max;
	
	reg r_xxxx_max;	
	always @(negedge sCLK_XVXENVS)begin 
		r_xxxx_max <= xxxx_max;
	end
	wire[7:0] vfi;
	wire [4:0]aaa;
	always @(posedge r_xxxx_max)begin 
		rkey_val <= l_key_val;
		rkey_on <= key_on;
	end

	reg l_key_on[VOICES];
	reg [7:0]l_key_val[VOICES];
	
	always @(posedge tCLK_271_4285)begin 
		for(v1=0;v1<VOICES;v1++) 
			l_key_on[v1] <= key_on[v1];	
	end
	
	generate
	genvar aa1,bb1;
		for(aa1=0;aa1<VOICES;aa1++)begin : key_reg 
			always @(posedge l_key_on[aa1])begin 
				l_key_val[aa1] <= key_val[aa1];
			end
			for(bb1=0;bb1<V_OSC;bb1++)begin : vfree_reg
				assign voice_free_r2[aa1][bb1] = voice_free[aa1];
			end
		end
	endgenerate	

////////////////          Midi Msg I/O Controller 		////////////////
wire   [7:0]	cur_data; 


reg [7:0]free_voices;
reg [7:0]active_notes;
wire [7:0]voice_free_r2[VOICES][V_OSC];

////////////////          Pitch & Volume control 		////////////////
	
	wire signed [23:0]osc_index_val[VOICES][V_OSC];
	wire	[V_WIDTH-1:0]osc_voice_index;	
	wire signed [10:0]modulation[V_OSC][VOICES];

	pitch_control #(.VOICES(VOICES),.V_OSC(V_OSC),.V_WIDTH(V_WIDTH),.O_WIDTH(O_WIDTH)) pitch1(
		.iRST_N(iRST_N) ,	// input  iRST_N_sig
		.clk ( sCLK_XVXENVS ),
		.rkey( rkey_val ),
		.osc_ct( osc_buf[0]  ),// osc_ct
		.osc_ft( osc_buf[1] ),// osc_ft
		.b_ct ( osc_buf[7] ),// base_ct
		.b_ft ( osc_buf[8] ),// base_ft
		.pb_value( com_buf[0] ),// pb_value
		.pitch_val( pitch_val ),
		.k_scale ( osc_buf[5] ),// k_scale
		.switch( switch ),
		.osc_index_val( osc_index_val )// output
	);

	wire signed [16:0]sine_lut_out[V_OSC];

	osc #(.VOICES(VOICES),.V_OSC(V_OSC),.V_WIDTH(V_WIDTH),.O_WIDTH(O_WIDTH)) osc12(
		.iRST_N(iRST_N) ,	// input  iRST_N_sig
		.tCLK( tCLK_271_4285 ),
		.sCLK_XVXENVS( sCLK_XVXENVS ),
		.sCLK_XVXOSC( sCLK_XVXOSC ),
		.pitch( osc_index_val ),
		.modulation( modulation ),
		.o_offs ( osc_buf[6] ),// o_offs
		.index( osc_voice_index ),
		.waveform(  ),
		.voice_free (voice_free_r2),
		.sine_lookup_output( sine_lut_out )
	);

	mixer #(.VOICES(VOICES),.V_OSC(V_OSC),.V_ENVS(V_ENVS)) vol_mixer (
		.sCLK_XVXENVS(sCLK_XVXENVS) ,	// input  clk_sig
		.iRST_N(iRST_N) ,	// input  iRST_N_sig
    	.switch	  ( switch ),			//input			
		.level_mul(level_mul), 	// output [7:0] level_mul_sig
		.osc_lvl( osc_buf[2] ) ,	// input  rate 0:3 // r
		.osc_mod( osc_buf[3] ) ,	// input level 0:3 // l
		.osc_feedb(osc_buf[4]) ,	// input  key_on_sig
		.m_vol ( com_buf[1] ),
		.mat_buf ( mat_buf ),
		.sine_lut_out ( sine_lut_out ),
		.xxxx_max ( xxxx_max ),
		.e_env_sel(e_env_sel),
		.e_voice_sel(e_voice_sel),
		.osc_voice_index(osc_voice_index),	// output
		.modulation(modulation),	// output
		.rsound_o(rsound_o)	// output
	);

	wire signed [7:0]r_r[V_ENVS][3:0];
	wire signed [7:0]l_r[V_ENVS][3:0];
	generate genvar e_inx;
		for(e_inx=0;e_inx<V_ENVS;e_inx=e_inx+2)begin : e_val_cnv
			assign l_r[e_inx+1][3] = env_buf[4'hF][e_inx>>1];
			assign l_r[e_inx+1][2] = env_buf[4'hE][e_inx>>1];
			assign l_r[e_inx+1][1] = env_buf[4'hD][e_inx>>1];
			assign l_r[e_inx+1][0] = env_buf[4'hC][e_inx>>1];
			assign r_r[e_inx+1][3] = env_buf[4'hB][e_inx>>1];
			assign r_r[e_inx+1][2] = env_buf[4'hA][e_inx>>1];
			assign r_r[e_inx+1][1] = env_buf[4'h9][e_inx>>1];
			assign r_r[e_inx+1][0] = env_buf[4'h8][e_inx>>1];

			assign l_r[e_inx][3] = env_buf[4'h7][e_inx>>1];
			assign l_r[e_inx][2] = env_buf[4'h6][e_inx>>1];
			assign l_r[e_inx][1] = env_buf[4'h5][e_inx>>1];
			assign l_r[e_inx][0] = env_buf[4'h4][e_inx>>1];
			assign r_r[e_inx][3] = env_buf[4'h3][e_inx>>1];
			assign r_r[e_inx][2] = env_buf[4'h2][e_inx>>1];
			assign r_r[e_inx][1] = env_buf[4'h1][e_inx>>1];
			assign r_r[e_inx][0] = env_buf[4'h0][e_inx>>1];
		end
	endgenerate

	env_gen_indexed #(.VOICES(VOICES),.V_ENVS(V_ENVS)) vol_env (
		.iRST_N(iRST_N) ,	// input  iRST_N_sig
		.r_r( r_r ) ,	// input  rate 0:3 // r
		.l_r( l_r ) ,	// input level 0:3 // l
		.clk(~sCLK_XVXENVS) ,	// input  clk_sig
		.key_on_r(rkey_on) ,	// input  key_on_sig
		.env_sel(e_env_sel),
		.voice_sel(e_voice_sel),
		.level_mul(level_mul), 	// output [7:0] level_mul_sig
		.voice_free(voice_free)	// output
	);

endmodule
