module st_reg_ram(
//	output reg [15+36+36+7+20+8+6-1:0] q, //level, oldlevel, distance, st --//
	output reg [127:0] q, //level, oldlevel, distance, st --//
	input [127:0] d,
	input [V_WIDTH+E_WIDTH-1:0] write_address, read_address,
	input we, wclk, rclk
	);
parameter VOICES;
parameter V_ENVS;
parameter V_WIDTH = utils::clogb2(VOICES);
parameter E_WIDTH = utils::clogb2(V_ENVS);

//	reg [15+36+36+7+20+8+6-1:0] read_address_reg;
	reg [V_WIDTH+E_WIDTH-1:0] read_address_reg,write_address_reg;
	reg [127:0] mem [VOICES*V_ENVS];
	always @ (posedge wclk) begin
		if (we)
		mem[write_address_reg] <= d;
		write_address_reg <= write_address;
	end
	always @ (posedge rclk) begin
		q <= mem[read_address_reg];
		read_address_reg <= read_address;
	end
endmodule
