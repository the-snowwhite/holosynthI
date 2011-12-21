// sine lookup value module using two symmetries
// appears like a 2048x10bits LUT even if it uses a 512x10bits internally
// 3 clock latency

module sine_lookup(clk, addr, value);
input clk;
input [10:0]addr;
output [16:0]value;

wire [15:0] LUT_output;

blockram512x16bits_2clklatency
my_DDS_sine_LUT(                   // the LUT must contain only one quarter of the sine wave
    .clock(clk),
    .address(addr[9] ? ~addr[8:0] : addr[8:0]),   // first symmetry
    .q(LUT_output)
);

// for the second symmetry, we need to use addr[10]
// but since we use a blockram that has 2 clock latencies on reads
// we need a two-clock delayed version of addr[10] here
reg addr10_delay1; always @(posedge clk) addr10_delay1 <= addr[10];
reg addr10_delay2; always @(posedge clk) addr10_delay2 <= addr10_delay1;

// now we can apply the second symmetry (and add a third latency to the module output for best performance)
//reg [16:0] value; always @(posedge clk) value <= addr10_delay2 ? {1'b1,-LUT_output} : {1'b0,LUT_output};

reg [16:0] value;
	always @(posedge clk) value <= (!LUT_output ? {1'b0,LUT_output} :
			addr10_delay2 ? {1'b1,-LUT_output} : {1'b0,LUT_output});

endmodule
