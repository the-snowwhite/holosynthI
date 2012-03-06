// 2 Env gen's for all osc's pr voice  --- 3 clk latency
// must run at 2x voice's x osc's clk
module env_gen_indexed (
	input					iRST_N,
	input 			[7:0]	r_r[V_ENVS][3:0],
	input signed	[7:0]	l_r[V_ENVS][3:0],
	input 					clk,
	input 					key_on_r[VOICES], 
	input		[E_WIDTH-1:0]	env_sel,		 
	input		[V_WIDTH-1:0]	voice_sel,		 
	output  signed[7:0]	level_mul,
	output reg				voice_free[VOICES]
);

parameter VOICES;
parameter V_ENVS;
parameter V_WIDTH = utils::clogb2(VOICES);
parameter E_WIDTH = utils::clogb2(V_ENVS);
parameter rate_mul = 7;
parameter num_mul = 22;
	parameter RES	 = 9'h000;  // Reset state <----	
	parameter IDLE 	 = 9'h1FE;	//9'b111111110;
	parameter RATE1  = 9'h002;	//9'b000000010;
	parameter LEVEL1 = 9'h004;	//9'b000000100;
	parameter RATE2  = 9'h008;	//9'b000001000;
	parameter LEVEL2 = 9'h010;	//9'b000010000;
	parameter RATE3  = 9'h020;	//9'b000100000;
	parameter LEVEL3 = 9'h040;	//9'b001000000;
	parameter RATE4  = 9'h080;	//9'b010000000;
	parameter LEVEL4 = 9'h100;	//9'b100000000;
	parameter mainvol_env_nr = 1;
// ------ Internal regs -------//
	wire [8:0]st_m;
	reg [8:0]st;
	reg [V_WIDTH-1:0]cur_voice;
	reg [E_WIDTH-1:0]cur_env;
	reg [7:0]r[3:0];
	reg signed [7:0]l[3:0];
	wire signed[36:0]level_m;
	reg signed[36:0]level;
	wire signed[7:0]oldlevel_m;
	reg signed[7:0]oldlevel;
	wire [20:0]distance_m;
	reg [20:0]distance;
	assign level_mul = level_m[36:29];
	
	st_reg_ram #(.VOICES(VOICES),.V_ENVS(V_ENVS))st_reg_ram_inst
(
	.q({cur_denom_m,cur_numer_m,level_m,oldlevel_m,distance_m,st_m}) ,	// output [15+36+36+7+20+8:0] q_sig
	.d({next_denom,next_numer,level,oldlevel,distance,st}) ,	// input [15+36+36+7+20+8:0] d_sig
	.write_address({cur_voice,cur_env}) ,	// input  write_address_sig
	.read_address({voice_sel,env_sel}) ,	// input  read_address_sig
	.we(1'b1) ,	// input  we_sig
	.wclk(clk), 	// input  clk_sig
	.rclk(~clk) 	// input  clk_sig
);
/*
volstmram	volstmram_inst (
	.data ( {next_denom,next_numer,level,oldlevel,distance,st} ),
	.rdaddress ( {voice_sel,env_sel} ),
	.rdclock ( ~clk ),
	.wraddress ( {cur_voice,cur_env} ),
	.wrclock ( clk ),
	.wren ( 1'b1 ),
	.q ( {cur_denom_m,cur_numer_m,level_m,oldlevel_m,distance_m,st_m} )
	);
*/	
	div24x8	div24x8_inst (
	.denom ( cur_denom_m ),
	.numer ( cur_numer_m ),
	.quotient ( quotient ),
	.remain ( )
	);
	wire [15:0]cur_denom_m;
	wire signed [36:0]cur_numer_m;
	reg [15:0]next_denom;
	reg signed [36:0]next_numer;
	wire signed[36:0]quotient;

	reg [E_WIDTH-1:0] oi;	
	reg [V_WIDTH-1:0] vi;
	reg init = 1;	

	always @(posedge clk or negedge iRST_N)begin 
		if(!iRST_N )begin
			cur_voice <= 0;
			cur_env <= 0;
			oi <= 0;
			vi <= 0;
			init <= 1'b1;
			st <= IDLE;
			level <= 0;
			oldlevel <= 0;
			distance <= 0;
		end	
		else if (!init) begin
			cur_voice <= voice_sel;
			cur_env <= env_sel;
			case(st_m)
			RES: 
				begin
					oi <= 0;
					vi <= 0;
					init <= 1;
				end
			IDLE:	
				begin
					if (key_on_r[cur_voice] == 1'b1)begin
						distance <= r[0]*r[0]<<rate_mul;						
						level <= 36'h0000000;
						oldlevel <= level[36:29]; 	
						next_numer <= (l[0]-oldlevel_m)<<<num_mul;
						next_denom <= r[0]*r[0];
						if(cur_env == mainvol_env_nr) voice_free[cur_voice] <= 1'b0;
						st <= RATE1;					
					end
					else begin
						distance <= 0;
						level <= 36'h0000000; 
						oldlevel <= level_m[36:29]; 
						st <= IDLE;
						if(cur_env == mainvol_env_nr) voice_free[cur_voice] <= 1'b1;
					end
				end		
			RATE1:	
				begin
					if (key_on_r[cur_voice]==1'b0)begin // Rate 1
						distance <= r[3]*r[3]<<rate_mul;
						level <= level_m; 
						oldlevel <= level_m[36:29]; 
						if(cur_env == mainvol_env_nr) voice_free[cur_voice] <= 1'b0;
						st <= RATE4;
					end	
					else begin 
						if(distance_m)begin
							distance <= distance_m-1;
							level <= level_m; 
							next_numer <= (l[0]-oldlevel_m)<<<num_mul;
							next_denom <= r[0]*r[0];
							level <= level_m + quotient;
							oldlevel <= oldlevel_m; 
							if(cur_env == mainvol_env_nr) voice_free[cur_voice] <= 1'b0;
							st <= RATE1;
						end
						else begin
							distance <= 0;
							level <= (l[0]<<<29);
							oldlevel <= level_m[36:29]; 
							if(cur_env == mainvol_env_nr) voice_free[cur_voice] <= 1'b0;
							st <= LEVEL1;
						end
					end
				end
			LEVEL1:	
				begin
					if (key_on_r[cur_voice] == 1'b0)begin // level 1
						distance <= r[3]*r[3]<<rate_mul;
						level <= level_m; 
						oldlevel <= level_m[36:29]; 
						next_numer <= (l[3]-oldlevel_m)<<<num_mul;
						next_denom <= r[3]*r[3];
						if(cur_env == mainvol_env_nr) voice_free[cur_voice] <= 1'b0;
						st <= RATE4;
					end
					else begin
						distance <= r[1]*r[1]<<rate_mul;
						level <= level_m; 
						oldlevel <= level_m[36:29]; 
						next_numer <= (l[1]-oldlevel_m)<<<num_mul;
						next_denom <= r[1]*r[1];
						if(cur_env == mainvol_env_nr) voice_free[cur_voice] <= 1'b0;
						st <= RATE2;
					end
				end	
			RATE2:	
				begin
					if (key_on_r[cur_voice] == 1'b0)begin // rate 2
						distance <= r[3]*r[3]<<rate_mul;
						level <= level_m; 
						oldlevel <= level_m[36:29]; 
						next_numer <= (l[3]-oldlevel_m)<<<num_mul;
						next_denom <= r[3]*r[3];
						if(cur_env == mainvol_env_nr) voice_free[cur_voice] <= 1'b0;
						st <= RATE4;
					end 
					else begin 
						if(distance_m)begin
							distance <= distance_m-1;
							level <= level_m; 
							next_numer <= (l[1]-oldlevel_m)<<<num_mul;
							next_denom <= r[1]*r[1];
							level <= level_m + quotient;
							oldlevel <= oldlevel_m; 
							if(cur_env == mainvol_env_nr) voice_free[cur_voice] <= 1'b0;
							st <= RATE2;
						end
						else begin
							distance <= 0;
							level <= l[1]<<<29;
							oldlevel <= level_m[36:29]; 
							if(cur_env == mainvol_env_nr) voice_free[cur_voice] <= 1'b0;
							st <= LEVEL2;		
						end
					end
				end
			LEVEL2:	
				begin
					if (key_on_r[cur_voice] == 1'b0)begin // level 2
						distance <= r[3]*r[3]<<rate_mul;
						level <= level_m; 
						oldlevel <= level_m[36:29]; 
						next_numer <= (l[3]-oldlevel_m)<<<num_mul;
						next_denom <= r[3]*r[3];
						if(cur_env == mainvol_env_nr) voice_free[cur_voice] <= 1'b0;
						st <= RATE4;
					end					
					else begin
						distance <= r[2]*r[2]<<rate_mul;
						level <= level_m; 
						oldlevel <= level_m[36:29]; 
						next_numer <= (l[2]-oldlevel_m)<<<num_mul;
						next_denom <= r[2]*r[2];
						if(cur_env == mainvol_env_nr) voice_free[cur_voice] <= 1'b0;
						st <= RATE3;
					end
				end	
			RATE3:	
				begin
					if (key_on_r[cur_voice] == 1'b0)begin // rate 3
						distance <= r[3]*r[3]<<rate_mul;
						level <= level_m; 
						oldlevel <= level_m[36:29]; 
						next_numer <= (l[3]-oldlevel_m)<<<num_mul;
						next_denom <= r[3]*r[3];
						if(cur_env == mainvol_env_nr) voice_free[cur_voice] <= 1'b0;
						st <=RATE4;
					end	
					else begin 
						if(distance_m)begin
							distance <= distance_m-1;
							level <= level_m; 
							oldlevel <= oldlevel_m; 
							next_numer <= (l[2]-oldlevel_m)<<<num_mul;
							next_denom <= r[2]*r[2];
							level <= level_m + quotient;
							if(cur_env == mainvol_env_nr) voice_free[cur_voice] <= 1'b0;
							st <= RATE3;
						end
						else begin
							distance <= 0;
							level <= l[2]<<<29;
							oldlevel <= level_m[36:29]; 
							if(cur_env == mainvol_env_nr) voice_free[cur_voice] <= 1'b0;
							st <= LEVEL3;		
						end
					end
				end	
			LEVEL3:	
				begin
					if (key_on_r[cur_voice] == 1'b0)begin // level 3					
						distance <= r[3]*r[3]<<rate_mul;
						level <= level_m; 
						oldlevel <= level_m[36:29]; 
						next_numer <= (l[3]-oldlevel_m)<<<num_mul;
						next_denom <= r[3]*r[3];
						if(cur_env == mainvol_env_nr) voice_free[cur_voice] <= 1'b0;
						st <= RATE4;
					end
					else begin
						distance <= 0;
						level <= l[2]<<<29;
						oldlevel <= level_m[36:29]; 
						if(cur_env == mainvol_env_nr) voice_free[cur_voice] <= 1'b0;
						st <= LEVEL3;
					end		
				end		
			RATE4:	
				begin
					if (key_on_r[cur_voice] ==  1'b1)begin
						distance <= r[0]*r[0]<<rate_mul; 
						level <= level_m; 
						oldlevel <= level_m[36:29]; 
						next_numer <= (l[0]-oldlevel_m)<<<num_mul;
						next_denom <= r[0]*r[0];
						if(cur_env == mainvol_env_nr) voice_free[cur_voice] <= 1'b0;
						st <= RATE1;
					end
					else begin 
						if(distance_m)begin // rate4
							distance <= distance_m-1;
							next_numer <= (l[3]-oldlevel_m)<<<num_mul;
							next_denom <= r[3]*r[3];
							level <= level_m + quotient;
							oldlevel <= oldlevel_m; 
							if(cur_env == mainvol_env_nr) voice_free[cur_voice] <= 1'b0;
							st <= RATE4;
						end
						else begin
							distance <= 0;
							level <= l[3]<<<29;
							if(cur_env == mainvol_env_nr) voice_free[cur_voice] <= 1'b1;
							oldlevel <= level_m[36:29]; 
							if(cur_env == mainvol_env_nr) voice_free[cur_voice] <= 1'b1;
							st <= LEVEL4;	
						end
					end
				end	
			LEVEL4:	
				begin
					if(l[3] == 8'h00)begin
						distance <= 20'h00000;
						level <= 36'h0000000;
						oldlevel <= 36'h0000000; 
						next_numer <= 36'h0000000;
						next_denom <= 8'h01;
						if(cur_env == mainvol_env_nr) voice_free[cur_voice] <= 1'b1;
						st <= IDLE;
					end	
					else begin
						if (key_on_r[cur_voice] ==  1'b1)begin
							distance <= r[0]*r[0]<<rate_mul;
							level <= level_m; 
							oldlevel <= level_m[36:29]; 
							next_numer <= (l[0]-oldlevel_m)<<<num_mul;
							next_denom <= r[0]*r[0];
							if(cur_env == mainvol_env_nr) voice_free[cur_voice] <= 1'b0;
							st <= RATE1;
						end	
						else begin
							distance <= 20'h00000;
							level <= l[3]<<<29;
							oldlevel <= level_m[36:29]; 
							next_numer <= 36'h0000000;
							next_denom <= 8'h01;
							if(cur_env == mainvol_env_nr) voice_free[cur_voice] <= 1'b1;
							st <= LEVEL4;
						end
					end	
				end		
//			default: st <= RES;	
			default: st <= IDLE;	
			endcase
		r <= r_r[env_sel];
		l <= l_r[env_sel];
		end			
		else begin
			oi <= oi + 1;
			cur_voice <= vi; 
			cur_env <= oi;
			level <= 0;
			oldlevel <= 0;
			distance <= 0;
			st <= IDLE;		
			next_numer <= 0;
			next_denom <= 1;
			if(oi == V_ENVS-1) begin
				if(vi<VOICES-1) begin
					vi <= vi +1;
				end
				else begin init <= 0; 
				end					 
			end
		end
	end

endmodule
