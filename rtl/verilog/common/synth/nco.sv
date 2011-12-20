
module nco (
input	iRST_N,
input	tCLK,
input	sCLK_XVXOSC,
input	[23:0]pitch[V_OSC],
input	reset[V_OSC],

output reg signed[10:0]phase_res[V_OSC]
);

parameter V_OSC;
parameter O_WIDTH;

	wire [O_WIDTH:0]i1;
	reg [35:0]phase_acc[V_OSC];   // 34 bits phase accumulator
	generate
	genvar i33;
	for(i33=0;i33<V_OSC;i33++)begin : phase_gens
		always @(posedge tCLK or posedge reset[i33] or negedge iRST_N)begin
			if(reset[i33] || !iRST_N) phase_acc[i33] <= 0;
			else phase_acc[i33] <= phase_acc[i33] + pitch[i33];   // 
		end
	end
	endgenerate	
		
	always @(posedge sCLK_XVXOSC)begin
		for(i1=0;i1<V_OSC;i1++)begin
			phase_res[i1] <= phase_acc[i1][35:25];		
		end
	end
	
endmodule
