module bar_blank(
input [11:0]CounterX,
output Hu4,
output Hu2,
output Hu1,
output Mu6,
output Mu5,
output Mu4,
output Mu2,
output Mu1,
output Lu6,
output Lu5,
output Lu4
);
parameter blank_x_off =0;
wire [11:0]bxdeta=22;

wire [11:0]bxd_t =bxdeta+2;

assign Lu4=((CounterX>=(blank_x_off+bxd_t*0)) && ( CounterX<=(blank_x_off+bxd_t*1)))?1:0;//+4
assign Lu5=((CounterX>=(blank_x_off+bxd_t*1)) && ( CounterX<=(blank_x_off+bxd_t*2)))?1:0;//+2
assign Lu6=((CounterX>=(blank_x_off+bxd_t*2)) && ( CounterX<=(blank_x_off+bxd_t*3)))?1:0;//+1
assign Mu1=((CounterX>=(blank_x_off+bxd_t*4)) && ( CounterX<=(blank_x_off+bxd_t*5)))?1:0;//6
assign Mu2=((CounterX>=(blank_x_off+bxd_t*5)) && ( CounterX<=(blank_x_off+bxd_t*6)))?1:0;//5
assign Mu4=((CounterX>=(blank_x_off+bxd_t*7)) && ( CounterX<=(blank_x_off+bxd_t*8)))?1:0;//4
assign Mu5=((CounterX>=(blank_x_off+bxd_t*8)) && ( CounterX<=(blank_x_off+bxd_t*9)))?1:0;//2
assign Mu6=((CounterX>=(blank_x_off+bxd_t*9)) &&( CounterX<=(blank_x_off+bxd_t*10)))?1:0;//1
assign Hu1=((CounterX>=(blank_x_off+bxd_t*11)) &&( CounterX<=(blank_x_off+bxd_t*12)))?1:0;//-6
assign Hu2=((CounterX>=(blank_x_off+bxd_t*13)) &&( CounterX<=(blank_x_off+bxd_t*14)))?1:0;//-5
assign Hu4=((CounterX>=(blank_x_off+bxd_t*15)) &&( CounterX<=(blank_x_off+bxd_t*16)))?1:0;//-4

endmodule
