module osc (
input		iRST_N,
input		tCLK,
input		sCLK_XVXENVS,
input		sCLK_XVXOSC,
input		[23:0]pitch[VOICES][V_OSC],
input signed[10:0]modulation[V_OSC][VOICES],
input		[7:0]o_offs[V_OSC],
input		[V_WIDTH-1:0]index,
input [V_WIDTH-1:0]waveform[V_OSC],
input		voice_free[VOICES][V_OSC],
output signed [16:0] sine_lookup_output[V_OSC]
);

wire [10:0]tablelookup[V_OSC];

parameter VOICES;
parameter V_OSC;
parameter V_WIDTH;
parameter O_WIDTH;
wire [10:0]phase_res[VOICES][V_OSC];
//wire reset[VOICES];

sine_lookup osc_sine[V_OSC](.clk( sCLK_XVXENVS ), .addr( tablelookup ), .value( sine_lookup_output ));
	
	generate
	genvar i33;
		for(i33=0;i33<V_OSC;i33++)begin : sine_gens
			assign tablelookup[i33] = phase_res[index][i33] + modulation[i33][index] + (o_offs[i33] << 3); 
		end
	endgenerate	

		nco #(.V_OSC(V_OSC),.O_WIDTH(O_WIDTH)) nco[VOICES] (
		.iRST_N(iRST_N) ,	// input  iRST_N_sig
		.tCLK ( tCLK ),
		.sCLK_XVXOSC (sCLK_XVXOSC ),
		.pitch ( pitch ),
		.reset ( voice_free ),
		.phase_res ( phase_res )
	);

endmodule
