module disp_ram(
	output reg [7:0] q, //
	input [7:0] d,
	input [9:0] write_address, read_address,
	input we, wclk, rclk
	);

	reg [9:0] read_address_reg,write_address_reg;
	reg [7:0] mem [1023:0];
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
