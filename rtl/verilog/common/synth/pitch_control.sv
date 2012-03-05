module pitch_control (
	input			iRST_N,
	input			clk,
	input 			[7:0]rkey[VOICES],
	input 			[7:0]osc_ct[V_OSC],
	input 			[7:0]osc_ft[V_OSC],
	input			[7:0]b_ct[V_OSC],// base pitch
	input			[7:0]b_ft[V_OSC],// base tune
	input 			[7:0]pb_value,
	input 			[13:0]pitch_val,
	input 			[7:0]k_scale[V_OSC],
	input			[17:0]switch,
	output reg signed [23:0]osc_index_val[VOICES][V_OSC]
);

parameter VOICES;
parameter V_OSC;
parameter V_WIDTH;
parameter O_WIDTH;

	wire [8:0]key = (b_ct[ox] <= 63) ? 
		((rkey[vx])-( 64 - b_ct[ox])+128) : ((rkey[vx])+(b_ct[ox][5:0])+128);	

////////		Internals		////////	
	wire [23:0]ct_res;	
	wire [23:0]pb_res;	
	wire [23:0]ft_ct_res;	
	wire [23:0]ft_pb_res;	
	wire [23:0]key_scale;	

	constmap constmap(.sound(key), .constant(ct_res));

	wire [8:0] ft_ct_key = (b_ft[ox] <= 63) ? (key-1) : (key+1);
	constmap ct_pb_pitchmap(.sound(ft_ct_key), .constant(ft_ct_res));
// Fine tune  //
		wire [29:0]ft_range_l = (ct_res-ft_ct_res)*(64 - b_ft[ox]);//b_ft(down)	
	wire [29:0]ft_range_h = ((ft_ct_res - ct_res)*b_ft[ox][5:0]);// b_ft(up)

	wire [23:0]ft_pitch = (b_ft[ox] <= 63) ? (ct_res- (ft_range_l>>6)) //b_ft(down)
	: ((ct_res + (ft_range_h>>6)));//b_ft(up)

// Pitch bend  //
	wire [8:0] pitch_key = (pitch_val <= 14'h1fff) ? (key-pb_value) : (key+pb_value);
	constmap pitchmap_pb(.sound(pitch_key), .constant(pb_res));
//	wire [8:0] ft_pitch_key = (b_ft[ox] <= 63) ? (key-(pb_value+1)) : (key+(pb_value+1));

	wire [8:0] pb_pitch_key = (pitch_val <= 14'h1fff) ? (key-(pb_value+1)) : (key+(pb_value+1));
	constmap ft_pb_pitchmap(.sound(pb_pitch_key), .constant(ft_pb_res));
	
	wire [36:0]pb_range_l = (ft_pitch-pb_res)*(14'h2000-pitch_val);//pb(down)
	wire [36:0]pb_range_h = ((pb_res - ft_pitch)*pitch_val[12:0]);//pb(up)

	wire [42:0]pb_ft_range_l = (b_ft[ox] <= 63) ? (pb_res - ft_pb_res)*(14'h2000-pitch_val)*(64-b_ft[ox])
	: (pb_res - ft_pb_res)*(14'h2000-pitch_val)*b_ft[ox][5:0];
	
	wire [42:0]pb_ft_range_h = (b_ft[ox] <= 63) ? ((ft_pb_res - pb_res)*pitch_val[12:0]*(64-b_ft[ox]))//pb_up b_ft(down)
	: ((ft_pb_res - pb_res)*pitch_val[12:0]*b_ft[ox][5:0]);// pb(up) b_ft(up)

	wire [23:0]pitch_ = (pitch_val <= 14'h1fff) ? (b_ft[ox] <= 63) ? (ft_pitch-(pb_range_l>>13)-(pb_ft_range_l>>19))//pb(down) b_ft(down) 
	: (ft_pitch-(pb_range_l>>13)+(pb_ft_range_l>>19)) //pb(down) b_ft_(up)
	: (b_ft[ox] <= 63) ? (ft_pitch+(pb_range_h>>13)-(pb_ft_range_h>>19))//pb(up) b_ft(down)
	: (ft_pitch+(pb_range_h>>13)+(pb_ft_range_h>>19));// pb(up)



// keyboard rate scaling //
	wire [23:0]base_pitch_val; 
//	assign base_pitch_val = base_pitch + (k_scale[ox] << 4);
	assign base_pitch_val = pitch_ + (k_scale[ox] << 4);
	
	wire [30:0]osc_res;
	wire [30:0]osc_res_l;
	wire [30:0]osc_res_h;
	wire [23:0]osc_transp_range_l;
	wire [23:0]osc_transp_range_h;
	wire [30:0]osc_transp_val_l;
	wire [30:0]osc_transp_val_h;
	wire [7:0]osc_ct_64;
	reg [O_WIDTH+V_WIDTH-1:0]x;// not double size !
	wire [O_WIDTH-1:0]ox = x[O_WIDTH-1:0];
	wire [V_WIDTH-1:0]vx = x[V_WIDTH+O_WIDTH-1:O_WIDTH];	
	reg signed [23:0]osc_pitch_val;

		assign osc_ct_64 = (osc_ct[ox] <= 8'd64) ?
			(64-osc_ct[ox]+1):(osc_ct[ox][5:0]+1);

	always @(posedge clk or negedge iRST_N)begin
		if(!iRST_N)begin
			x <=0;
		end
		else begin
			x <= x+1;
			osc_index_val[vx][ox] <= (osc_ft[ox] <= 8'h40) ? 
				(osc_res - (osc_transp_val_l>>6)) : 
				(osc_res + (osc_transp_val_h>>6));  	
		end
	end

	assign osc_res =  (osc_ct[ox] <= 8'd64) ?// M:C Ratio
		(base_pitch_val / (osc_ct_64)): 
		(base_pitch_val * (osc_ct_64));

	assign osc_res_l =  (osc_ct[ox] <= 8'd64) ?// M:C Ratio
		(base_pitch_val / (osc_ct_64+1)):
		(base_pitch_val * (osc_ct_64-1));

	assign osc_res_h =  (osc_ct[ox] <= 8'd63) ?// M:C Ratio 
		(base_pitch_val / ((osc_ct_64)-1)):
		(base_pitch_val * (osc_ct_64+1));
				
	assign osc_transp_range_l = osc_res - osc_res_l; 
	assign osc_transp_range_h = osc_res_h - osc_res;
	assign osc_transp_val_l = (64 - osc_ft[ox]) * osc_transp_range_l;  //
	assign osc_transp_val_h = (osc_ft[ox][5:0]) * osc_transp_range_h;	 //

endmodule
