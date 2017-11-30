// A simple ahb test module
//






module ahb(AHBIF.AHBM am,AHBIF.AHBS asl,cantintf.tox tx);

typedef struct packed {
        reg [7:0] quantaDiv;
        reg [5:0] propQuanta,seg1Quanta;
        reg [3:0] datalen;
        reg       format;
        reg [1:0] frameType;
        reg [4:0] Reserved;
} cmdT;

typedef struct packed {
        reg [28:0] id;
        reg [2:0] Reserved;
} idT;
    
cmdT cmd,cmd_d;
idT id,id_d;

reg [63:0] dataword,dataword_d;



reg [31:0] saddr,saddr_d;
reg [31:0] swdata,swdata_d;
reg swrite,swrite_d;
reg ssel,ssel_d;
reg [31:0] bm_base,bm_base_d;
reg bm_start;

typedef enum {SA_idle,SA_C1,SA_Cn,SA_pipe} SAHB;

typedef enum {BM_idle,BM_check,BM_fetchReq,BM_fetchDone,BM_startDut,
              BM_waitDut,BM_waitDutBusy,BM_write_req,BM_write_reqDone,BM_updateLink}
BMSM;

reg bm_busy;

SAHB sahb,sahb_d;
BMSM bmsm,bmsm_d;
reg bm_req,bm_grant;    // local request and grant...
reg [31:0] bm_addr;     // Address to the BM machine
reg bm_write;           // Used to request to the BM machine
reg bm_startbm;         // starts the ahb bus state machine
reg [4:0] bm_len;       // the number of words to transfer
reg sa_done;            // the done signal from the ahb state machine

reg [31:0] sa_addr,sa_addr_d;   // used to the transfer
reg [4:0] sa_len,sa_len_d,sa_cnt,sa_cnt_d;     // used for transfer of a burst
reg sa_write,sa_write_d;    // is this a write requests
reg [1:0] sa_htrans,sa_htrans_d;    // Htrans...
reg sa_pipe,sa_pipe_d;  // The pipeline flag...
reg [3:0] sa_reg,sa_reg_d;

reg [63:0] sa_dataword,sa_dataword_d;
reg startXmitS,startXmitM;
cmdT       sa_cmd,sa_cmd_d;
idT        sa_id,sa_id_d;
reg [31:0] sa_caddr,sa_caddr_d;
reg [31:0] sa_cdata,sa_cdata_d;
reg [31:0] sa_link,sa_link_d;

always @(*) begin
  tx.startXmit <= startXmitS | startXmitM;
  am.mHWDATA <= sa_cdata;
end


always @(*) begin
  asl.HREADY <= 1;
  startXmitS = 0;
  ssel_d = 0;
  swrite_d = swrite;
  saddr_d = saddr;
  dataword_d = dataword;
  cmd_d = cmd;
  id_d = id;
//  bm_base_d=bm_base;
  bm_start=0;
  bm_req=0;  
  sahb_d = sahb;
  sa_cnt_d = sa_cnt;
  sa_done=0;
  sa_htrans_d=sa_htrans;
  sa_pipe_d=0;
  sa_reg_d = sa_reg;
  sa_dataword_d = sa_dataword;
  sa_cmd_d = sa_cmd;
  sa_id_d = sa_id;
  sa_caddr_d = sa_caddr;
  sa_cdata_d = sa_cdata;
  sa_link_d = sa_link;
  
  am.mHADDR <= sa_addr;
  am.mHWRITE <= sa_write;
  am.mHSIZE <= 2;
  //am.HPROT <= 0;
  bm_grant = am.mHGRANT;
  
  
  
  case(asl.HTRANS)
    HTRANSnonseq,HTRANSseq: begin
      ssel_d=1;
      swrite_d = asl.HWRITE;
      saddr_d = asl.HADDR;
    end
    default: begin
      ssel_d = 0;
    end
  endcase
  
  // we are doing a cycle
  if(ssel) begin
    if(swrite) begin
      case(saddr[4:0])
        5'h00: dataword_d[63:32]=asl.HWDATA;
        5'h04: dataword_d[31:0] =asl.HWDATA;
        5'h08: cmd_d = asl.HWDATA&32'hFFFF_FFE0;
        5'h0c: id_d = asl.HWDATA&32'hFFFF_FFF8;
        5'h10: startXmitS = 1;
        5'h14: bm_base_d = asl.HWDATA;
        5'h18: bm_start=1;
        default: begin
        
        end
      endcase
    end else begin
      case(saddr[4:0])
        5'h00: asl.HRDATA <= dataword[63:32];
        5'h04: asl.HRDATA <= dataword[31:0];
        5'h08: asl.HRDATA <= cmd;
        5'h0c: asl.HRDATA <= id;
        5'h10: asl.HRDATA <= {31'b0,tx.busy};
        5'h14: asl.HRDATA <= bm_base;
        5'h18: asl.HRDATA <= bm_busy;
      endcase
    end
  end
  
  case(sahb)
    SA_idle: begin
      if(bm_startbm) begin
        sahb_d = SA_C1;
        sa_addr_d = bm_addr;
        sa_write_d = bm_write;
        sa_len_d = bm_len;
        sa_cnt_d = 1;
        sa_htrans_d=2;
      end
    end
    SA_C1: begin
      bm_req=1;
      
      if(bm_grant==1) begin
        sa_pipe_d=1;
        sa_reg_d=sa_cnt;
        if(sa_len == 1) begin
            sahb_d=SA_pipe;
            sa_htrans_d=0;
        end else begin
            sa_cnt_d = sa_cnt+1;
            sa_addr_d=sa_addr+4;
            sa_htrans_d=3;
            sahb_d=SA_Cn;
        end
      end
    end
    SA_Cn: begin
      bm_req=1;
      if(bm_grant==1) begin
        sa_pipe_d=1;
        sa_reg_d=sa_cnt;
        if(sa_len==sa_cnt) begin
            sahb_d=SA_pipe;
            sa_htrans_d=0;
        end else begin
            sa_cnt_d=sa_cnt_d+1;
            sa_addr_d=sa_addr+4;
        end
      end
    end
    SA_pipe: begin
      sa_done=1;
      sahb_d=SA_idle;
    end
  
  endcase 
  
  
  tx.quantaDiv = (bmsm==BM_idle)?cmd.quantaDiv:sa_cmd.quantaDiv;
  tx.propQuanta = (bmsm==BM_idle)?cmd.propQuanta:sa_cmd.propQuanta;
  tx.seg1Quanta = (bmsm==BM_idle)?cmd.seg1Quanta:sa_cmd.seg1Quanta;
  tx.datalen = (bmsm==BM_idle)?cmd.datalen:sa_cmd.datalen;
  tx.format = (bmsm==BM_idle)?cmd.format:sa_cmd.format;
  tx.id=(bmsm==BM_idle)?id.id:sa_id.id;
  tx.frameType = (bmsm==BM_idle)?cmd.frameType:sa_cmd.frameType;
  tx.xmitdata = (bmsm==BM_idle)?dataword:sa_dataword;
  
  if(sa_pipe==1&& sa_write==0) begin
    case(sa_reg)
      0,1: sa_dataword_d[63:32]=am.mHRDATA;
      2: sa_dataword_d[31:0]=am.mHRDATA;
      3: sa_cmd = am.mHRDATA;
      4: sa_id = am.mHRDATA;
      5: sa_caddr_d = am.mHRDATA;
      6: sa_cdata_d = am.mHRDATA;
      7: sa_link_d = am.mHRDATA;
    
    endcase
  
  end

  
  am.mHBUSREQ <= bm_req;
  am.mHTRANS <= sa_htrans;
  

end


//
// Higher level state machine
//

always @(*) begin
  bmsm_d=bmsm;
  bm_addr=0;
  bm_len=0;
  bm_startbm=0;
  bm_base_d=bm_base;
  startXmitM=0;

  bm_busy=1;
  case(bmsm)
    BM_idle: begin
        bm_busy=0;
        if(bm_start==1) begin
            bmsm_d = BM_check;
        end
    end
    
    BM_check: begin
        if(bm_base==0) begin
          bmsm_d = BM_idle;
        end else begin
          bmsm_d = BM_fetchReq;
        end
    end
    
    BM_fetchReq: begin
        bm_startbm=1;
        bm_addr = bm_base;
        bm_write = 0;
        bm_len = 7;
        bmsm_d = BM_fetchDone;
    end
    
    BM_fetchDone: begin
        if(sa_done) bmsm_d = BM_startDut;
    end
    
    BM_startDut: begin
        startXmitM = 1;
        bmsm_d=BM_waitDutBusy;
    end
    
    BM_waitDutBusy: begin
        if(tx.busy) bmsm_d = BM_waitDut;
    end
    
    BM_waitDut: begin
        if(!tx.busy) begin
           bmsm_d = BM_write_req; 
        end
    
    end
    
    BM_write_req: begin
        bm_startbm=1;
        bm_addr = sa_caddr;
        bm_write = 1;
        bm_len = 1;
        bmsm_d = BM_write_reqDone;
        
    
    end
    
    BM_write_reqDone: begin
        if(sa_done) bmsm_d = BM_updateLink;
    
    end
    
    BM_updateLink: begin
       bm_base_d = sa_link;
       bmsm_d = BM_check;
    end
  
  endcase
  

end





always @(posedge(asl.HCLK) or posedge(asl.HRESET)) begin
  if( asl.HRESET) begin
    ssel <= 0;
    saddr <= 0;
    cmd <= 0;
    id <= 0;
    dataword <= 0;
    swrite <= 0;
    bm_base <= 0;
    sahb <= SA_idle;
    bmsm <= BM_idle;
    sa_addr <= 0;
    sa_len <= 0;
    sa_write <= 0;
    sa_htrans <= 0;
    sa_cnt <= 0;
    sa_reg <= 0;
    sa_pipe <= 0;
    sa_dataword <= 0;
    sa_cmd <= 0;
    sa_id <= 0;
    sa_caddr <= 0;
    sa_cdata <= 0;
    sa_link <= 0;
  end else begin
    sa_dataword <= #1 sa_dataword_d;
    sa_cmd <= #1 sa_cmd_d;
    sa_id <= #1 sa_id_d;
    sa_caddr <= #1 sa_caddr_d;
    sa_cdata <= #1 sa_cdata_d;
    sa_link <= #1 sa_link_d;
    ssel <= #1 ssel_d;
    saddr <= #1 saddr_d;
    cmd <= #1 cmd_d;
    id <= #1 id_d;
    dataword <= #1 dataword_d;
    swrite <= #1 swrite_d;
    bm_base <= #1 bm_base_d;
    sahb <= #1 sahb_d;
    bmsm <= #1 bmsm_d;
    sa_addr <= #1 sa_addr_d;
    sa_len <= #1 sa_len_d;
    sa_write <= #1 sa_write_d;
    sa_htrans <= #1 sa_htrans_d;
    sa_cnt <= #1 sa_cnt_d;
    sa_pipe <= #1 sa_pipe_d;
    sa_reg <= #1 sa_reg_d;
  end
end





endmodule :ahb
