module midi_decoder(
	input   			CLOCK_25,
	input   			sys_clk,
	input   			iRST_N,
// from uart
	input				byteready_in,
	input	[7:0]		cur_status_in,
	input [7:0]		midi_bytes_in,// check if can be used as databyte_in instead
	input [7:0]		databyte_in,
// inputs from synth engine	
	input 			voice_free_[VOICES],	
// outputs to synth_engine
// notes
	output reg 	key_on[VOICES],
	output reg 	[7:0]	key_val[VOICES],
	output reg 	[7:0]	vel_on[VOICES],
// controller data
	output reg  		octrl_cmd, 
	output reg  		pitch_cmd,
	output reg  [7:0]	octrl, 
	output reg  [7:0]	octrl_data, 
	output reg  		sysex_cmd,
	output reg  [7:0]	sysex_data[3], 
// status data
	output reg [V_WIDTH:0]	active_keys,
	output reg 	off_note_error

);

parameter VOICES = 8;
parameter V_WIDTH = utils::clogb2(VOICES);

/////////////////////////////////////Key1-Key2 Output///////////////////////////
	wire is_st_note_on=(
		(cur_status[7:4]==4'h9)?1'b1:1'b0);

	wire is_st_note_off=(
		(cur_status[7:4]==4'h8)?1'b1:1'b0);
		 
	wire is_st_ctrl=(
		(cur_status[7:4]==4'hb)?1'b1:1'b0);
 
	wire is_st_pitch=(
		(cur_status[7:4]==4'he)?1'b1:1'b0);
 
	wire is_st_sysex=(
		(cur_status[7:4]==4'hf)?1'b1:1'b0);
 
	wire is_data_byte=(
	 (midi_bytes[0]==1'b1)?1'b1:1'b0);
	
	wire is_velocity=(
	 (midi_bytes[0]==1'b0 && midi_bytes != 8'h0)?1'b1:1'b0);
	 
	 wire is_allnotesoff=(
	 (databyte==8'h7b)?1'b1:1'b0);	 
	
//////////////key1 & key2 Assign///////////
reg byteready;
reg [7:0]cur_status;
reg [7:0]midi_bytes;
reg [7:0]databyte;
reg voice_free_r[VOICES];
reg [V_WIDTH:0]cur_slot; 

	always @(posedge CLOCK_25)begin
			voice_free_r <= voice_free_;
	end	
	
	reg [V_WIDTH-1:0]first_free;
	reg [V_WIDTH-1:0]first_on;
	reg [V_WIDTH-1:0]on_slot[VOICES];
	reg [V_WIDTH-1:0]off_slot[VOICES];
	reg free_voice;
	reg [7:0]vel_off;
	reg [7:0]cur_note;
	reg [V_WIDTH-1:0]slot_off;
	reg off_note_error_flag;
	wire [V_WIDTH:0]i1;
	wire [V_WIDTH:0]i2;
	wire [V_WIDTH:0]i3;
	wire [V_WIDTH:0]i4;
	wire [V_WIDTH:0]i5;
	wire [V_WIDTH:0]i6;
	wire [V_WIDTH:0]i7;
	wire [V_WIDTH:0]i8;

	always @(negedge iRST_N or posedge CLOCK_25)begin
		if (!iRST_N) begin
			free_voice <= 1'b1;
		end
		else begin 
			byteready <= byteready_in;
			cur_status <= cur_status_in;
			midi_bytes <= midi_bytes_in;
			databyte <= databyte_in;
			for(i3=0; i3 < VOICES ; i3=i3+1) begin
				if(voice_free_r[i3])begin
					free_voice <= 1'b1;
					break;
				end
				else begin
					free_voice <= 1'b0;				
				end
			end
		end	
	end
	
	always @(negedge iRST_N or posedge is_data_byte)begin
		if (!iRST_N) begin
			first_free<=0;
		end 
		else begin
			for(i1=0; i1 < VOICES ; i1++) begin
				if(voice_free_r[i1])begin
					first_free<=i1;
					break;
				end
			end	 
		end	
	end
	
	always @(negedge iRST_N or negedge byteready) begin
		if (!iRST_N) begin // init values 
			active_keys <= 0;
			off_note_error <= 1'b0;
			for(i5=0;i5<VOICES-1;i5++)begin
				key_on[i5]<=1'b0;
				key_val[i5]<=8'hff;
				on_slot[i5]<=0;
				off_slot[i5]<=0;
				vel_on[i5]<=0;
			end
			slot_off<=0;
			cur_note<=0;
			cur_slot<=0;
			active_keys<=0;
//			off_note<=0;
			off_note_error<=1'b0;
			off_note_error_flag<=0;
		end 
		else begin 
			octrl_cmd <= 1'b0;sysex_cmd <= 1'b0;pitch_cmd <= 1'b0;
			if(is_st_note_on)begin // Note on omni
				if(is_data_byte)begin
					if(active_keys >= VOICES) begin
						active_keys <= active_keys-1;
						key_on[on_slot[0]]<=1'b0;	
						key_val[on_slot[0]]<=8'hff;
						slot_off<=on_slot[0];					
						cur_slot<=on_slot[0];
					end else if(free_voice == 1'b0)begin
						cur_slot <= off_slot[active_keys];
					end
					else begin
						cur_slot<=first_free;
					end	
					for(i6=VOICES-1;i6>0;i6--)begin
						on_slot[i6-1]<=on_slot[i6];
					end
					cur_note<=databyte;				
				end	else if(is_velocity)begin
					active_keys <= active_keys+1;
					vel_on[cur_slot]<=databyte;
					key_on[cur_slot]<=1'b1;
					key_val[cur_slot]<=cur_note;
					on_slot[VOICES-1] <= cur_slot;	
				end
			end	else if(is_st_ctrl)begin // Control Change omni
				if(is_data_byte)begin 
					octrl<=databyte;
					if(is_allnotesoff)begin
						for(i4=0;i4<VOICES;i4++)begin
							key_on[i4]<=1'b0;
							key_val[i4]<=8'hff;					
						end	
						slot_off <= 0;
						cur_note <= 0;
						active_keys <= 0;
						off_note_error <= 1'b0;
					end
				end	else if(is_velocity)begin
					octrl_data<=databyte;
					octrl_cmd<=1'b1;
				end
			end	else if(is_st_sysex)begin // Sysex
				if(midi_bytes >=3 && midi_bytes <= 5)begin
					sysex_data[midi_bytes-3]<=databyte;
					if (midi_bytes == 5)begin
						sysex_cmd <= 1'b1;
					end
				end
			end	else if(is_st_pitch)begin // Control Change omni
				if(is_data_byte)begin 
					octrl<=databyte;
				end	else if(is_velocity)begin
					octrl_data<=databyte;
					pitch_cmd<=1'b1;
				end
			end	else if (is_st_note_off) begin// Note off omni
				if(is_data_byte)begin 
					for(i2=0;i2<VOICES;i2=i2+1)begin
						if(databyte==key_val[i2])begin
							active_keys <= active_keys-1;
							slot_off<=i2;
							key_on[i2]<=1'b0;
							key_val[i2]<=8'hff;
							off_note_error_flag <= 0;
							break;
						end
						else begin 
							off_note_error_flag <= 1;
						end
					end
				end	else if(is_velocity )begin
					if(off_note_error_flag)begin
						off_note_error <= 1'b1;
					end
					if(key_val[slot_off] == 8'hff)begin
						vel_on[slot_off]<=databyte;
						off_slot[VOICES-1]<=slot_off;
						for(i7=VOICES-1;i7>0;i7--)begin
							if(i7>active_keys)begin
								off_slot[i7-1] <= off_slot[i7];
							end
						end
					end
					if(active_keys == 0)begin
						for(i8=0;i8<VOICES;i8++)begin
							key_on[i8]<=1'b0;
							key_val[i8]<=8'hff;					
							vel_on[i8]<=0;
						end	
						slot_off <= 0;
						cur_note <= 0;
						slot_off<=0;
						cur_slot<=0;
					end
				end
			end			
		end			  
	end
	
endmodule
