
parameter wait_200= 32'd80_000;
parameter wait_500= wait_200+32'd200_000;
parameter wait_tXPR= wait_500+32'd108;
parameter wait_tMRD_M2= wait_tXPR+ 32'd4;
parameter wait_tMRD_M3=wait_tMRD_M2+32'd4;
parameter wait_tMRD_M1=wait_tMRD_M3+32'd4;
parameter wait_tMOD=wait_tMRD_M1+32'd12;
parameter wait_zqinit=wait_tMOD+TDLLK;


module initialization (input ck,input ck_n,input rst_n,DDR3_sdram.ddr_wr i,output reg init_done );

  logic cke;
  logic cs_n;
  
  logic [63:0] tck=TCK_MIN;
  logic ras_n;
  logic cas_n;
  logic we_n;
  reg  dq_en;
  int count;
  reg           [BA_BITS-1:0] ba;
  reg         [ADDR_BITS-1:0] a;
  wire          [DM_BITS-1:0] dm;

  wire [14:0] long;
  logic odt;
  reg RESET;
  //reg init_done=0;
    
  assign dm       = {DM_BITS{1'bz}};
  assign long     = 15'h1;
   
   assign i.RESET = RESET;
   assign i.cke   = cke;
   assign i.cs_n  = cs_n;
   assign i.ras_n = ras_n;
   assign i.cas_n = cas_n;
   assign i.we_n  = we_n;
   assign i.dm    = {DM_BITS{1'bz}}; 
   assign i.ba    = ba;
   assign i.a     = a;
   assign i.dq0   = {DQ_BITS{1'bz}};
   assign i.dqs   = {DQS_BITS{1'bz}};
   assign i.dqs_n = {DQS_BITS{1'bz}};
   assign i.tdqs_n= {DQS_BITS{1'bz}};
   assign i.odt   = odt;


  
 
    always @(posedge ck or negedge rst_n) begin

      if(~rst_n) begin
        cs_n    <=  1'bz;
        ras_n   <=  1'bz;
        cas_n   <=  1'bz;
        we_n    <=  1'bz;
        ba      <=  {BA_BITS{1'bz}};
        a       <=  {ADDR_BITS{1'bz}};
	count   <=  32'h0000_0000; 
	RESET   <=  1'b0;
	init_done <= 1'b0;
      end
      else begin
	count  <= count+1;
		    // $display (" count %d",count);
	
	case (count)

	// Wait for (200 micro -10n) second after reset is asserted to dessert cke.		  
	(wait_200-5): begin
                     cke <=  1'b0;
		     $display (" cke deasserted %t",$time);
	          end
	// Wait for 200 micro second after reset is asserted to dessert it.		  
         wait_200:begin 
		    RESET<= 1'b1;
		     $display (" reset deasserted %t",$time);
		  end
	// wait for (500 micro-tIS) second after reset==1 and reset odt
        (wait_500-1):begin 
	            odt <= 1'b0;
		     $display (" odt deasserted %t",$time);

	          end
	// wait for 500 micro second after reset==1 and set cke to 1 and NOP command
         wait_500 :begin
	             cke   <= #TIH 1'b1;		 
                     cs_n  <= 1'b0;
                     ras_n <= 1'b1;
                     cas_n <= 1'b1;
                     we_n  <= 1'b1;
		     $display (" NOP command %t",$time);
		   end
       //Wait for tXPR time CKE is asserted. Configure Mode Register 2 using MRS command
       wait_tXPR:begin
	            cke   <= #TIH 1'b1;		        
                    cs_n  <= #TIH 1'b0;
                    ras_n <= #TIH 1'b0;
                    cas_n <= #TIH 1'b0;
                    we_n  <= #TIH 1'b0;
                    a <= #TIH 16'd0;
                    ba <=#TIH 3'b010;
 		   $display (" Load Mode register 2 command %t",$time);       
                 end
	// After Mode Register 2 is configured, Wait for tMRD to configure another mode register. Issue NOP Command meanwhile!
        wait_tXPR+1 :begin
	             cke   <= #TIH 1'b1;		 
                     cs_n  <= #TIH 1'b0;
                     ras_n <= #TIH 1'b1;
                     cas_n <= #TIH 1'b1;
                     we_n  <= #TIH 1'b1;
		     $display (" NOP command %t",$time);
		   end
       // After waiting for tMRD configure Mode Register 3
       wait_tMRD_M2 :begin
	       	    cke   <= #TIH 1'b1;		        
                    cs_n  <= #TIH 1'b0;
                    ras_n <= #TIH 1'b0;
                    cas_n <= #TIH 1'b0;
                    we_n  <= #TIH 1'b0;
                    a <= #TIH 16'd0;
                    ba <=#TIH 3'b011;
 		   $display (" Load Mode register 3 command %t",$time);       
                  end

	// After Mode Register 3 is configured, Wait for tMRD to configure another mode register. Issue NOP Command meanwhile!

       wait_tMRD_M2+1 : begin
		     cke   <= #TIH 1'b1;		 
                     cs_n  <= #TIH 1'b0;
                     ras_n <= #TIH 1'b1;
                     cas_n <= #TIH 1'b1;
                     we_n  <= #TIH 1'b1;
		     $display (" NOP command %t",$time);
                 end
       // After waiting for tMRD configure Mode Register 1
	
       wait_tMRD_M3 :begin
	       	    cke   <= #TIH 1'b1;		        
                    cs_n  <= #TIH 1'b0;
                    ras_n <= #TIH 1'b0;
                    cas_n <= #TIH 1'b0;
                    we_n  <= #TIH 1'b0;
                    a <= #TIH 16'b0000_0000_0100_0100;
                    ba <=#TIH 3'b001;
 		   $display (" Load Mode register 1 command %t",$time);       
                  end
	// After Mode Register 1 is configured, Wait for tMRD to configure another mode register. Issue NOP Command meanwhile!

      wait_tMRD_M3+1: begin
		     cke   <= #TIH 1'b1;		 
                     cs_n  <= #TIH 1'b0;
                     ras_n <= #TIH 1'b1;
                     cas_n <= #TIH 1'b1;
                     we_n  <= #TIH 1'b1;
		     $display (" NOP command %t",$time);
	          end

       // After waiting for tMRD configure Mode Register 0

     wait_tMRD_M1:begin
	       	    cke   <= #TIH 1'b1;		        
                    cs_n  <= #TIH 1'b0;
                    ras_n <= #TIH 1'b0;
                    cas_n <= #TIH 1'b0;
                    we_n  <= #TIH 1'b0;
                    a <= #TIH 16'b0000_0101_0010_0010;  // Bit 8 is set! DLL reset  // change bit 1 to 1 to make BC-4
                    ba <=#TIH 3'b000;
 		   $display (" Load Mode register 0 command %t",$time); 
	          end
	// After Mode Register 0 is configured, Wait for tM0D to configure non mode register. Issue NOP Command meanwhile!

      wait_tMRD_M1+1: begin
	             cke   <= #TIH 1'b1;		 
                     cs_n  <= #TIH 1'b0;
                     ras_n <= #TIH 1'b1;
                     cas_n <= #TIH 1'b1;
                     we_n  <= #TIH 1'b1;
		     $display (" NOP command %t",$time);
	          end
	// Issue ZQ Calibration Command 
      wait_tMOD: begin
                   cke   <= #TIH 1'b1;
                   cs_n  <= #TIH 1'b0;
                   ras_n <= #TIH 1'b1;
                   cas_n <= #TIH 1'b1;
                   we_n  <= #TIH 1'b0;
                   ba    <= #TIH {BA_BITS{1'b0}};
                   a     <= #TIH  long<<10;
		     $display (" ZQ Calibration command %t",$time);

	         end
	// Wait for tZQ_INIT time. Issue NOP Command meanwhile!

      wait_tMOD+1: begin
	             cke   <= #TIH 1'b1;		 
                     cs_n  <= #TIH 1'b0;
                     ras_n <= #TIH 1'b1;
                     cas_n <= #TIH 1'b1;
                     we_n  <= #TIH 1'b1;
		     $display (" NOP command %t",$time);
	         end
     wait_zqinit: begin
	            init_done <= 1'b1;
		    $display (" Initialization Done %t",$time);
                    //#500 $finish();
	          end
        endcase
      end
    end 


endmodule
