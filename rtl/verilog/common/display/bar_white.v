module  bar_white(
input [11:0]CounterX,
output L_5,
output L_6,
output L_7,
output M_1,
output M_2,
output M_3,
output M_4,
output M_5,
output M_6,
output M_7,
output H_1,
output H_2,
output H_3,
output H_4,
output H_5
);
parameter white_x_off = 11;
wire [11:0]xdeta=22;

wire [11:0]xd_t =xdeta+2;
assign L_5= ((CounterX>=(white_x_off+xd_t*0)) && ( CounterX<=(white_x_off+xd_t*1)) )?1:0;
assign L_6= ((CounterX>=(white_x_off+xd_t*1)) && ( CounterX<=(white_x_off+xd_t*2)) )?1:0;  
assign L_7= ((CounterX>=(white_x_off+xd_t*2)) && ( CounterX<=(white_x_off+xd_t*3)) )?1:0;  
assign M_1= ((CounterX>=(white_x_off+xd_t*3)) && ( CounterX<=(white_x_off+xd_t*4)) )?1:0;  
assign M_2= ((CounterX>=(white_x_off+xd_t*4)) && ( CounterX<=(white_x_off+xd_t*5)) )?1:0;  
assign M_3= ((CounterX>=(white_x_off+xd_t*5)) && ( CounterX<=(white_x_off+xd_t*6)) )?1:0;  
assign M_4= ((CounterX>=(white_x_off+xd_t*6)) && ( CounterX<=(white_x_off+xd_t*7)) )?1:0;  
assign M_5= ((CounterX>=(white_x_off+xd_t*7)) && ( CounterX<=(white_x_off+xd_t*8)) )?1:0;  
assign M_6= ((CounterX>=(white_x_off+xd_t*8)) && ( CounterX<=(white_x_off+xd_t*9)) )?1:0;  
assign M_7= ((CounterX>=(white_x_off+xd_t*9)) && ( CounterX<=(white_x_off+xd_t*10)) )?1:0;  
assign H_1= ((CounterX>=(white_x_off+xd_t*10)) && ( CounterX<=(white_x_off+xd_t*11)) )?1:0;  
assign H_2= ((CounterX>=(white_x_off+xd_t*11)) && ( CounterX<=(white_x_off+xd_t*12)) )?1:0;  
assign H_3= ((CounterX>=(white_x_off+xd_t*12)) && ( CounterX<=(white_x_off+xd_t*13)) )?1:0;  
assign H_4= ((CounterX>=(white_x_off+xd_t*13)) && ( CounterX<=(white_x_off+xd_t*14)) )?1:0;  
assign H_5= ((CounterX>=(white_x_off+xd_t*14)) && ( CounterX<=(white_x_off+xd_t*15)) )?1:0;  

endmodule
