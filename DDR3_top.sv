//`timescale 1ps / 1ps
parameter tclk= 10000;
typedef enum int {S0,S1} state_mc;

typedef enum int {idle1,read_resp} state_ready1;

module DDR3_top(input HCLK,input HRESET,AHBIF.AHBMS m,DDR3_sdram d1,d2);
//input HCLK,HRESET; 
wire   HGRANT= 1; // check this!
//outputs from slave which go as din and push to fifo
wire PUSH;

//dout and pull of the fifo for processing logic and address mapping
wire[31:0]  addr_map;
wire        FULL_f0,EMPTY_f0,FULL_f1,EMPTY_f1;
logic       f0_wr_enable,f1_wr_enable;

logic [1:0]  count_split;
wire  [31:0] width;
logic        cmd_valid,cmd;
wire         f0_rd_enable ;

wire 	     read_in_progress;
wire         read_ready;
wire [7:0]   f1_din;
reg in1, 
    in2 ,
    in3, 
    in4, 
    in5 ,
    in6, 
    in7, 
    in8 ,
    in9 ,
    in10,
    in11,
    in12,
    in13,
    in14,
    in15,
    in16,
    in17, in_done;







wire pos_ready;
reg read_done_delayed;
reg pos_flop;
reg [15:0] read_data_pos,read_data_neg;
reg flag1,flag2;
reg [31:0] read_data,read_out;

reg [31:0] pipe_addr1, pipe_addr2;
reg pipe_hwrite1, pipe_hwrite2;

state_mc state;
state_ready1 state_ready;

typedef struct packed{
reg cmd;
reg [31:0] addr;
reg [31:0] data;
} async_fifo_in;
async_fifo_in ahb_in,ahb_out;

/*typedef struct packed{
reg [31:0] addr;
reg [15:0] data;
reg cmd;
} fifo_in;
fifo_in sync_in,sync_out; */

//assign cmd_valid = f0_rd_enable? 1:0;
always @(*) begin
 if(f0_rd_enable) cmd_valid = 1;
 else cmd_valid = 0;
end
 
//assign write_done = (m.mHWDATA== 32'h01ca1056); // change this later!
 
always @(posedge HCLK or posedge HRESET ) begin
 if(m.mHTRANS == 2'b10 || m.mHTRANS == 2'b11) begin //{ 
   if(m.mHTRANS == 2'b10) begin //{
     if(m.mHWRITE==1) begin //{
       if(FULL_f0) m.mHREADY <= #1 1'b0; else m.mHREADY <= #1 1'b1; 
     end //}
     else begin //{
       m.mHREADY <= #1 ~EMPTY_f1; // added 4/30
     end //}
   end //}
   else begin //{
     if(m.mHWRITE==1) begin //{
       if(FULL_f0) m.mHREADY <= #1 1'b0; else m.mHREADY <= #1 1'b1; 
     end //}
     else begin //{
       	       
       m.mHREADY <= #1 ~EMPTY_f1; // added 4/30
     end //}
   end //}
 end //}
 else begin
      if(read_in_progress == 1) begin
	m.mHREADY <= #1 1'b0;
	read_done_delayed <= 1;
      end 
      else if(read_done_delayed == 1) begin
	read_done_delayed <= 0;
        m.mHREADY <= #1 1'b0;
      end
      else 
      m.mHREADY <= #1 1'b1; // added 4/30
      end

end
always @(posedge HCLK or posedge HRESET) begin 
    if (HRESET) begin 
         ahb_in.addr  <= 0;
	 ahb_in.data  <= 0;
         ahb_in.cmd   <= 0;
	 state        <= S0;
	 state_ready  <= idle1;
    end else begin 
        m.mHRDATA <= #1 read_out;
       case (state)
       S0: begin
	     if(m.mHTRANS == 2'b10 || m.mHTRANS == 2'b11) begin 
               pipe_addr1      <= m.mHADDR;
               pipe_hwrite1    <= m.mHWRITE;
	      // if(FULL_f0) m.mHRESP <= 2'b10; else m.mHRESP <= 2'b00;
	    //  if(FULL_f0) m.mHREADY <= #1 1'b0; else m.mHREADY <= #1 1'b1; 

	       if(m.mHTRANS == 2'b10) begin
		 if(m.mHWRITE==1) begin
		   state         <= S1;
		   f0_wr_enable  <= 1'b0;
	      //     if(FULL_f0) m.mHREADY <= #1 1'b0; else m.mHREADY <= #1 1'b1; 
		 end
		 else begin
	           ahb_in.addr   <= m.mHADDR;
                   ahb_in.cmd    <= m.mHWRITE;
	           ahb_in.data  <= 32'h9999;
		   state         <= S0;
             	   f0_wr_enable  <= 1'b1;
		//   m.mHREADY <= #1 ~EMPTY_f1; // added 4/30
                  // m.mHRESP  <= 2'b10;
	         end
               end
	       else begin
		 if(m.mHWRITE==1) begin

                 ahb_in.addr  <= pipe_addr2;
	         ahb_in.data  <= m.mHWDATA;
                 ahb_in.cmd   <= pipe_hwrite2;
	         f0_wr_enable <= 1'b1;
                 state        <= S1;
	     //    if(FULL_f0) m.mHREADY <= #1 1'b0; else m.mHREADY <= #1 1'b1; 
	        end
		else begin
	           ahb_in.addr   <= #1 m.mHADDR;
                   ahb_in.cmd    <= #1 m.mHWRITE;
	           ahb_in.data   <= #1 32'h9999;
		   state         <= #1 S0;
		   f0_wr_enable  <= #1 1'b0;
//		   if(~EMPTY_f1) f0_wr_enable  <= 1'b1; else  f0_wr_enable  <= 1'b0;
	//	   m.mHREADY <= #1 ~EMPTY_f1; // added 4/30
                // m.mHRESP  <= 2'b00;           
	        end
      	       end	       
	     end
	     else begin
	       state <= S0;
	       f0_wr_enable <= 1'b0;
	      //m.mHRESP    <= 2'b10;   
	  //      m.mHREADY <= #1 1'b1;   
	      // if(FULL_f0) m.mHREADY <= #1 1'b0; else m.mHREADY <= #1 1'b1; 
	     end 
	   end
      S1: begin
	     if(m.mHTRANS == 2'b10 || m.mHTRANS == 2'b11) begin
	   // if(FULL_f0) m.mHRESP <= 2'b10; else m.mHRESP <= 2'b00; 
	    //  if(FULL_f0) m.mHREADY <= #1 1'b0; else m.mHREADY <= #1 1'b1; 
               pipe_addr2   <= #1  m.mHADDR;
               pipe_hwrite2 <= #1  m.mHWRITE;


	       if(m.mHTRANS == 2'b10) begin
		 if(m.mHWRITE==1) begin
		   state         <= #1  S0;
		   f0_wr_enable  <= #1 1'b0;
	       //    if(FULL_f0) m.mHREADY <= #1 1'b0; else m.mHREADY <= #1 1'b1; 
		 end
		 else begin
	           ahb_in.addr   <= #1  m.mHADDR;
                   ahb_in.cmd    <= #1  m.mHWRITE;
	           ahb_in.data  <= #1  32'h9999;
		   state         <= #1  S1;
             	   f0_wr_enable  <= #1  1'b1;
	//	   m.mHREADY <= #1 ~EMPTY_f1; // added 4/30
                  // m.mHRESP  <= 2'b10;
	         end
               end
	       else begin
		 if(m.mHWRITE==1) begin
	          ahb_in.addr  <= #1 pipe_addr1;
	          ahb_in.data  <= #1 m.mHWDATA;
                  ahb_in.cmd   <= #1 pipe_hwrite1;
	          f0_wr_enable <= #1 1'b1;
                  state        <= #1  S0;
	       //   if(FULL_f0) m.mHREADY <= #1 1'b0; else m.mHREADY <= #1 1'b1; 
	        end
		else begin
	           ahb_in.addr   <= #1  m.mHADDR;
                   ahb_in.cmd    <= #1 m.mHWRITE;
	           ahb_in.data   <= #1 32'h9999;
		   state         <= #1 S1;
		   f0_wr_enable  <= #1 1'b0;

		//   if(~EMPTY_f1) f0_wr_enable  <= 1'b1; else  f0_wr_enable  <= 1'b0;
		//   m.mHREADY <= #1 ~EMPTY_f1; // added 4/30
                // m.mHRESP  <= 2'b00;           
	        end
      	       end	       
	     end
	     else begin
		 f0_wr_enable <= 1'b0;
	       //  m.mHRESP    <= 2'b10;
	       // m.mHREADY <= #1 1'b1;   
                state <= #1 S0;
	        //if(FULL_f0) m.mHREADY <= #1 1'b0; else m.mHREADY <= #1 1'b1; 

	     end
	   end
       endcase
     end
end

//Connecting the asynchronous fifo to collect address from AHB slave for furthur processing
fifo_async #(65,2048,12)  f0 (
                .wclk   (HCLK),         
                .rclk   (d1.ck),
                .rst    (!HRESET),
                .din    (ahb_in),
                .push   (f0_wr_enable),
                .pull   (f0_rd_enable),
                .dout   (ahb_out),
                .full   (FULL_f0),
                .empty  (EMPTY_f0)
                ); 


                
initialization init ( .ck       (d1.ck),
                      .ck_n     (~d1.ck),
                      .rst_n    (~HRESET),
                      .i        (d1),
                      .init_done(m.init_done)
                    );
                    
                    
                    
ctrl_operation ctrl ( .ck         (d2.ck),
                      .ck_n       (~d2.ck),
                      .rst_n      (~HRESET),
                      .cmd_valid  (cmd_valid),
                      .cmd_ready  (~EMPTY_f0),
                      .cmd_data   (ahb_out),
                      .cmd_get    (f0_rd_enable),
                      .w          (d2),
		      .r          (m),
                      .read_ready (read_ready),
		      .read_in_progress(read_in_progress) 
                    ); 
                    
    assign RESET                = (m.init_done )? d1.RESET    :d1.RESET;
    assign cke                  = (m.init_done )? d2.cke     :d1.cke;
    assign cs_n                 = (m.init_done )? d2.cs_n    :d1.cs_n;
    assign ras_n                = (m.init_done )? d2.ras_n   :d1.ras_n;
    assign cas_n                = (m.init_done )? d2.cas_n   :d1.cas_n;
    assign we_n                 = (m.init_done )? d2.we_n    :d1.we_n;
    wire [DM_BITS-1:0] dm       = (m.init_done )? d2.dm      :d1.dm;
    wire [BA_BITS-1:0] ba       = (m.init_done )? d2.ba      :d1.ba; 
    wire [ADDR_BITS-1:0] a      = (m.init_done )? d2.a       :d1.a;
    wire [DQ_BITS-1:0] dq0      = (m.init_done )? d2.dq0     :d1.dq0; 
    wire [DQS_BITS-1:0] dqs     = (m.init_done )? d2.dqs     :d1.dqs;
    wire [DQS_BITS-1:0] dqs_n   = (m.init_done )? d2.dqs_n   :d1.dqs_n;
    wire [DQS_BITS-1:0] tdqs_n  = (m.init_done )? d2.tdqs_n  :d1.tdqs_n;
    wire odt                    = (m.init_done )? d2.odt     :d1.odt;
            
ddr3 sdramddr3_0 (
                .rst_n  (RESET),
                .ck     (d1.ck), 
                .ck_n   (~d1.ck),
                .cke    (cke), 
                .cs_n   (cs_n), 
                .ras_n  (ras_n), 
                .cas_n  (cas_n), 
                .we_n   (we_n),
                .dm_tdqs(dm), 
                .ba     (ba), 
                .addr   (a), 
                .dq     (dq0), 
                .dqs    (dqs),
                .dqs_n  (dqs_n),
                .tdqs_n (tdqs_n),
                .odt    (odt)
            );

assign pos_ready = (read_ready==1) && (dqs==1);
  always @(negedge d1.ck or posedge HRESET) begin
    if(HRESET) begin
      read_data_neg <= #1 16'h0000;
      flag1         <= #1 1'b0;
    end
    else begin
	pos_flop <= #1 pos_ready;
	  //     $display("read_data= %h",read_data);
	
      if(read_ready) begin  
	 // $display ("dqs=%b",dqs); 
        if(dqs==1'b1) begin
          case(flag1)		
          0: begin 
	       read_data_neg[7:0]<= #1 dq0;
	       flag1 <= #1 1'b1;
	     end
	      1: begin
	       read_data_neg[15:8]<= #1 dq0;
	       flag1 <= #1 1'b0;
	       //$display("read_data_pos= %h",read_data_neg);
	     end
	  endcase
        end
      end
      else begin
        read_data_neg <= #1 16'h0000;
      end
    end
   
  end
 
   always @(posedge d1.ck or posedge HRESET) begin
    if(HRESET) begin
       read_data_pos <= #1 16'h0000;
       flag2 <= #1 1'b0;
       read_data <= #1 32'd0;
       f1_wr_enable <= #1 1'b0;
    end
    else begin
      if(pos_flop==1'b1) begin
        if(dqs==1'b0) begin
          case(flag2)		
          0: begin 
              read_data_pos[7:0]<= #1  dq0;
	       flag2 <= #1 1'b1;
	       f1_wr_enable <= #1 1'b0;
	     end
	  1: begin
              read_data_pos[15:8]<= #1 dq0;
	       flag2 <= #1 1'b0;
	       read_data <= #1 {dq0,read_data_neg[15:8],read_data_pos[7:0],read_data_neg[7:0]};
	       f1_wr_enable <= #1 1'b1; 
              
             end
	   endcase
        end
	else begin
	       f1_wr_enable <= #1 1'b0;
	end
      end
      else begin
	f1_wr_enable <= #1 1'b0;
        read_data_pos <= #1 16'h0000;
      end
    end
   
  end


always @(posedge HCLK or posedge HRESET) begin
  if(HRESET) begin
   in1  <= #1 0;
   in2  <= #1 0;
   in3  <= #1 0;
   in4  <= #1 0 ;
   in5  <= #1 0;
   in6  <= #1 0;
   in7  <= #1 0;
   in8  <= #1 0;
   in9  <= #1 0;
   in10  <= #1 1'b0;
   in11  <= #1 1'b0 ;
   in12  <= #1 1'b0;
   in13  <= #1 1'b0;
   in14  <= #1 1'b0;
   in15  <= #1 1'b0;
   in16  <= #1 1'b0;
   in17  <= #1 1'b0;
   in_done  <= #1 1'b0 ;


  end
  else begin
   in1  <= #1 m.init_done;
   in2  <= #1 in1;
   in3  <= #1 in2;
   in4  <= #1 in3 ;
   in5  <= #1 in4;
   in6  <= #1 in5;
   in7  <= #1 in6;
   in8  <= #1 in7;
   in9  <= #1 in8;
   in10  <= #1 in9 ;
   in11  <= #1 in10 ;
   in12  <= #1 in11;
   in13  <= #1 in12;
   in14  <= #1 in13;
   in15  <= #1 in14;
   in16  <= #1 in15;
   in17  <= #1 in16;
   in_done  <= #1 in17 ;
  end
end

always @(*) begin
   //if(m.mHWDATA== 32'hc01af0c9) 	
  if(m.mHWDATA==32'h01ca1056)
  m.write_done = #(10*tclk) 1'b1;
 else
  m.write_done = 1'b0;
  
 
end

//assign m.mHREADY = ~EMPTY_f1;
assign f1_rd_enable = ~EMPTY_f1;

fifo_async #(32,64,7)  f1 (
                .wclk   (d1.ck),         
                .rclk   (HCLK),
                .rst    (!HRESET),
                .din    (read_data),
                .push   (f1_wr_enable),
                .pull   (f1_rd_enable),
                .dout   (read_out),
                .full   (FULL_f1),
                .empty  (EMPTY_f1)
                ); 

endmodule

