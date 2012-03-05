module MIDI_UART(
	input   				CLOCK_25,
	input					sys_clk,
	input   				iRST_N,
	input   				midi_rxd,
	input					initial_reset,
	output	reg		byteready,
	output   reg		sys_real,
	output	reg[7:0]	sys_real_dat,
	output	reg[7:0]	cur_status,
	output	reg[7:0]	midi_bytes,
	output	reg[7:0]	databyte
);
	reg midi_dat,md_1;
	wire md_ok = md_1 & midi_rxd;
	
	always @(posedge CLOCK_25)begin
		md_1 <= midi_rxd;
		midi_dat <= md_ok;			
	end

//// Clock gen ////
wire mgen_c;
wire [7:0]m_cnt_bits;

midi_clk_gen mck (
	.clock 	( CLOCK_25 ),
	.sclr 	(reset_mod_cnt),
	.cout	(mgen_c),
	.q		(m_cnt_bits )
	);
reg midi_clk;
TFF mid_Ck (
		.t(mgen_c), 
		.clk(CLOCK_25), 
		.clrn(!reset_mod_cnt), 
		.prn(1'b1), 
		.q(midi_clk)
	);

reg startbit_d;
always @(posedge CLOCK_25 or negedge iRST_N)begin
	if (!iRST_N)begin startbit_d <=0;end 
	else begin
		if(revcnt>=18) startbit_d<=0;
		else if (!startbit_d)begin
			if(midi_dat) startbit_d <=0;
			else startbit_d<=1;
		end		
	end
end

// Clk gen reset circuit /////
reg reset_mod_cnt;
reg [2:0]reset_cnt;
always @(negedge CLOCK_25 or negedge iRST_N)begin
	if(!iRST_N)begin reset_cnt <=0;reset_mod_cnt <=0;end
	else begin
		if (initial_reset || !startbit_d)	
			reset_cnt<=0;
		else if(reset_cnt<=1 && startbit_d)begin
			reset_cnt<=reset_cnt+1;
			reset_mod_cnt<=1;
		end
		else reset_mod_cnt<=0;
	end
end

///// sequence generator /////
	reg [4:0]revcnt;
	
	always @(posedge midi_clk or negedge iRST_N)begin
		if(!iRST_N) revcnt <= 0;
		else begin
			if (!startbit_d) revcnt<=0;
			else if (revcnt >=18) revcnt<=0;
			else revcnt<=revcnt+1;
		end
	end
	 
// Serial data in
	reg [7:0]samplebyte;

	always @(negedge midi_clk or negedge iRST_N) begin
		if(!iRST_N)begin samplebyte <=0; databyte<=0;end
		else begin 
			case (revcnt[4:0])
			3:samplebyte[0]<=midi_dat;
			5:samplebyte[1]<=midi_dat;
			7:samplebyte[2]<=midi_dat;
			9:samplebyte[3]<=midi_dat;
			11:samplebyte[4]<=midi_dat;
			13:samplebyte[5]<=midi_dat;
			15:samplebyte[6]<=midi_dat;
			17:samplebyte[7]<=midi_dat;
			18:databyte <= samplebyte;
			default:;
			endcase
		end
	end	
	wire byte_end = (revcnt[4:0]==18)? 1 : 0;
	
    always @(posedge initial_reset or negedge midi_clk or negedge iRST_N) begin 
		if(!iRST_N) byteready<=0;
		else begin
			if (initial_reset) byteready<=0;
			else if ( byte_end && (sys_real == 1'b0)) byteready<=1;
			else byteready<=0;
		end
    end			
	 
// DataByte counter -- Status byte logger //	
	always @(negedge startbit_d or negedge iRST_N)begin
		if(!iRST_N)begin midi_bytes<=0; cur_status<=0;end
		else begin
			if(samplebyte[7:4] == 4'hf && samplebyte[3:0]!=4'h0)begin
				sys_real_dat <=samplebyte;
				sys_real<= 1'b1; 
			end
			else begin
				sys_real <= 1'b0;
				if(samplebyte & 8'h80)begin
					midi_bytes<=0;
					cur_status<=samplebyte;
				end
				else midi_bytes<=midi_bytes+1;
			end
		end
	end
		
endmodule
