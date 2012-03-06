module synth_clk_gen (
input iRST_N,
input tCLK,
input iCLK_16_9,
output reg	LRCK_1X,
//output reg	LRCK_8X,
output reg	sCLK_XV,
output reg	sCLK_2XV,
output reg	sCLK_XVXOSC,
output reg	sCLK_XVXENVS,
output reg	oAUD_BCK
);
parameter 	VOICES = 8;
parameter 	V_OSC = 4; // oscs per Voice
parameter 	V_ENVS = 2*V_OSC;

parameter	AUDIO_CLK		=	271428571;	//	271.428571 MHz
parameter	REF_CLK			=	16964286;	//	16.964286	MHz
parameter	SAMPLE_RATE		=	44110;		//	48		KHz
parameter	DATA_WIDTH		=	16;			//	16		Bits
parameter	CHANNEL_NUM		=	2;			//	Dual Channel

//	Internal Registers and Wires
reg		[8:0]	BCK_DIV;
reg		[12:0]	LRCK_1X_DIV;
//reg		[10:0]	LRCK_8X_DIV;
//reg		[10:0]	sCLK_XV_DIV;
//reg		[9:0]	sCLK_2XV_DIV;
reg		[9:0]	sCLK_XVXOSC_DIV;
reg		[8:0]	sCLK_XVXENVS_DIV;

////////////////////////////////////
///////////	AUD_BCK Generator	//////////////
always@(posedge iCLK_16_9 or negedge iRST_N)
begin
	if(!iRST_N)
	begin
		LRCK_1X_DIV		<=	0;
		LRCK_1X		<=	0;
		BCK_DIV		<=	0;
		oAUD_BCK	<=	0;
	end
	else
	begin
		//	LRCK 1X
		if(LRCK_1X_DIV >= REF_CLK/(SAMPLE_RATE*2)-1 )
		begin
			LRCK_1X_DIV	<=	0;
			LRCK_1X	<=	~LRCK_1X;
		end
		else
		LRCK_1X_DIV		<=	LRCK_1X_DIV+1;
		//	AUD_BCK
		if(BCK_DIV >= REF_CLK/(SAMPLE_RATE*DATA_WIDTH*CHANNEL_NUM*2)-1 )
		begin
			BCK_DIV		<=	0;
			oAUD_BCK	<=	~oAUD_BCK;
		end
		else
		BCK_DIV		<=	BCK_DIV+1;
	end
end
//////////////////////////////////////////////////
////////////	AUD_LRCK Generator	//////////////
always@(posedge tCLK or negedge iRST_N)
begin
	if(!iRST_N)
	begin
		sCLK_XVXOSC_DIV 	<=	0;
		sCLK_XVXENVS_DIV 	<=	0;
		sCLK_XVXOSC	<=	0;
		sCLK_XVXENVS	<=	0;
	end
	else
	begin
		if(sCLK_XVXOSC_DIV >= AUDIO_CLK/(SAMPLE_RATE*CHANNEL_NUM*VOICES*V_OSC*2)-1 )
		begin
			sCLK_XVXOSC_DIV	<=	0;
			sCLK_XVXOSC	<=	~sCLK_XVXOSC;
		end
		else
		sCLK_XVXOSC_DIV		<=	sCLK_XVXOSC_DIV+1;	
		//	LRCK 128X
		if(sCLK_XVXENVS_DIV >= AUDIO_CLK/(SAMPLE_RATE*CHANNEL_NUM*VOICES*V_ENVS*2)-1 )
		begin
			sCLK_XVXENVS_DIV	<=	0;
			sCLK_XVXENVS	<=	~sCLK_XVXENVS;
		end
		else
		sCLK_XVXENVS_DIV		<=	sCLK_XVXENVS_DIV+1;	
	end	
end

endmodule
