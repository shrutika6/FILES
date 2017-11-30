//`timescale 1ps / 1ps

module fifo_async(wclk,rclk,rst,din,push,pull,dout,full,empty);

//-------------------------------------------------------------//
//                   PARAMETERS                                //
//-------------------------------------------------------------//

parameter WIDTH = 8;
parameter DEPTH = 16;
parameter ADDR  = 5;

//------------------------------------------------------------//
//                  INPUT OUTPUT SIGNALS                      //  
//------------------------------------------------------------//

input wclk,rclk,rst;
input [WIDTH-1:0] din;
input push,pull; 

output empty,full;
output [WIDTH-1:0] dout;

//------------------------------------------------------------//
//             INTERMEDIATE SIGNALS                           //
//------------------------------------------------------------//
wire            full,empty;
wire            wen,ren;
reg [ADDR-1:0]  wptr_bi,rptr_bi;
reg [ADDR-1:0]  wptr_bi_next,rptr_bi_next;
reg [ADDR-1:0]  wptr_gray,rptr_gray; 
reg [ADDR-1:0]  wptr_gray_ss,rptr_gray_ss;
reg [ADDR-1:0]  wptr_bi_ss,rptr_bi_ss;
reg [WIDTH-1:0] mem[(DEPTH)-1:0];
genvar i,j,k,m;

//-----------------------------------------------------------//
//             WRITE CLOCK DOMAIN                            //
//-----------------------------------------------------------//

assign wen = (!full && push);

assign wptr_bi_next = wptr_bi + wen;

always @(posedge wclk or negedge rst) begin 
    if (!rst) begin 
      wptr_gray <= #TIH 0;
      wptr_bi   <= #TIH 0;

    end else begin
      // $display (" rst= %b width = %d write_en = %b read_en = %b  empty = %b full= %b wptr_bi=%h %t",rst,WIDTH,wen,ren,empty,full,wptr_bi,$time);

	 
      wptr_gray <= #TIH (wptr_bi)^(wptr_bi>>1);     //converting binary into gray
      wptr_bi   <= #TIH wptr_bi_next;
    end
end    
    
//synchronous module generation 
generate 
  for (i=0;i<ADDR;i=i+1) begin 
    sync sync_wr(
     .clk   (wclk),
     .rst   (rst),
     .in    (rptr_gray[i]),
     .out   (rptr_gray_ss[i])
     );
  end  
endgenerate

//gray to binary conversion
assign rptr_bi_ss[ADDR-1] = rptr_gray_ss[ADDR-1];

generate
 for (k=ADDR-2;k>=0;k=k-1) begin 
    assign rptr_bi_ss[k] = ^rptr_gray_ss[ADDR-1:k];
 end 
endgenerate 

assign full = ((wptr_bi[ADDR-1]  != rptr_bi_ss[ADDR-1]) & 
              (wptr_bi[ADDR-2:0] == rptr_bi_ss[ADDR-2:0]));

//----------------------------------------------------------//
//                 READ CLOCK DOMAIN                        //
//----------------------------------------------------------//

assign ren = (!empty && pull);

assign rptr_bi_next = rptr_bi + ren;

always @(posedge rclk or negedge rst) begin 
    if (!rst) begin 
        rptr_gray <= #TIH 0;
        rptr_bi   <= #TIH 0;
    end else begin 
        rptr_gray <= #TIH (rptr_bi)^(rptr_bi>>1);
        rptr_bi   <= #TIH rptr_bi_next;
    end
end 

//synscrounous module

generate
    for (j=0; j<ADDR; j=j+1) begin 
        sync sync_rd(
            .clk (rclk),
            .rst (rst),
            .in  (wptr_gray[j]),
            .out (wptr_gray_ss[j])
            );
     end
endgenerate

//gray to binary conversion

assign wptr_bi_ss[ADDR-1] = wptr_gray_ss[ADDR-1];

generate
    for (m= ADDR-2; m>=0; m=m-1) begin 
        assign wptr_bi_ss[m] = ^wptr_gray_ss[ADDR-1:m];
    end 
endgenerate

assign empty = (wptr_bi_ss[ADDR-1:0] == rptr_bi[ADDR-1:0]);


//---------------------------------------------------------------//
//                 FIFO READS AND WRITES                         //
//---------------------------------------------------------------//
    
always @(posedge wclk) begin
    if (wen) begin
        mem[wptr_bi[ADDR-2:0]] <= #TIH din[WIDTH-1:0];
    end
end

assign dout = ren ? mem[rptr_bi[ADDR-2:0]] : 'bz0;

endmodule


            
        
    
// Synchronous FIFO//
/*


module fifo(clk,rst,write_data_in,read_en,write_en,read_data_out,fifo_full,fifo_empty);

input clk,rst;
input [63:0] write_data_in;
input read_en,write_en;
output reg [63:0] read_data_out;
output fifo_full,fifo_empty;

typedef struct packed{
reg [31:0] addr;
reg [31:0] data;
} fifo_def;
fifo_def mem[31:0];


reg [5:0] wpointer,rpointer;
wire read_en_wire,write_en_wire;
wire [4:0] read_addr,write_addr;


assign read_addr= rpointer[4:0];
assign write_addr=wpointer[4:0];

assign fifo_full = ((rpointer[4:0] == wpointer[4:0]) && (rpointer[5] ^ wpointer[5]));
assign fifo_empty= (rpointer[4:0] == wpointer[4:0]);

assign read_en_wire = (read_en && ~fifo_empty);
assign write_en_wire = (write_en && ~fifo_full);



always @(posedge clk or posedge rst) begin
  if(rst) begin
    rpointer<= #TIH  5'b00000;
  end
  else if(read_en_wire) begin
    rpointer <= #TIH  rpointer+1;
    read_data_out <= #TIH  mem[read_addr];
  end
end 

always @(posedge clk or posedge rst) begin
  if(rst) begin
    wpointer<= #TIH   5'b00000;
  end
  else if(write_en_wire) begin
    mem[write_addr]<= #TIH   write_data_in;
    wpointer <= #TIH  wpointer+1;
  end
end 

endmodule
*/












