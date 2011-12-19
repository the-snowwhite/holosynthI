module	TCON	(	//	Host Side
	oCurrent_X,
	oCurrent_Y,
//	oAddress,
//	oRequest,
//	VGA Side
	oVGA_HS,
	oVGA_VS,
	oVGA_SYNC,
	oinDisplayArea,
	oVGA_CLOCK,
//	Control Signal
	iCLK,
	iRST_N	,
	oLCD_BLANK,
	oHD,
	oVD,
	oDEN	
);
//===========================================================================
// PARAMETER declarations
//===========================================================================

//	Horizontal	Parameter
parameter	H_FRONT	=	16+40 ;
parameter	H_SYNC	=   96;
parameter	H_BACK	=	48;
parameter	H_ACT	=	640;
parameter	H_TOTAL	=	H_FRONT+H_SYNC+H_BACK+H_ACT;

//	Horizontal	Parameter
parameter	H_DE_FRONT	=	40 ;
parameter	H_DE_SYNC	=   1  ;
parameter	H_DE_BACK	=	216;
parameter	H_DE_ACT	=	800; 
parameter	H_DE_TOTAL	=	H_DE_FRONT+H_DE_SYNC+H_DE_BACK+H_DE_ACT;

//	Horizontal	Parameter
parameter	H_VEEK_FRONT	=	40 ;
parameter	H_VEEK_SYNC	=   	128  ;
parameter	H_VEEK_BACK	=	88;
parameter	H_VEEK_ACT	=	800; 
parameter	H_VEEK_TOTAL	=	H_VEEK_FRONT+H_VEEK_SYNC+H_VEEK_BACK+H_VEEK_ACT;

//	Vertical Parameter
parameter	V_SYNC	=	2  ;
parameter	V_ACT	=	480; 
parameter 	V_FRONT	=	11-3 ;
parameter 	V_BACK	=	32+3 ;
parameter 	V_TOTAL	=	V_FRONT+V_SYNC+V_BACK+V_ACT;

//	Vertical Parameter
parameter	V_DE_SYNC	=	2  ;
parameter	V_DE_ACT	=	480; 
parameter 	V_DE_FRONT	=	11-3 ;
parameter 	V_DE_BACK	=	32+3 ;
parameter 	V_DE_TOTAL	=	V_DE_FRONT+V_DE_SYNC+V_DE_BACK+V_DE_ACT;

//	Vertical Parameter
parameter	V_VEEK_SYNC	=	4  ;
parameter	V_VEEK_ACT	=	600; 
parameter 	V_VEEK_FRONT	=	3;
parameter 	V_VEEK_BACK	=	23 ;
parameter 	V_VEEK_TOTAL	=	V_VEEK_FRONT+V_VEEK_SYNC+V_VEEK_BACK+V_VEEK_ACT;


//============================================================================
// PARAMETER declarations
//============================================================================
`ifdef _LTM_Graphics	         
	parameter H_LINE = H_DE_TOTAL;
	parameter V_LINE = V_DE_TOTAL;
	parameter Hsync_Blank = H_DE_BACK;
	parameter Hsync_Front_Porch = H_DE_FRONT;
	parameter Vertical_Back_Porch = V_DE_BACK;
	parameter Vertical_Front_Porch = V_DE_FRONT;
`endif
`ifdef _VEEK_Graphics	         
	parameter H_LINE = H_VEEK_TOTAL;
	parameter V_LINE = V_VEEK_TOTAL;
	parameter Hsync_Blank = H_VEEK_BACK;
	parameter Hsync_Front_Porch = H_VEEK_FRONT;
	parameter Vertical_Back_Porch = V_VEEK_BACK;
	parameter Vertical_Front_Porch = V_VEEK_FRONT;
`endif	
//===========================================================================

//===========================================================================
// PORT declarations
//===========================================================================
output reg oHD;
output reg oVD;
output reg oDEN;
//	Host Side

//output		[21:0]	oAddress;
output		[11:0]	oCurrent_X;
output		[11:0]	oCurrent_Y;
//output		reg		oRequest;
//	VGA Side

output	reg			oVGA_HS;
output	reg			oVGA_VS;
output				oVGA_SYNC;
output	reg			oinDisplayArea;
output				oVGA_CLOCK;
output  	reg		oLCD_BLANK;
//	Control Signal
input				iCLK;
input				iRST_N;	


//=============================================================================
// REG/WIRE declarations
//=============================================================================

//reg			[10:0]	H_Cont;
//reg			[10:0]	V_Cont;

//	Horizontal	Parameter
wire [11:0] H_BLANK;

//	Horizontal	Parameter
wire [11:0] H_DE_BLANK	 ;

//	Vertical Parameter
//wire [11:0] V_FRONT	 ;
//wire [11:0] V_BACK	;
wire [11:0]	V_BLANK	 ;
//wire [11:0]	V_TOTAL	;

//=============================================================================
// REG/WIRE declarations
//=============================================================================

wire			display_area;
reg		[10:0]  x_cnt;  
reg		[10:0]	y_cnt; 
reg				mhd;
reg				mvd;
reg				mden;


//=============================================================================
// Structural coding
//=============================================================================
assign H_BLANK	=	H_FRONT+H_SYNC+H_BACK ;
assign H_DE_BLANK	=	H_DE_SYNC + H_DE_BACK ;
//assign V_FRONT	=	11 ;
//assign V_BACK	=	32 ;
assign V_BLANK	=	V_FRONT+V_SYNC+V_BACK ;
//assign V_TOTAL	=	V_FRONT+V_SYNC+V_BACK+V_ACT;

//=============================================================================
// Structural coding
//=============================================================================
					
// This signal indicate the lcd display area .
assign	display_area = ((x_cnt>(Hsync_Blank-1)&& //>215
						(x_cnt<(H_LINE-Hsync_Front_Porch))&& //< 1016
						(y_cnt>(Vertical_Back_Porch-1))&& 
						(y_cnt<(V_LINE - Vertical_Front_Porch))
						))  ? 1'b1 : 1'b0;
///////////////////////// x  y counter  and lcd hd generator //////////////////
always@(posedge iCLK or negedge iRST_N)
	begin
		if (!iRST_N)
		begin
			x_cnt <= 11'd0;	
			mhd  <= 1'd0;  	
		end	
		else if (x_cnt == (H_LINE-1))
		begin
			x_cnt <= 11'd0;
			mhd  <= 1'd0;
		end	   
		else
		begin
			x_cnt <= x_cnt + 11'd1;
			mhd  <= 1'd1;
		end	
	end

always@(posedge iCLK or negedge iRST_N)
	begin
		if (!iRST_N)
			y_cnt <= 11'd0;
		else if (x_cnt == (H_LINE-1))
		begin
			if (y_cnt == (V_LINE-1))
				y_cnt <= 11'd0;
			else
				y_cnt <= y_cnt + 11'd1;	
		end
	end
////////////////////////////// touch panel timing //////////////////

always@(posedge iCLK  or negedge iRST_N)
	begin
		if (!iRST_N)
			mvd  <= 1'b1;
		else if (y_cnt == 10'd0)
			mvd  <= 1'b0;
		else
			mvd  <= 1'b1;
	end			

always@(posedge iCLK  or negedge iRST_N)
	begin
		if (!iRST_N)
			mden  <= 1'b0;
		else if (display_area)
			mden  <= 1'b1;
		else
			mden  <= 1'b0;
	end			
always@(posedge iCLK or negedge iRST_N)
	begin
		if (!iRST_N)
			begin
				oHD	<= 1'd0;
				oVD	<= 1'd0;
				oDEN <= 1'd0;
			end
		else
			begin
				oHD	<= mhd;
//				oVGA_HS	<= mhd;
				oVD	<= mvd;
//				oVGA_VS <= mvd;
				oDEN <= display_area;
//				oinDisplayArea <= display_area;
				
			end		
	end

	assign	oCurrent_X	=	(x_cnt>=Hsync_Blank)	?	x_cnt-Hsync_Blank	:	11'h0	;
	assign	oCurrent_Y	=	(y_cnt>=Vertical_Back_Porch)	?	y_cnt-Vertical_Back_Porch	:	11'h0	;

////////////////////////////////////////////////////////////
	assign	oVGA_SYNC	=	1'b1;			//	This pin is unused.
	always @(posedge oVGA_CLOCK)	oinDisplayArea	=	~((x_cnt<  (H_BLANK)  )||(y_cnt<V_BLANK));
	always @(posedge oVGA_CLOCK)begin
	oLCD_BLANK	=	~((x_cnt<  (Hsync_Blank)  )||(y_cnt<Vertical_Back_Porch));
//	oVGA_BLANK	=	~((x_cnt<  (Hsync_Blank)  )||(y_cnt<Vertical_Back_Porch));
	end
	assign	oVGA_CLOCK	=	iCLK;

//assign	oAddress	=	oCurrent_Y*H_ACT+oCurrent_X;
//always @(posedge oVGA_CLOCK)	oRequest	=	(( H_Cont >= H_BLANK && H_Cont<H_TOTAL)	&&
//						 (V_Cont>=V_BLANK && V_Cont<V_TOTAL));
////assign	oCurrent_X	=	(H_Cont>=H_BLANK)	?	H_Cont-H_BLANK	:	11'h0	;
////assign	oCurrent_Y	=	(V_Cont>=V_BLANK)	?	V_Cont-V_BLANK	:	11'h0	;

//	Horizontal Generator: Refer to the pixel clock
/*always@(posedge iCLK or negedge iRST_N)
begin
	if(!iRST_N)
	begin
		H_Cont		<=	0;

	end
	else
	begin
		if ( 0 )begin
			H_Cont		<=	0;

	    end
	    else
		if(H_Cont < H_TOTAL)
		H_Cont	<=	H_Cont+1'b1;
		else
		H_Cont	<=	0;
		
	end
end
*/
// VGA_HS out //
	always@(posedge iCLK or negedge iRST_N) begin
		if(!iRST_N)
			oVGA_HS		<=	1;
		else begin
			case  ( x_cnt )
				H_FRONT-1        :oVGA_HS	<=	1'b0;
				H_FRONT+H_SYNC-1 :oVGA_HS	<=	1'b1;
			endcase
		end
	end

/*
//	Vertical Generator: Refer to the horizontal sync
always@(posedge oVGA_HS or negedge iRST_N)
begin
	if(!iRST_N)
	begin
		V_Cont		<=	0;
	end
	else
	begin
		if(V_Cont<V_TOTAL)
		V_Cont	<=	V_Cont+1'b1;
		else
		V_Cont	<=	0;
	end
end
*/
// VGA_VS out//

	always@(posedge oVGA_HS or negedge iRST_N) begin
		if(!iRST_N)
			oVGA_VS		<=	1;
		else begin
			case ( y_cnt )
				V_FRONT-1        :oVGA_VS	<=	1'b0;
				V_FRONT+V_SYNC-1 :oVGA_VS	<=	1'b1;
			endcase
		end
	end

endmodule
