// --------------------------------------------------------------------
// Copyright (c) 2007 by Terasic Technologies Inc. 
// --------------------------------------------------------------------
//
// Permission:
//
//   Terasic grants permission to use and modify this code for use
//   in synthesis for all Terasic Development Boards and Altera Development 
//   Kits made by Terasic.  Other use of this code, including the selling 
//   ,duplication, or modification of any portion is strictly prohibited.
//
// Disclaimer:
//
//   This VHDL/Verilog or C/C++ source code is intended as a design reference
//   which illustrates how these types of functions can be implemented.
//   It is the user's responsibility to verify their design for
//   consistency and functionality through the use of formal
//   verification methods.  Terasic provides no warranty regarding the use 
//   or functionality of this code.
//
// --------------------------------------------------------------------
//           
//                     Terasic Technologies Inc
//                     356 Fu-Shin E. Rd Sec. 1. JhuBei City,
//                     HsinChu County, Taiwan
//                     302
//
//                     web: http://www.terasic.com/
//                     email: support@terasic.com
//
// --------------------------------------------------------------------
//
// Major Functions:	HMB Touch Panel RGB data encoder
//
// --------------------------------------------------------------------
//
// Revision History :
// --------------------------------------------------------------------
//   Ver  :| Author            			:| Mod. Date :| Changes Made:
//   V1.0 :| Johnny Fan	:| 07/5/10  	:| Initial Revision
//   V1.1 :| Johnny Fan	:| 07/6/6	  	:| 1.Change RGB decoder sequence
//										   2.Remove oPISO_LCD_RGB , oLCD_HD , oLCD_VD,oLCD_DEN delay function			
//										   	
// --------------------------------------------------------------------
module LCD_DATA_ENCODE ( // input
						iCLK,
						Muti_CLK,
						iLCD_R,
						iLCD_G,			
						iLCD_B,
						iRST_N,
						iLCD_HD,		
						iLCD_VD,		
						iLCD_DEN,	
						// output
						oPISO_LCD_RGB,
						oLCD_HD,
						oLCD_VD,
						oLCD_DEN
						);
						
////////////   I/O declare  /////////////////
input			iCLK;  // 25M hz
input			Muti_CLK; // 75M hz
input	[7:0]	iLCD_R;
input	[7:0]	iLCD_G;
input	[7:0]	iLCD_B;
input			iRST_N;						
input			iLCD_HD;
input			iLCD_VD;
input			iLCD_DEN;
output	[7:0]	oPISO_LCD_RGB;	
output			oLCD_HD;
output			oLCD_VD;
output			oLCD_DEN;

//////////////////////////////////////////////

reg		[1:0]	PISO_cnt;
reg		[7:0]	PISO_RGB;
reg				RGB_SYNC;
reg		[7:0]	PISO_RGB_delay;
reg		[7:0]	PISO_RGB_delay1;
reg		[1:0]	iLCD_HD_delay;	
reg		[1:0]	iLCD_VD_delay; 	
reg		[1:0]	iLCD_DEN_delay; 
wire	[7:0]	mPISO_LCD_RGB;
wire			mLCD_HD;
wire			mLCD_VD;
wire			mLCD_DEN;
wire	[7:0]	oPISO_LCD_RGB;
reg				oLCD_HD;
reg				oLCD_VD;
reg				oLCD_DEN;

assign	 oPISO_LCD_RGB	= 	PISO_RGB;

always@(posedge Muti_CLK)
	begin
		oLCD_HD		<= iLCD_HD;
		oLCD_VD  	<= iLCD_VD;
		oLCD_DEN 	<= iLCD_DEN;
	end
wire	psio_cnt_rst_p;	
assign	psio_cnt_rst_p = (iLCD_HD!= oLCD_HD);


/////////////// RGB DATA PISO ////////////////////////
always@(posedge Muti_CLK)
begin
	if (psio_cnt_rst_p)
		PISO_cnt <= 0;
	else if (PISO_cnt == 2)
		PISO_cnt <= 0;
	else
		PISO_cnt <= PISO_cnt + 1;		
end

always@(posedge Muti_CLK)
begin
	if (psio_cnt_rst_p)
		PISO_RGB <= 0;
	else
	begin
	case(PISO_cnt)
		2'b00 : PISO_RGB <= iLCD_G;
		2'b01 : PISO_RGB <= iLCD_R;
		2'b10 : PISO_RGB <= iLCD_B;	
	endcase
	end
end

endmodule

						