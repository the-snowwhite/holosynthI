/////////////////////////////////////////////
////     2Channel-Music-Synthesizer     /////
/////////////////////////////////////////////
/*****************************************************/
/*             KEY & SW List               			 */
/* BUTTON[1]: I2C reset                       		 */
/* BUTTON[2]: Demo Sound and Keyboard mode selection */
/* BUTTON[3]: Keyboard code Reset             		 */
/* BUTTON[4]: Keyboard system Reset                  */
/*****************************************************/

module synthesizer (
// Clock
	input		CLOCK_50,				
// reset
	output		DLY0,
// MIDI uart
	input		MIDI_Rx_DAT,				//	MIDI Data

	input	[4:1]	button,					//	Button[4:1]
	input   [17:0]	SW,
//	output	[3:0]	hex_disp[7:0],

	output	[8:1]	GLED,					//	LED[4:1] 
	output	[17:1]	RLED,					//	LED[4:1] 

	output		VGA_CLK,   				//	VGA Clock
	output		HS,					//	VGA H_SYNC
	output		VS,					//	VGA V_SYNC
//	output		LCD_BLANK,				//	LCD BLANK
	output		HD,				//	LCD BLANK
	output		VD,				//	LCD BLANK
	output		DEN,				//	LCD BLANK
	output		inDisplayArea,				//	VGA BLANK
	output		SYNC,				//	VGA SYNC
	output	[9:0]	VGA_R,   				//	VGA Red[9:0]
	output	[9:0]	VGA_G,	 				//	VGA Green[9:0]
	output	[9:0]	VGA_B,   				//	VGA Blue[9:0]
	output          HC_VGA_CLOCK,			//  VGA encodr clock     
	output          HC_LCD_CLOCK,			//  VGA encodr clock     

	inout		AUD_ADCLRCK,			//	Audio CODEC ADC LR Clock
	inout		AUD_DACLRCK,			//	Audio CODEC DAC LR Clock
	input		AUD_ADCDAT,			    //	Audio CODEC ADC Data
	output		AUD_DACDAT,				//	Audio CODEC DAC Data
	inout		AUD_BCLK,				//	Audio CODEC Bit-Stream Clock
	output		AUD_XCK,					//	Audio CODEC Chip Clock

	input 		N_adr_data_rdy,				// midi data num ready from Nios
	input	[9:0]	N_adr,				// controller nr.
	output	[7:0]	N_synth_out_data,				// data byte
	input	[7:0]	N_synth_in_data,				// data byte
	output		N_save_sig,
	output		N_load_sig,
	output	[7:0] 	N_sound_nr, 

	input		LTM_ADC_BUSY,
	output   	LTM_ADC_DCLK,
	output		LTM_ADC_DIN,
	input		LTM_ADC_DOUT,
	input		LTM_ADC_PENIRQ_n,
	output		LTM_SCEN,
	inout		LTM_SDA

);


//parameter VOICES = 32;

//parameter VOICES = 16;
parameter VOICES = 8;
//parameter VOICES = 4;
//parameter VOICES = 2;
// --> !!! Min 2 voices ---//!parameter VOICES = 1;

parameter V_OSC = 4;
//parameter V_OSC = 2;
//parameter V_OSC = 1;

parameter V_ENVS = V_OSC*2;

parameter V_WIDTH = utils::clogb2(VOICES);
parameter O_WIDTH = utils::clogb2(V_OSC);

parameter V_1 = 1;
parameter V_2 = 2;
parameter V_3 = 3;
parameter V_4 = 4;
parameter V_5 = 5;
parameter V_6 = 6;
parameter V_7 = 7;
parameter V_8 = 8;
parameter V_9 = 9;
	
parameter VW_1 = utils::clogb2(V_1); 	
parameter VW_2 = utils::clogb2(V_2); 	
parameter VW_3 = utils::clogb2(V_3); 	
parameter VW_4 = utils::clogb2(V_4); 	
parameter VW_5 = utils::clogb2(V_5); 	
parameter VW_6 = utils::clogb2(V_6); 	
parameter VW_7 = utils::clogb2(V_7); 	
parameter VW_8 = utils::clogb2(V_8); 	
parameter VW_9 = utils::clogb2(V_9); 	

//-----		Wires		-----//
//---	Reset gen		---//	
wire reset1 = button[1];
wire reset2 = button[2];
wire iRST_N = ((MCNT==200) || (!reset2))?0:1;

//---	Midi	---//
// inputs
wire midi_rxd = !MIDI_Rx_DAT;			
//outputs
wire byteready;
wire[7:0] cur_status,midi_bytes,databyte;

//---	Midi	Decoder ---//

// inputs
// outputs
wire 	key_on[VOICES];
wire 	[7:0]	key_val[VOICES];
wire 	[7:0]	vel_on[VOICES];
wire ctrl_cmd,pitch_cmd,sysex_cmd;
wire[7:0] ctrl,cur_data,sysex_data[3];
wire [V_WIDTH:0]	active_keys;
wire 	off_note_error;

//---	Midi	Controllers unit ---//

wire [13:0]pitch_val;
wire signed [7:0] env_buf[16][V_OSC];	
wire signed [7:0] osc_buf[16][V_OSC];	
wire signed [7:0] mat_buf[32][V_OSC];	
wire signed [7:0] com_buf[32];	

wire [7:0] o_index;
	
assign status_data[0] = active_keys;
//	assign status_data[1] =	off_note_error;
//	assign status_data[1] =	 {off_note_error,o_index[6:0]};
assign status_data[1] =	 osc_inx;
wire[7:0] osc_inx;
assign osc_inx[7] = off_note_error;
assign osc_inx[6:0] = o_index[6:0];

////////////	Init Reset sig Gen	////////////	
// system reset  //

Reset_Delay	du3  (
	.iCLK(CLOCK_50),
	.iRST(reset1),
	.oRST_0(DLY0),
	.oRST_1(DLY1),
	.oRST_2(DLY2)
);
wire DLY1,DLY2;	

reg [10:0] MCNT;
	always @(negedge reset1 or posedge sysclk) begin
		if (!reset1) MCNT=0;
		else if(MCNT < 500) MCNT=MCNT+1;
	end
wire initial_reset=(MCNT<12)?1:0;

//-----	Clockgens & Timing	----//
//  PLL
VGA_PLL	p1	(	
	.areset ( 1'b0 ),								
	.inclk0 ( CLOCK_50 ),
	.c0		( HC_LCD_CLK ),	// 39Mhx
	.c1		( HC_VGA_CLOCK ),// 
	.c2		( CLOCK_25 ) 
);

wire	CLOCK_25;
// Sound clk gen //

// TIME & Display CLOCK Generater //

`ifdef _LTM_Graphics	         
	assign VGA_CLK  = CLOCK_25 ;
`endif
`ifdef _VEEK_Graphics	         
	assign VGA_CLK  = HC_LCD_CLK ;
`endif


reg    [31:0]VGA_CLK_o;
	always @( posedge CLOCK_25) VGA_CLK_o = VGA_CLK_o + 1;
wire   sysclk = VGA_CLK_o[10];
wire 	 touch_clk = VGA_CLK_o[10];


//---				---//

MIDI_UART MIDI_UART_inst (
	.CLOCK_25		(CLOCK_25),	// input  reset sig
	.sys_clk		(sysclk),	// input  sys_clk_sig
	.iRST_N			(iRST_N),	// input  reset_sig
	.initial_reset	(initial_reset),	// input  reset_timing_sig
	.midi_rxd		(midi_rxd),	// input  midi_rxd_sig
	.byteready		(byteready),	// output  byteready_sig
	.cur_status		(cur_status),	// output [7:0] cur_status_sig
	.midi_bytes		(midi_bytes),	// output [7:0] midi_bytes_sig
	.databyte		(databyte) 	// output [7:0] databyte_sig
);

midi_decoder #(.VOICES(VOICES),.V_WIDTH(V_WIDTH)) midi_decoder_inst(
// inputs
	.clock_25	( CLOCK_25 ),		// 25 Mhz clock    		
	.sys_clk	( sysclk ),		//system clock		
	.iRST_N		(iRST_N) ,		// input  reset_sig
	.byteready_in	(byteready),		//midi data ready
	.cur_status_in	(cur_status),		// current midi data status
	.midi_bytes_in	(midi_bytes),		// data byte
	.databyte_in	(databyte),		// data byte
	.voice_free_	( voice_free ),		// envelope gen finished
// outputs   
	.key_on		( key_on  ),		// key trigers
	.key_val	( key_val ),		// key midi number
	.vel_on		( vel_on ),		// key velocity
	.ctrl_cmd	( ctrl_cmd ),		// 1 on first databyte 0 on second
	.pitch_cmd	( pitch_cmd ),		// 1 on first databyte 0 on second
	.ctrl		( ctrl),		// Controller nr.
	.cur_data	( cur_data),		// Controller Data
	.sysex_cmd	( sysex_cmd ),		// 1 on last databyte 
	.sysex_data	( sysex_data ),		// Controller Data
	.active_keys	( active_keys ),	//
	.off_note_error	( off_note_error )
);

	
midi_controllers_unit #(.VOICES(VOICES),.V_OSC(V_OSC)) midi_controllers(
	.iCLK			( CLOCK_25),
	.iRST_n			(DLY2),
	.SW 			(SW),
// from midi_decoder
	.ctrl_cmd		( ctrl_cmd ), 
	.ctrl			( ctrl ), 
	.cur_data		( cur_data ), 
	.sysex_data		( sysex_data ), 		// Controller Data
	.pitch_cmd		( pitch_cmd ),
	.sysex_cmd		( sysex_cmd ),			// 1 on last databyte 
//	controller & status signals //	
//	.hex_disp( hex_disp ),
	.hex_disp		(  ),
	.disp_data		( disp_data ),
	.o_index		(o_index),
	.disp_val		( disp_val ),
//	cpu signals //
	.N_adr_data_rdy		( N_adr_data_rdy ),					// midi data ready from Nios
	.N_adr			( N_adr[8:0] ),				// controller nr.
	.N_synth_out_data	( N_synth_out_data ),		// data byte
	.N_synth_in_data	( N_synth_in_data ),		// data byte
	.N_save_sig		( N_save_sig ),
	.N_load_sig		( N_load_sig ),
//	touch signals	 //
	.slide_val		( slide_val ),	//input
	.write_slide		( write_slide ),
// outputs	
//	.synth_data( synth_data ),
	.env_buf		( env_buf ),
	.osc_buf		( osc_buf ),
	.mat_buf		( mat_buf ),
	.com_buf		( com_buf ),
	.pitch_val		( pitch_val )
);

wire voice_free[VOICES];

//////////// Sound Generation /////////////	

`ifdef _Synth
					
// 2CH Audio Sound output -- Audio Generater //
synth_engine #(.VOICES(VOICES),.V_OSC(V_OSC),.V_ENVS(V_ENVS)) synth_engine_inst	(		        
// AUDIO CODEC //		
	.tCLK_271_4285( TONE_CTRL_CLK ),	//input
	.iCLK_16_9( AUD_CTRL_CLK ),		//input
	.iRST_N(iRST_N) ,	// input  reset_sig
	.oAUD_BCK ( AUD_BCLK ),				//output
	.oAUD_DATA( AUD_DACDAT ),			//output
	.oAUD_LRCK( AUD_DACLRCK ),			//output																
// KEY //		
    	.switch	  ( SW[17:0]),			//input			
	.button	  ( button[4:1]),		//input			
	// -- Sound Control -- //
    	.clock_25 ( CLOCK_25 ),			// input 25 Mhz clock    		
	.sys_clk  ( sysclk ),  		//input system clock		
//	from midi_decoder //
    	.key_on   ( key_on ),			//input key trigers
    	.key_val( key_val ),				//input key midi number
    	.vel_on  ( vel_on ),				// key velocity
// from env gen // 
	.voice_free(voice_free),		//output from envgen
// from midi_controller_unit
//	.synth_data ( synth_data ),
	.env_buf( env_buf ),
	.osc_buf( osc_buf ),
	.mat_buf( mat_buf ),
	.com_buf( com_buf ),
	.pitch_val ( pitch_val )
);
//	AUDIO SOUND

Audio_pll	Audio_pll (
	.inclk0 ( CLOCK_50 ),
	.c0 ( AUD_CTRL_CLK ),  // 16.925466 Mhz
	.c1 ( TONE_CTRL_CLK ), // 64.880952--> 267.187500 --> 271.428571 Mhz
	.locked (  )
);

wire AUD_CTRL_CLK;
wire TONE_CTRL_CLK;
	
assign	AUD_ADCLRCK	=	AUD_DACLRCK;

assign	AUD_XCK		=	AUD_CTRL_CLK;			
	
`endif


/////// LED Display ////////
assign GLED[8:1] = {key_on[7],key_on[6],key_on[5],key_on[4],
	key_on[3],key_on[2],key_on[1],key_on[0]};

assign RLED[8:1] = {voice_free[7],voice_free[6],voice_free[5],voice_free[4],
	voice_free[3],voice_free[2],voice_free[1],voice_free[0]};	

//assign RLED[16:9] = {voice_free[15],voice_free[14],voice_free[13],voice_free[12],
//						voice_free[11],voice_free[10],voice_free[9],voice_free[8]};	
/*
	assign hex_disp[0] = y_coord[3:0];
	assign hex_disp[1] = y_coord[7:4];
	assign hex_disp[2] = y_coord[11:8];
	assign hex_disp[3] = 4'h0;
	assign hex_disp[4] = x_coord[3:0];
	assign hex_disp[5] = x_coord[7:4];
	assign hex_disp[6] = x_coord[11:8];
	assign hex_disp[7] = {3'b000,new_coord};
*/



// LCD Display + Touch + +++++++++++++++++++--- Color ----------------------------------//
	wire [7:0]disp_data[64];
		
display display_inst_1(		
	// VGA output //		
	.VGA_CLK	( VGA_CLK ),   
	.HS	( HS ), 
	.VS	( VS ), 
	.SYNC	( SYNC ),	
	.inDisplayArea	( inDisplayArea ),
//	.inLcdDisplay	( LCD_BLANK ),
//	.inLcdDisplay	( ),
	.HD		( HD ),
	.VD		( VD ),
	.DEN		( DEN ),
	.VGA_R		( VGA_R ),
	.VGA_B		( VGA_B ),
	.VGA_G		( VGA_G ),
// Key code-in //
	.scan_code1	( key_val[0] ),
	.scan_code2	( key_val[1] ),
	.scan_code3	( key_val[2] ), // ON
	.scan_code4	( key_val[3] ), // OFF
	.disp_data	( disp_data ),
	.status_data	( status_data ),
	.DLY2		(DLY2),
	.chr_3		( chr_3 ),
	.lne		( lne ),
	.slide_val	( slide_val )
);
wire [7:0]status_data[12];
///// Touch Controller files /////////////

wire [3:0] chr_3,lne;
wire [7:0]edit_chr,slide_val;
wire [7:0]disp_val;
wire write_slide;
reg transmit_en_r;
reg new_coord_r;

	touch	touch	(
		.iRST_n 	( DLY0 ),
		.sys_clk  ( touch_clk ),  		//input system clock		
		.x (~x_coord[11:4]),
		.y (y_coord[11:4]),
		.new_coord_r (new_coord_r),
		.transmit_en (transmit_en_r ),
		.disp_data( disp_data ),
		.penirq_n (LTM_ADC_PENIRQ_n),
		.touch_status_data (status_data[2:11]),
		.disp_val(disp_val),
		.chr_3 ( chr_3 ),
		.lne( lne ),
		.slide_val(slide_val),
		.write_slide ( write_slide ),
		.N_save_sig ( N_save_sig ),	//save patch to sd
		.N_load_sig ( N_load_sig ),	//output load patch from sd
		.N_adr_9(N_adr[9]), // input end transfer
		.N_sound_nr(N_sound_nr)	// output file nr. name to sd			
	);

	always @(posedge CLOCK_50)begin
		new_coord_r <= new_coord;
		transmit_en_r <= transmit_en;
	end
	
assign LTM_ADC_DCLK	= ( adc_dclk & ltm_3wirebusy_n )  |  ( ~ltm_3wirebusy_n & ltm_sclk );

wire            adc_dclk;
wire            ltm_3wirebusy_n;
wire            ltm_sclk;
wire            touch_irq;
wire    [11:0]  x_coord,y_coord;
wire            new_coord;
wire 				 transmit_en;
	
	lcd_spi_controller	du2	(	
		// Host Side
		.iCLK(CLOCK_50),
		.iRST_n(DLY0),
		// 3wire Side
		.o3WIRE_SCLK(ltm_sclk),
		.io3WIRE_SDAT(LTM_SDA),
		.o3WIRE_SCEN(LTM_SCEN),
		.o3WIRE_BUSY_n(ltm_3wirebusy_n)
	);	

// Touch Screen Digitizer ADC configuration //

	adc_spi_controller		du4	(
		.iCLK(CLOCK_50),
		.iRST_n(DLY0),
		.oADC_DIN(LTM_ADC_DIN),
		.oADC_DCLK(adc_dclk),
		.oADC_CS(),
		.iADC_DOUT(LTM_ADC_DOUT),
		.iADC_BUSY(LTM_ADC_BUSY),
		.iADC_PENIRQ_n(LTM_ADC_PENIRQ_n),
		.oTOUCH_IRQ(touch_irq),
		.oX_COORD(x_coord),
		.oY_COORD(y_coord),
		.oNEW_COORD(new_coord),
		.transmit_en (transmit_en )
	);

endmodule
