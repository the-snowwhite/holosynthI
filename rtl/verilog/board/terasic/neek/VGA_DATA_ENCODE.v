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
// Major Functions:	HMB VGA RGB data encoder
//
// --------------------------------------------------------------------
//
// Revision History :
// --------------------------------------------------------------------
//   Ver  :| Author            			:| Mod. Date :| Changes Made:
//   V1.0 :| Johnny Fan	:| 07/5/10  	:| Initial Revision
									   	
// --------------------------------------------------------------------
module VGA_DATA_ENCODE ( // input
						iCLK,
						Muti_CLK,
						iVGA_R,
						iVGA_G,			
						iVGA_B,
						iRST_N,
						iVGA_HS,		
						iVGA_VS,		
						iVGA_BLANK,
						iVGA_SYNC,	
						// output
						oHC_VGA_DATA,
						oHC_VGA_HS,
						oHC_VGA_VS,
						oHC_VGA_BLANK,
						oHC_VGA_SYNC
						
						);
						
////////////   I/O declare  /////////////////
input			iCLK;  // 25M hz
input			Muti_CLK; // 75M hz
input	[9:0]	iVGA_R;
input	[9:0]	iVGA_G;
input	[9:0]	iVGA_B;
input			iRST_N;						
input			iVGA_HS;
input			iVGA_VS;
input			iVGA_BLANK;
input			iVGA_SYNC;
output	[9:0]	oHC_VGA_DATA;	
output			oHC_VGA_HS;
output			oHC_VGA_VS;
output			oHC_VGA_BLANK;
output			oHC_VGA_SYNC;

//////////////////////////////////////////////

reg		[1:0]	PISO_cnt;
reg		[9:0]	PISO_RGB;
wire	[9:0]	oHC_VGA_DATA;
reg				oHC_VGA_HS;
reg				oHC_VGA_VS;
reg				oHC_VGA_BLANK;
reg				oHC_VGA_SYNC;

assign	 oHC_VGA_DATA	= 	PISO_RGB;

always@(posedge Muti_CLK)
	begin
		oHC_VGA_HS   	<= 	iVGA_HS;
		oHC_VGA_VS  	<=	iVGA_VS;
		oHC_VGA_BLANK 	<=	iVGA_BLANK;
		oHC_VGA_SYNC 	<=	iVGA_SYNC;
	end	

assign	psio_cnt_rst_p = (iVGA_HS!= oHC_VGA_HS);

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
		2'b00 : PISO_RGB <= iVGA_G;
		2'b01 : PISO_RGB <= iVGA_R;
		2'b10 : PISO_RGB <= iVGA_B;	
	endcase
	end
end

endmodule

						