module char_disp
(
	// Input Ports
	input [11:0]counterX,
	input [11:0]counterY,
	input [9:0]ram_Adr,
	input [7:0]ram_Data,
	input clk,
	input wclk,
	input write_Ram,

	// Output Ports
	output char_bit,
	output intextarea
	// Inout Ports
);

	// Module Item(s)
	wire [7:0] CharacterRAM_dout;
/*
	ram8x2048	ram8x2048_inst (
	.clock ( ~clk ),
	.data ( ram_Data ),
	.rdaddress ( {counterY[8:4],counterX[9:4]} ),
	.wraddress ( ram_Adr ),
	.wren ( write_Ram ),
	.q ( CharacterRAM_dout )
	);
*/

	reg[5:0]ra_x;
	
	disp_ram st_reg_ram_inst
(
	.q(CharacterRAM_dout) ,	// output  q_sig
	.d(ram_Data) ,	
	.write_address(ram_Adr) ,	// input  write_address_sig
//	.read_address({counterY[7:4],(counterX[9:4]}) ,	// input  read_address_sig
	.read_address({counterY[7:4],ra_x}) ,	// input  read_address_sig
	.we(write_Ram) ,	// input  we_sig
	.wclk(wclk), 	// input  clk_sig
	.rclk(~clk) 	// output  clk_sig
);

	charrom_64	charrom_64_inst (
		.address ({ CharacterRAM_dout,counterY[3:1] }),
		.clock ( clk ),
		.q ( raster8 )
		);

	wire [8:0] raster8;
	
	assign intextarea = (counterY > 0 && counterY < 256 && counterX >= 1 && counterX<=(800-32));
	
	reg [2:0]x_ind;
	reg [7:0]char_byte;
	always @(posedge clk)begin
		ra_x  <= counterX[9:4]-1;
		x_ind[2:0] <= 7 - counterX[3:1];
	end
	
	assign char_bit = raster8[x_ind] & intextarea;

endmodule
