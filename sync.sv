//`timescale 1ps / 1ps


module sync(input clk,
            input rst,
            input in,
            output reg out);

reg trans;

always @(posedge clk or negedge rst) begin 
  if (!rst) begin 
    trans <= #TIH 1'b0;
    out   <= #TIH 1'b0;
  end else begin 
    trans <= #TIH in;
    out   <= #TIH trans;
  end
 end 
endmodule 
