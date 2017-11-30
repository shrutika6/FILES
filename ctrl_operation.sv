typedef enum int {	idle, 
			nop,
			activate,read,write,nop_write,nop_read,DQS_WEN,DQS_REN,pre_compare,cmd_compare,post_compare,nop_tWR_precharge,precharge,nop_precharge} state_pr;
parameter tRCD=14; //10;
parameter bl= 4'd8;
parameter tWR =10; //10;
parameter tRP =10; //10; //Precharge command period
module ctrl_operation(input ck,ck_n,rst_n,cmd_valid,cmd_ready,input [64:0] cmd_data,output reg cmd_get, DDR3_sdram.ddr_wr w, AHBIF.AHBMS r,
                      output reg read_ready, output reg read_in_progress);
  logic [63:0] tck=TCK_MIN;
  
  int  count_tRCD,count_ccd,count_burstlen,count_write,count_tRP,count_tWR;
 
  logic cke;
  logic cs_n;
  logic odt_out;
  logic ras_n;
  logic cas_n;
  logic we_n;
  
  
  reg    [BA_BITS-1:0] ba;
  reg    [ADDR_BITS-1:0] a;
  
  wire   [DM_BITS-1:0] dm;
  reg    [DM_BITS-1:0] dm_out;
  
  reg    [DQ_BITS-1:0] dq;
  wire   [DQ_BITS-1:0] dq0;
  reg    [DQ_BITS-1:0] dq_out;
  wire   [DQ_BITS-1:0] dq1;

  reg    [DQ_BITS-1:0] dq1_out;
  reg    [DQ_BITS-1:0] dq2_out,dq_temp;
  wire   [DQS_BITS-1:0] dqs;
  reg    [DQS_BITS-1:0] dqs2_out,dqs1_out;

  wire   [DQS_BITS-1:0] dqs_n;
  wire   [DQS_BITS-1:0] tdqs_n;
  
  reg    dq_en, dqs_en,data_en;
  logic  odt;
  reg    flag1=0,flag2=0 ,flag, flag_compare; 
 
  state_pr state;
  logic  cmd;
  logic  [2:0] bank_addr=3'b000,ba_temp;
  logic  [15:0] row_addr=15'h008,ra_temp;
  logic  [9:0] col_addr=10'h200;
  logic  [31:0] wr_data,addr;
  logic [1:0] htrans_temp;
  
    assign w.RESET  = w.RESET;
    assign w.cke    = cke;
    assign w.cs_n   = cs_n;
    assign w.ras_n  = ras_n;
    assign w.cas_n  = cas_n;
    assign w.we_n   = we_n;
    assign w.dm     = dm;
    assign w.ba     = ba; 
    assign w.a      = a;
    assign w.dq0    = dq0; 
    assign w.dqs    = dqs;
    assign w.dqs_n  = dqs_n;
    assign w.tdqs_n = tdqs_n;
    assign w.odt    = odt;
  
    assign dm       = dq_en ? dm_out:{DM_BITS{1'bz}};
    assign dq0      = dq_temp;
    assign dqs      = ck ? dqs2_out:dqs1_out;
    assign dqs_n    = ck ? ~dqs2_out:~ dqs1_out;
    
    

    always @(*) begin
     if(ck) dq_temp = #(tck/4) dq2_out;
     else dq_temp = #(tck/4) dq1_out;
    end

    
    // Address Mapping - From AHB address to DDR3 Compatible Row, Column and Bank Address
always @(*) begin
   bank_addr =  addr[12:10]; // 3 bits of bank addr
   row_addr  =  addr[28:13]; // 16 bits of row addr
   col_addr  =  addr[9:0]; // 10 bits of column addr
end


always @(posedge ck or negedge rst_n) begin
  if(~rst_n) begin
    state        <= idle;
    count_write  <= #TIH 32'd0;
    cmd_get      <= #TIH 1'b0;
    addr         <= #TIH 32'h0001_0200;
    flag	 <= 0;
    htrans_temp  <= 2'b00;
    read_ready <= 0;
    read_in_progress <= 0;
   
  end
  else begin
     if(cmd_valid==1) begin
       addr      <= #TIH cmd_data[63:32];
       cmd       <= #TIH cmd_data[64];    // Cmd- Write or Read 	
       wr_data   <= #TIH cmd_data[31:0];
     end      
    case (state)
    
    idle: begin
          odt     <= #TIH 1'b0;
          cke     <= #TIH 1'b1;
          cs_n    <= #TIH 1'b0;
          ras_n   <= #TIH 1'b1;
          cas_n   <= #TIH 1'b1;
          we_n    <= #TIH 1'b1;
          a       <= #TIH 16'h400;
          ba      <= #TIH 3'b000;
          ba_temp <= #TIH 3'b000;
          ra_temp <= #TIH  16'h400;
	  read_ready <= #TIH 1'b0;
    //$display ("In idle state");
    
          if(cmd_ready) begin
	    if(r.mHTRANS == 2'b00 || r.mHTRANS == 2'b01)
		state <= #TIH idle;
	    else if(flag == 0) begin
		cmd_get   <= #TIH 1'b1;
		flag <= 1'b1;
	    end
	    else begin
              cmd_get   <= #TIH 1'b0;
	      flag 	<= 1'b0;
	      addr      <= #TIH cmd_data[63:32];
              cmd       <= #TIH cmd_data[64];    // Cmd- Write or Read 	
              wr_data   <= #TIH cmd_data[31:0];
              state    <= #TIH activate;
              $display ("cmd_valid is one %t",$time);
            end
          end
          else begin
            cmd_get  <= #TIH 1'b0; 
            state    <= #TIH idle;
          end
       end
       
       
    activate: begin
            cmd_get    <= #TIH 1'b0;  
            cke        <= #TIH 1'b1;
            cs_n       <= #TIH 1'b0;
            ras_n      <= #TIH 1'b0;
            cas_n      <= #TIH 1'b1;
            we_n       <= #TIH 1'b1;
            ba         <= #TIH bank_addr; //cmd_data
            a          <= #TIH row_addr; 
            ba_temp    <= #TIH bank_addr;
            ra_temp    <= #TIH row_addr;
	   state      <= #TIH nop;
	   count_tRCD <= #TIH tRCD;
	   read_ready <= #TIH 1'b0;
        
	        $display (" Bank addr= %h, Row Addr= %h , Column addr= %h", bank_addr,row_addr,col_addr);
            $display (" Activate command %t",$time);
        end
        
        
     nop: begin
          count_tRCD <= #TIH count_tRCD-1;
          cke       <= #TIH 1'b1;
          cs_n      <= #TIH 1'b0;
          ras_n     <= #TIH 1'b1;
          cas_n     <= #TIH 1'b1;
          we_n      <= #TIH 1'b1;
	  count_ccd <= #TIH TCCD-2;
	  read_ready <= #TIH 1'b0;
	 //$display ("------------------------------------");
         // $display (" NOP command after Activate %t",$time);
        //$display (" Bank addr= %h, Row Addr= %h , Column addr= %h,write_out= %h", bank_addr,row_addr,col_addr,write_out);
            if(count_tRCD==0) begin 
                if(cmd==1) begin 
                    state <= #TIH write;
                end
            else begin
                    state <= #TIH read;
                end
            end
            else state <= #TIH nop;
            //#200   test_done();  
            end

            
    read : begin
          cmd_get <= #TIH 1'b0;
          cke     <= #TIH 1'b1;
          cs_n    <= #TIH 1'b0;
          ras_n   <= #TIH 1'b1;
          cas_n   <= #TIH 1'b0;
          we_n    <= #TIH 1'b1;
          ba      <= #TIH ba_temp;
          a       <= #TIH col_addr;
          odt     <= #TIH 1'b0;
          state   <= #TIH nop_read;
          read_ready <= #TIH 1'b0;
          $display ("in READ state at %t and ba_temp = %0h and col_addr = %0h", $time,ba_temp,col_addr);
          end
          
          
     write:begin
            cke     <= #TIH 1'b1;
            cs_n    <= #TIH 1'b0;
            ras_n   <= #TIH 1'b1;
            cas_n   <= #TIH 1'b0;
            we_n    <= #TIH 1'b0;
            ba      <= #TIH ba_temp;
	    a       <= #TIH col_addr;
	    cmd_get <= #TIH 1'b0;
	    dm_out  <= #TIH 2'b00; 
            odt     <= #TIH 1'b1;
            state   <= #TIH nop_write;
            read_ready <= #TIH 1'b0;
          end

 nop_write: begin
            count_ccd       <= #TIH count_ccd-1;
            cke             <= #TIH 1'b1;
            cs_n            <= #TIH 1'b0;
            ras_n           <= #TIH 1'b1;
            cas_n           <= #TIH 1'b1;
            we_n            <= #TIH 1'b1;
	    read_ready <= #TIH 1'b0;
            count_burstlen  <= #TIH bl-4; // burstlen/2 time to send a burst due to DDR operation
            if(count_ccd==0) begin 
                    state <= #TIH DQS_WEN;
         
               count_ccd  <= #TIH TCCD-2;
            end         
            else    state <= #TIH nop_write; 
          end 
          
          
 nop_read: begin
            count_ccd       <= #TIH count_ccd-1;
            cke             <= #TIH 1'b1;
            cs_n            <= #TIH 1'b0;
            ras_n           <= #TIH 1'b1;
            cas_n           <= #TIH 1'b1;
            we_n            <= #TIH 1'b1;
            read_ready <= #TIH 1'b0;
            count_burstlen  <= #TIH bl-4; // burstlen/2 time to send a burst due to DDR operation
            if(count_ccd==0) begin 
                 
              state <= #TIH DQS_REN;     
               count_ccd  <= #TIH TCCD-2;
            end         
            else    
		state <= #TIH nop_read; 
          end  
            
    DQS_WEN:begin
            
	       if(count_burstlen == 1'b0) begin
			 if(cmd_ready) begin
			   dqs_en   <= #TIH 1'b0;
		           cmd_get  <= #TIH 1'b1;
			   addr     <= #TIH cmd_data[63:32];
                            cmd     <= #TIH cmd_data[64];    // Cmd- Write or Read 	
                            wr_data <= #TIH cmd_data[31:0];

                           state    <= #TIH cmd_compare;
			 end else begin
			   dqs_en   <= #TIH 1'b0;
		           cmd_get  <= #TIH 1'b0;
                           state    <= #TIH DQS_WEN;
			 end
		      //  $display (" bank address old %h new %h row addr old %h new %h %t", ba_temp,bank_addr,ra_temp,row_addr,$time);
               end
	       else begin
		     state  <= #TIH DQS_WEN;
                     dqs_en <= #TIH 1'b1;
            count_burstlen  <= #TIH count_burstlen-1'b1;

                end
	   end
                            
   DQS_REN:begin 
	           if(count_burstlen == 1'b0) begin
                     read_in_progress <= #TIH 1'b0;
                     if(cmd_ready==1) begin
		       cmd_get<= #TIH 1'b1;
                       addr   <= #TIH cmd_data[63:32];
		       cmd    <= #TIH cmd_data[64];   
		       state  <= #TIH cmd_compare;
		     end
		     else begin 
		       if(r.mHTRANS==2'b00 || r.mHTRANS== 2'b01) begin	     
		         cmd_get  <= #TIH 1'b0;
                     //    count_tWR <= #TIH tWR;		 
                         state    <= #TIH pre_compare;
		       end
		       else begin
		         cmd_get  <= #TIH 1'b0;     
                         state    <= #TIH cmd_compare;
		         addr     <= #TIH addr + 4;
		       end
		     end
               	   end else begin
		      cmd_get         <= #TIH 1'b0;
                      dqs_en          <= #TIH 1'b0;
	              read_ready      <= #TIH 1'b1;
                      count_burstlen  <= #TIH count_burstlen-1'b1;
               	      state <= #TIH DQS_REN;
                      
               	end
           end

 pre_compare: begin
                read_ready <= #TIH 1'b0;
                if(cmd_ready==1) begin

		   cmd_get<= #TIH 1'b1;
                   addr   <= #TIH cmd_data[63:32];//check this
		   cmd    <= #TIH cmd_data[64];   //check this
                   state  <= #TIH cmd_compare;
                end
	        else begin
                   state    <= #TIH pre_compare;
		   cmd_get <= #TIH 1'b0;
		end
              end
 cmd_compare: begin
                  read_ready <= #TIH 1'b0;
 	          cmd_get  <= #TIH 1'b0;                
                  state   <= #TIH post_compare;
              end
 post_compare:begin 
                read_ready <= #TIH 1'b0;
                cmd_get <= #TIH 1'b0;
                  if  ((bank_addr == ba_temp) && (row_addr == ra_temp)) begin // new bank and row address compared with old 

                        if(cmd==1) begin 
                          state <= #TIH write;
                        end 
                        else if (cmd == 0) begin 
                          state <= #TIH read;
                          dqs_en<= #TIH 1'b0;
                       end 
                       else begin 
                            state <= #TIH idle;  
                       end 
                  end 
                  else begin 
                        dqs_en    <= #TIH 1'b0;
			htrans_temp <= #TIH r.mHTRANS;		
                        count_tWR <= #TIH tWR;
                        state     <= #TIH nop_tWR_precharge; 
			read_in_progress <= #TIH 1'b1; // Precharge
                   end 
             end  
             
             
 nop_tWR_precharge:begin
               read_ready <= #TIH 1'b0;
               count_tWR  <= #TIH count_tWR -1;
                   cke    <= #TIH 1'b1;
                   cs_n   <= #TIH 1'b0;
                   ras_n  <= #TIH 1'b1;
                   cas_n  <= #TIH 1'b1;
                   we_n   <= #TIH 1'b1;
		 cmd_get  <= #TIH 1'b0;     
                   
                    if(count_tWR==0) begin
                        state <= #TIH precharge; 
                    end else begin 
                        state <= #TIH nop_tWR_precharge;
                    end
                   end
                   
                   
      precharge: begin
                read_ready <= #TIH 1'b0;
                cmd_get   <= #TIH 1'b0;
                   cke    <= #TIH 1'b1;
                   cs_n   <= #TIH 1'b0;
                   ras_n  <= #TIH 1'b0;
                   cas_n  <= #TIH 1'b1;
                   we_n   <= #TIH 1'b0;
                    ba    <= #TIH ba_temp;
                    a     <= #TIH 16'h0000; 
                state     <= #TIH nop_precharge;
                count_tRP <= #TIH tRP;
                end
            
    nop_precharge:begin
                  read_ready <= #TIH 1'b0;
                  count_tRP <= #TIH count_tRP -1;
                  cke   <= #TIH 1'b1;
                  cs_n  <= #TIH 1'b0;
                  ras_n <= #TIH 1'b1;
                  cas_n <= #TIH 1'b1;
                  we_n  <= #TIH 1'b1;
			 
                    if(count_tRP==0) begin 
                       
		        if(htrans_temp == 2'b00 || htrans_temp== 2'b01) begin
			     state <= #TIH idle;
			     htrans_temp <= #TIH r.mHTRANS;
	                end        
			else begin
			     state <= #TIH activate; 
			     htrans_temp <= #TIH r.mHTRANS;
			end
                    
                    end else begin 
			
                        state <= #TIH nop_precharge;
                    end
                 end
    endcase
  end
end

always @(posedge ck or negedge rst_n) begin
  if(rst_n==0) begin
    flag1   <= #TIH 1'b0;
    dqs1_out<= #TIH {DQS_BITS{1'bz}}; 
    dq1_out<= #TIH {DQS_BITS{1'bz}}; 
  end
  else begin
    if(dqs_en) begin 
      dqs1_out<= #TIH {DQS_BITS{1'b0}};
      dq_en   <= #TIH 1'b1;
      case(flag1)	    
	0: begin 
	   dq1_out <= wr_data[7:0];
	   flag1 <= 1'b1;
           end
	1: begin
	   dq1_out <= wr_data[23:16];
	   flag1 <= 1'b0;
	   end
      endcase
    end 
    else begin
      dqs1_out <= #TIH {DQS_BITS{1'bz}};
         dq_en <= #TIH 1'b0;
      dq1_out <= {DQ_BITS{1'bz}}; 
      flag1   <= #TIH 1'b0;

    end
  end
end



always @(negedge ck or negedge rst_n) begin
  if(rst_n==0) begin
    dqs2_out<= #TIH {DQS_BITS{1'bz}};
  end
  else begin
    if(dqs_en) begin
      dqs2_out<= #TIH {DQS_BITS{1'b1}};
    end
    else begin
       dqs2_out <= #TIH {DQS_BITS{1'bz}};
    end

  end
end

    
always @(negedge ck or negedge rst_n) begin
  if(rst_n==0) begin
    dq2_out<= #TIH {DQS_BITS{1'bz}}; 
    flag2 <= #TIH 1'b0;
  end
  else begin
    if(dq_en) begin
      case (flag2) 
      0: begin 
        dq2_out <= wr_data[15:8];
	    flag2 <= 1'b1;
	 end
      1: begin
        dq2_out <= wr_data[31:24];
        flag2 <= 1'b0; 
	 end
      endcase
    end 
    else begin
      flag2    <= #TIH 1'b0;
      dq2_out  <= {DQ_BITS{1'bz}};   
    end
  end
end
    
    
endmodule

