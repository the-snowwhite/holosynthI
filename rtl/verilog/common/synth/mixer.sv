module mixer (
// Inputs -- //
	// Clock
	input sCLK_XVXENVS, // clk
	// reset
	input	iRST_N,
	input   [17:0]	switch,
	//
	input	signed [7:0]level_mul, // envgen output				
	// 
	input  signed [7:0]osc_lvl[V_OSC],		// osc_lvl	osc_buf[2]
	input  signed [7:0]osc_mod[V_OSC],		// osc_mod    osc_buf[3]
	input  signed [7:0]osc_feedb[V_OSC],		// osc_feedb  osc_buf[4]
	input  signed [7:0]m_vol,				// m_vol		com_buf[1]
	input  signed [7:0]mat_buf[32][V_OSC],
	// pitch
	input signed [16:0]sine_lut_out[V_OSC],
// Oututs -- //
	//	env gen
	output	xxxx_max,
	output	[E_WIDTH-1:0]e_env_sel, // 2 env's 
	output 	[V_WIDTH-1:0]e_voice_sel,
	// osc
	output reg	[V_WIDTH-1:0]osc_voice_index,
	output reg signed [10:0]modulation[V_OSC][VOICES],
	// sound data out
	output reg signed [15:0]rsound_o
);
	
parameter 	VOICES;
parameter 	V_OSC; // oscs per Voice
parameter 	V_ENVS; // envs per Voice
parameter V_WIDTH = utils::clogb2(VOICES);
parameter O_WIDTH = utils::clogb2(V_OSC);
parameter E_WIDTH = utils::clogb2(V_ENVS);

////////////////   	Main state machine		////////////////	
//-----		Internals		-----//
	reg	[V_WIDTH-1:0]lvl_mul_index;
	reg	[V_WIDTH-1:0]mod_index;
	reg	[V_WIDTH+E_WIDTH:0]xxxx;

//-----	 combinatorial		-----//
//	env gen
	assign xxxx_max = (xxxx == (VOICES*V_ENVS*2)-1) ? 1:0;
	assign e_voice_sel = xxxx[V_WIDTH+E_WIDTH-1:E_WIDTH];
	assign e_env_sel = xxxx[E_WIDTH-1:0]; // 2 env's 

	wire signed [24:0]rsound_sum = ((rsound_sum_w) * m_vol);// m_vol
	wire signed[24:0] rsound_sum_w;
	wire signed [23:0]osc_sound_data[V_OSC];	
	wire signed [23:0]osc_mod_data[V_OSC];
	wire signed [23:0]osc_feedback_data[V_OSC];
//	wire signed [13:0]m_in_all[V_OSC];
//	wire signed [13:0]fb_in_all[V_OSC];
	wire signed [11:0]m_in_all[V_OSC];
	wire signed [18:0]m_in_all_x_mat[V_OSC];
	wire signed [11:0]fb_in_all[V_OSC];
	wire signed [18:0]fb_in_all_x_mat[V_OSC];
//	wire signed [21:0]osc_mod_data_sum[V_OSC];
//	wire signed [21:0]osc_feedback_data_sum[V_OSC];
	wire signed [18:0]osc_mod_data_sum[V_OSC];
	wire signed [18:0]osc_feedback_data_sum[V_OSC];
	wire signed [10:0]matrix_data[V_OSC];
	wire [23:0]sum[V_OSC];
	wire signed [15:0]osc_sine_mul_data[V_OSC];

	wire [V_WIDTH:0] v1;
	wire [O_WIDTH:0] o1,oi1;

	generate genvar aa6;
	for(aa6=0;aa6<V_OSC;aa6++)begin : acc_osc_summer
		assign sum[aa6] = sine_lut_out[aa6] * level_mul_r[(lvl_mul_index)][({aa6,1'b0})];
		assign osc_sine_mul_data[aa6] = sum[aa6][23:8];
	end
	endgenerate
	
	generate genvar aa5;
	for(aa5=0;aa5<V_OSC;aa5++)begin : sound_lvl_mod
		assign osc_sound_data[aa5] = (osc_sine_mul_data[aa5] * (osc_lvl[aa5]));// osc_lvl[aa5]
		assign osc_mod_data[aa5] = (osc_sine_mul_data[aa5] * (osc_mod[aa5]));// osc_mod[aa5]
		assign osc_feedback_data[aa5] = ((sine_lut_out[aa5]>>>1) * (osc_feedb[aa5]));// osc_feedb[aa5]
	end
	endgenerate

// Matrix
	generate genvar am5,oo1;
/*	if (V_OSC <= 1) 
//	begin : sum_one_osc_mod

	assign m_in_all[0] = 			osc_mod_data_r[0];
	assign fb_in_all[0] = 	osc_feedb_data_r[0];
	assign osc_mod_data_sum[0] = 			m_in_all[0] * mat_buf[0][0]; 
	assign osc_feedback_data_sum[0] = 	fb_in_all[0] * mat_buf[0+8][0];

	end 
	else 
*/	
	begin : sum_all_osc_mod_feedb_outs	
		for(am5=0;am5<V_OSC;am5++)begin : matrix_mod
			assign m_in_all[am5] =	m_sum(osc_mod_data_r);
			assign fb_in_all[am5] =	fb_sum(osc_feedb_data_r);
		end
	end
		


	begin : sum_osc_modulation_ins	
		for(am5=0;am5<V_OSC;am5++)begin : matrix_mod
//			for(oo1=1;oo1<V_OSC;oo1++)begin : osc_vol_sum
//				assign osc_mod_data_sum[am5] = m_in_all[0] * mat_buf[0][am5] + m_in_all[oo1] * mat_buf[oo1][am5];
//				assign osc_feedback_data_sum[am5] =	fb_in_all[0] * mat_buf[0+8][am5] + fb_in_all[oo1] * mat_buf[oo1+8][am5];
	
			assign m_in_all_x_mat[am5] = x_mat_m(m_in_all,mat_buf[am5]);
			assign osc_mod_data_sum[am5] = x_m_sum(m_in_all_x_mat);

			assign fb_in_all_x_mat[am5] = x_mat_fb(fb_in_all,mat_buf[am5+8]);
			assign osc_feedback_data_sum[am5] = x_fb_sum(fb_in_all_x_mat);

//			assign osc_mod_data_sum[am5] = x_mat_m(m_in_all,mat_buf[am5]);
//			assign osc_feedback_data_sum[am5] = x_mat_fb(fb_in_all,mat_buf[am5+8]);
//			end
		end
	end
	
	endgenerate
/*
	function integer m_sum;
		input signed[10:0] a[V_OSC];
		begin
		case (V_OSC) 
			1 :	m_sum =a[0];
			2 :	m_sum =a[0]+a[1];
			3 :	m_sum =a[0]+a[1]+a[2];
			4 :	m_sum =a[0]+a[1]+a[2]+a[3];
			5 :	m_sum =a[0]+a[1]+a[2]+a[3]+a[4];
			6 :	m_sum =a[0]+a[1]+a[2]+a[3]+a[4]+a[5];
			7 :	m_sum =a[0]+a[1]+a[2]+a[3]+a[4]+a[5]+a[6];
			8 :	m_sum =a[0]+a[1]+a[2]+a[3]+a[4]+a[5]+a[6]+a[7];
			default : m_sum=0;
		endcase
		end
	endfunction

	function integer mfb_sum;
		input signed[18:0] a[V_OSC];
		begin
		case (V_OSC) 
			1 :	mfb_sum =a[0];
			2 :	mfb_sum =a[0]+a[1];
			3 :	mfb_sum =a[0]+a[1]+a[2];
			4 :	mfb_sum =a[0]+a[1]+a[2]+a[3];
			5 :	mfb_sum =a[0]+a[1]+a[2]+a[3]+a[4];
			6 :	mfb_sum =a[0]+a[1]+a[2]+a[3]+a[4]+a[5];
			7 :	mfb_sum =a[0]+a[1]+a[2]+a[3]+a[4]+a[5]+a[6];
			8 :	mfb_sum =a[0]+a[1]+a[2]+a[3]+a[4]+a[5]+a[6]+a[7];
			default : mfb_sum=0;
		endcase
		end
	endfunction
*/
	function int x_mat_m(int m_in[V_OSC], int mat[V_OSC]);
		int i,res[V_OSC];
			for(i=0;i<V_OSC;i++)begin
				res[i] = m_in[i]*mat[i];
			end
			return res.sum;
	endfunction

	function int x_mat_fb(int m_in[V_OSC], int mat[V_OSC]);
		int i,res[V_OSC];
			for(i=0;i<V_OSC;i++)begin
				res[i] = m_in[i]*mat[i];
			end
			return res.sum;
	endfunction

/*
	assign m_in_all[0] = 			osc_mod_data_r[0] + osc_mod_data_r[1];
	assign m_in_all[1] = 			osc_mod_data_r[0] + osc_mod_data_r[1];

	assign fb_in_all[0] = 	osc_feedb_data_r[0] + osc_feedb_data_r[1];
	assign fb_in_all[1] = 	osc_feedb_data_r[0] + osc_feedb_data_r[1];
*/

/*	assign osc_mod_data_sum[0] = 			(m_in_all[0]*mat_buf[0][0])+(m_in_all[1]*mat_buf[1][0])+(m_in_all[2]*mat_buf[2][0])+(m_in_all[3]*mat_buf[3][0]);									
	assign osc_mod_data_sum[1] = 			(m_in_all[0]*mat_buf[0][1])+(m_in_all[1]*mat_buf[1][1])+(m_in_all[2]*mat_buf[2][1])+(m_in_all[3]*mat_buf[3][1]);
	assign osc_mod_data_sum[2] = 			(m_in_all[0]*mat_buf[0][2])+(m_in_all[1]*mat_buf[1][2])+(m_in_all[2]*mat_buf[2][2])+(m_in_all[3]*mat_buf[3][2]);
	assign osc_mod_data_sum[3] = 			(m_in_all[0]*mat_buf[0][3])+(m_in_all[1]*mat_buf[1][3])+(m_in_all[2]*mat_buf[2][3])+(m_in_all[3]*mat_buf[3][3]);

	assign osc_feedback_data_sum[0] = 	(fb_in_all[0]*mat_buf[0+8][0])+(fb_in_all[1]*mat_buf[1+8][0])+(fb_in_all[2]*mat_buf[2+8][0])+(fb_in_all[3]*mat_buf[3+8][0]);													
	assign osc_feedback_data_sum[1] = 	(fb_in_all[0]*mat_buf[0+8][1])+(fb_in_all[1]*mat_buf[1+8][1])+(fb_in_all[2]*mat_buf[2+8][1])+(fb_in_all[3]*mat_buf[3+8][1]);
	assign osc_feedback_data_sum[2] = 	(fb_in_all[0]*mat_buf[0+8][2])+(fb_in_all[1]*mat_buf[1+8][2])+(fb_in_all[2]*mat_buf[2+8][2])+(fb_in_all[3]*mat_buf[3+8][2]);
	assign osc_feedback_data_sum[3] = 	(fb_in_all[0]*mat_buf[0+8][3])+(fb_in_all[1]*mat_buf[1+8][3])+(fb_in_all[2]*mat_buf[2+8][3])+(fb_in_all[3]*mat_buf[3+8][3]);
*/

/*	generate
		if (V_OSC <= 1) 
		begin : sum_one_osc
			assign rsound_sum_w = osc_sound_data_r_sum[0];
		end 
		else 
		begin : sum_all_oscs	
			genvar oo1;
			for(oo1=0;oo1<V_OSC;oo1=oo1+2)begin : osc_vol_sum
				assign rsound_sum_w = osc_sound_data_r_sum[oo1] + osc_sound_data_r_sum[oo1+1];
			end
		end
	endgenerate
	
	signed int sum_array(char* A, unsigned int n) {
	signed int sum=0;
	for (unsigned int i=0;i<n; i++) {
		sum += A[i];
	}
	return sum;
} 
*/
	function int m_sum(int a[V_OSC]);
		return a.sum;
	endfunction

	function int fb_sum(int a[V_OSC]);
		return a.sum;
	endfunction

	function int x_m_sum(int a[V_OSC]);
		return a.sum;
	endfunction

	function int x_fb_sum(int a[V_OSC]);
		return a.sum;
	endfunction

	function int r_sum(int a[V_OSC]);
		return a.sum;
	endfunction

//	wire signed[22:0] a[V_OSC] = osc_sound_data_r_sum;
//	assign rsound_sum_w =a[0]+a[1]+a[2]+a[3];

	assign rsound_sum_w = r_sum(osc_sound_data_r_sum);
	assign matrix_data = matrix_data_r;

///////////////////////// 	Clock driven 					///////////////////////////
	reg signed [7:0]level_mul_r[VOICES][V_ENVS];// note Double up for  new 1xclk envgen
	reg [V_WIDTH-1:0]cur_voice;
	reg [E_WIDTH-1:0]cur_env; // note --> double up

	reg signed[10:0]osc_mod_data_r[V_OSC];
	reg signed[10:0]osc_feedb_data_r[V_OSC];
	reg signed[22:0]osc_sound_data_r_sum[V_OSC];
	reg signed[10:0]matrix_data_r[V_OSC];
	reg[VOICES+8:0] sh_reg = 0;


	always @(negedge sCLK_XVXENVS)begin
		cur_voice <= e_voice_sel;
		cur_env <= e_env_sel;
		level_mul_r[cur_voice][cur_env] <= level_mul;
	end
	
	always @(negedge sCLK_XVXENVS or negedge iRST_N)begin
		if(!iRST_N)begin xxxx <= 0;end
		else begin
			if(xxxx_max )begin xxxx <= 0;end
			else begin
				xxxx <= xxxx+1;
			end
		end
	end
	
	always @(negedge sCLK_XVXENVS or negedge iRST_N)begin 
		if(!iRST_N ) begin osc_voice_index<=0;lvl_mul_index<=0;mod_index<=0;end 
		else begin
			if( xxxx_max)
				begin osc_voice_index<=0;lvl_mul_index<=0;mod_index<=0;end // lvl_mul_index<=VOICES+VOICES-4;xsel<=VOICES+VOICES-6;
			else begin
				if(xxxx < VOICES) sh_reg <= (sh_reg  << 1)+ 1; else sh_reg <= sh_reg << 1;
				if(sh_reg[1])begin osc_voice_index<=osc_voice_index+1;end // osc_voice_index --> osc index
				else begin osc_voice_index <=0;end
										  // <-- sine lut out * levelmul[voice sel]
										 // + osc_sound + osc_feedb_data_r + osc_mod_data_r 	
									    // all oscs at once
				if(sh_reg[2] && !sh_reg[3])begin lvl_mul_index<=0; for(o1=0;o1<V_OSC;o1++)begin osc_sound_data_r_sum[o1] <= 0;end end  // osc_output_data, 
				if(sh_reg[3])begin
					for(o1=0;o1<V_OSC;o1++)begin
						osc_mod_data_r[o1] <= osc_mod_data[o1][23:13];
						osc_feedb_data_r[o1] <= osc_feedback_data[o1][23:13];
						osc_sound_data_r_sum[o1] <= osc_sound_data_r_sum[o1] + (osc_sound_data[o1]>>>7);
					end lvl_mul_index <= lvl_mul_index+1; 	// <-- sine lut out * levelmul[voice sel]
					// + osc_sound + feedb_data + osc_mod_data 	// all oscs at once
				end
				if(sh_reg[4])begin				
/*					for(o1=0;o1<V_OSC;o1++)begin
						for(oi1=0;oi1<V_OSC;oi1++)begin
							if(oi1 != o1)begin
								modulation[o1][mod_index] <= osc_mod_data_r[oi1]+ osc_feedb_data_r[o1]; 
							end
						end				 	
					end
*/
					for(o1=0;o1<V_OSC;o1++)begin
//						matrix_data_r[o1] <= (osc_mod_data_sum[o1][21:11]) + (osc_feedback_data_sum[o1][21:11]);
						matrix_data_r[o1] <= (osc_mod_data_sum[o1][18:8]) + (osc_feedback_data_sum[o1][18:8]);
					end
				end
				if(sh_reg[4] && !sh_reg[5]) mod_index<=0;
				if(sh_reg[5])begin
					for(o1=0;o1<V_OSC;o1++)begin
						modulation[o1][mod_index] <= matrix_data_r[o1];// --> NB TEST ? include -->osc_buf[4'hA] m_dest,osc_buf[4'hB] f_dest //m_in_1
					end
					mod_index <= mod_index+1; // modulation <-- osc_mod data_r + osc_feedb_data_r 
				end
//				if(sh_reg[5+VOICES] && !sh_reg[6+VOICES])begin
				if(sh_reg[6+VOICES] && !sh_reg[7+VOICES])begin
/* output-->*/	if(switch[1])rsound_o <= rsound_sum >>> 8;else rsound_o <= rsound_sum >>> 9;  
				end
			end
		end
	end

//--------------		End  	Main state machine		--------------//
	
	
	
	
endmodule
