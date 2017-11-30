// A simple version of a can controller
//


module canxmit(cantintf.xmit x);

typedef enum [4:0] { Sidle,Sdrstart,Sdrstart1,Sdr11,Sdr1,Sdr2,Sdr3,Sdr29,Sdre1,
    Sdre2,Sdr291,Sdr292,Sdrlen,Sdrdata,Sdrcrc,Sdack0,Sdack1
    } smhigh;
    
typedef enum [1:0] { P0,P1,Ton,Toff} pdataT;

typedef enum [2:0] { Bidle,Bstart,Bprop,Bseg1,Bseg2 } sbitT;



smhigh hstate,nhstate;
reg [6:0] cnt,cnt_d;
reg [6:0] bcnt,bcnt_d;
reg [14:0] crc,crc_d;
logic nxcrc;
logic stuff;
reg [3:0] scnt,scnt_d;
pdataT spol,spol_d;
pdataT sdata,sdata_d,ddata;
logic stopbit;
reg [7:0] cntquanta,cntquanta_d;
logic quantaEvent;
logic enableQuanta;

logic pushraw,stopraw;
pdataT pdata;
reg dd,dd_d;    // the dout latched data

sbitT sbit,sbit_d;  // the bit state machine
reg [5:0] btcnt,btcnt_d; // used in the bit time
logic bsample;      // when to sample the input data
reg bout,bout_d;    // the bit out...
reg bnext,bnext_d;      // the next bit out
reg bvalid,bvalid_d;    // the bit out valid

// holding place goes here...
typedef enum [2:0] { Fidle,Fnostuff,Fnowait,Fget,Fcheck,Fsend,Fstuff } stuffT;
stuffT sstate,sstate_d;


// An improved stuffer
//

always @(*) begin
  sstate_d=sstate;
  sdata_d = sdata;
  ddata = sdata;
  scnt_d=scnt;
  stopraw=1;
  spol_d=spol;
  case(sstate)
    Fidle: begin
      sdata_d=P1;
      sstate_d=Fnostuff;
      scnt_d=1;
      spol_d=P1;
    end
    Fnostuff: begin
      if(stuff) begin
        sstate_d=Fget;
        scnt_d=1;
        spol_d=P1;
      end else begin
        stopraw=0;
        if(pushraw) begin
          sdata_d=pdata;
          sstate_d=Fnowait;
        end
      end
    end
    Fnowait: begin
      if(!stopbit) begin
        sstate_d = Fnostuff;
      end
    end
// The running stuffing machine
    Fget: begin
      stopraw=0;
      if(!stuff) begin
        sstate_d =Fnostuff;
      end else if(pushraw) begin
        sdata_d=pdata;
        sstate_d=Fcheck;
      end
    end
    Fcheck: begin
       if( spol==sdata ) begin
         if(scnt == 5) begin
           sstate_d=Fstuff;
         end else begin
           scnt_d=scnt+1;
           sstate_d=Fsend;
         end
       end else begin
         spol_d = sdata;
         sstate_d = Fsend;
         scnt_d=1;
       end
    end
    Fsend: begin
      if(!stopbit) begin
        sstate_d = Fget;
      end
    end
    Fstuff: begin
      ddata =(sdata==P0)?P1:P0;
      scnt_d=1;
      spol_d=sdata;
      if(!stopbit) begin
        sstate_d=Fsend;
      end
    end
  
  endcase
end

//
// The bit state machine
//
always @(*) begin
  sbit_d=sbit;
  btcnt_d=btcnt;
  bsample=0;
  stopbit=1;
  ci.dout = 1;
  ci.ddrive=1;
  bout_d = bout;
  bnext_d = bnext;
  ci.dout = bout;
  enableQuanta=1;
  dd_d = dd;
  case(sbit)
    Bidle: begin
      stopbit=0;
      enableQuanta=0;
      ci.ddrive=0;
      if(ddata==Ton) begin
        sbit_d = Bstart;
        bnext_d = (ddata==P0)?0:1;
      end
    end
    
    Bstart: begin
      btcnt_d=1;
      bout_d=bnext;
      ci.dout = dd;
      if(sdata==Toff) begin
        sbit_d = Bidle;
      end else if(quantaEvent) begin
        sbit_d = Bprop;
        stopbit=0;
        dd_d = (ddata==P0)?0:1;
//        ci.dout=dd_d;
      end
    end  
  
    Bprop: begin
      ci.dout=dd;
      if(quantaEvent) begin
        if(btcnt >= ci.propQuanta) begin
          btcnt_d=1;
          sbit_d = Bseg1;
        end else begin
          btcnt_d = btcnt+1;
        end
      end
    end
  
    Bseg1: begin
      ci.dout=dd;
      if(quantaEvent) begin
        if(btcnt >= ci.seg1Quanta) begin
          btcnt_d=1;
          sbit_d = Bseg2;
          bsample=1;
        end else begin
          btcnt_d = btcnt+1;
        end
      end
    end
  
    Bseg2: begin
      ci.dout=dd;
      if(quantaEvent) begin
        if(btcnt >= ci.seg1Quanta) begin
          btcnt_d=1;
          sbit_d = Bstart;
        end else begin
          btcnt_d = btcnt+1;
        end
      end
    end
  endcase

end
//
// This is the bit quanta engine
//
always @(*) begin
  cntquanta_d=1;
  quantaEvent=0;
  if(enableQuanta) begin
    cntquanta_d=cntquanta+1;
    if(cntquanta>=ci.quantaDiv) begin
      cntquanta_d=1;
      quantaEvent=1;
    end
  end
end
//
// This is the bit stuffer
//
/*
always @(*) begin
  scnt_d = scnt;
  spol_d = spol;
  sdata_d = sdata;
  sstate_d = sstate;
  stopraw=1;
  ddata=sdata;
   begin
    case(sstate)
      Fidle: begin  // 000
        stopraw=0;
        if(stuff) begin
          if(pushraw) begin
            sdata_d=pdata;
            sstate_d=Fcnt;
            scnt_d=1;
          end else begin
            sstate_d=Fwait;
            scnt_d=1;
          end
        end else begin
          if(pushraw) begin
            sdata_d=pdata;
            sstate_d=FidleData;
          end
        end
      end
      FidleData: begin // 001
        stopraw=1;
        if(!stopbit) begin
          sstate_d=Fidle;
        end
      end
      Fwait: begin // 010
        stopraw=0;
        if(stuff==0) begin
          if(pushraw) begin
            sdata_d=pdata;
            sstate_d=FidleData;
          end
          sstate_d=Fidle;
        end else if(pushraw) begin
            sstate_d=Fcnt;
            sdata_d=pdata;
        end
      end
      Fcnt: begin // 011
        stopraw=1;
        if(spol == sdata) begin
            if(scnt==5) begin
              spol_d = (pdata==P0)?P1:P0;
              sstate_d=Fstuff;
            end else begin
              if(!stopbit) begin
                scnt_d=scnt+1;
                sstate_d=Fwait;
                spol_d = pdata;
              end
            end
        end else begin
          if(!stopbit) begin
            scnt_d=1;
            spol_d = pdata;
            sstate_d=Fwait;
          end
        end
      end
      Fstuff: begin // 100
        stopraw=1;
        ddata=(sdata==P0)?P1:P0;
        if(!stopbit) begin
          scnt_d=1;
          spol_d=sdata;
          ddata=sdata;
          sstate_d=Fcnt;
        end
      end
    
  
    endcase
  end
end
*/

task stepcrc;
  nxcrc = crc[14] ^ ((pdata==P0)?0:1);
  crc_d = { crc[13:0],1'b0 } ^ ((nxcrc)?15'h4599:0);
endtask : stepcrc

task pushData(input pdataT dat,input smhigh nsx);
  pushraw=1;
  pdata = dat;
  stuff=1;
  if(!stopraw) begin
    nhstate=nsx;
    stepcrc;
  end
endtask : pushData

// The high level state machine

always @(*) begin
  cnt_d = cnt;
  nhstate = hstate;
  x.busy=1;
  pushraw=0;
  pdata = Toff;
  crc_d = crc;
  bcnt_d = bcnt;
  stuff=0;
  case(hstate)
    Sidle: begin
      cnt_d=0;
      crc_d=0;
      if(x.startXmit) begin
        case(x.frameType)
          XMITdataframe,XMITremoteframe: nhstate = Sdrstart;
        endcase
      end 
      x.busy=0;
    end
    
    Sdrstart: begin
      pushraw=1;
      pdata=Ton;
      if( !stopraw ) nhstate = Sdrstart1;
      stuff=0;
    end
    
    Sdrstart1: begin
      pushData(P0,Sdr11);
      cnt_d = 28;
    end
    
    Sdr11: begin
      pushraw=1;
      stuff=1;
      pdata = (x.id[cnt])?P1:P0;
      if(!stopraw) begin
        stepcrc;
        cnt_d=cnt-1;
        if(cnt==18) begin
          if(x.format) begin
            nhstate=Sdre1;
          end else nhstate=Sdr1;
        end
      end
    end
    
    Sdre1: begin
      pushraw=1;
      stuff=1;
      pdata=P1; // this is the SRR extended frame bit
      if(!stopraw) begin
        nhstate = Sdre2;
        stepcrc;
      end
    end
    
    Sdre2: begin
      pushraw=1;
      stuff=1;
      pdata=P0; // the ide bit for extended frame
      if(!stopraw) begin
        nhstate = Sdr291;
        stepcrc;
      end
    end
    
    Sdr291: begin
        pushraw=1;
        stuff=1;
        pdata = (x.id[cnt])?P1:P0;
        if(!stopraw) begin
            stepcrc;
            cnt_d=cnt-1;
            if(cnt == 0) begin
              nhstate=Sdr1;
            end
        end
    end
// Sdr1 is not just the normal flow    
    Sdr1: begin // send the RTR bit
      pushraw=1;
      stuff=1;
      pdata = (x.frameType==XMITdataframe)?P0:P1;
      if(!stopraw) begin
        nhstate=Sdr2;
        stepcrc;
      end
    end
  
    Sdr2: begin
      pushraw=1;
      stuff=1;
      pdata=P0;
      if(!stopraw) begin
        nhstate=Sdr3;
        stepcrc;
        cnt_d=3;
      end
    end
    
    Sdr3: begin
      pushraw=1;
      stuff=1;
      pdata=P0;
      if(!stopraw) begin
        stepcrc;
        cnt_d=3;
        nhstate=Sdrlen;
      end
    end
    
    Sdrlen: begin
      pushraw=1;
      stuff=1;
      pdata=(x.datalen[cnt])?P1:P0;
      if(!stopraw) begin
        cnt_d=cnt-1;
        stepcrc;
        if(cnt==0) begin
          cnt_d=63;
          bcnt_d=0;
          if(x.frameType==XMITdataframe && x.datalen != 0) begin
            nhstate = Sdrdata;
          end else begin
            cnt_d=14;
            nhstate = Sdrcrc;
          end
        end
      end
    end
    
    Sdrdata: begin
      pushraw=1;
      stuff=1;
      pdata=(x.xmitdata[cnt])?P1:P0;
      if(!stopraw) begin
        stepcrc;
        cnt_d=cnt-1;
        bcnt_d=bcnt+1;
        if(bcnt_d[6:3]==x.datalen) begin
          cnt_d=14;
          nhstate=Sdrcrc;
        end
      end
    end
    
    Sdrcrc: begin
      pushraw=1;
      stuff=1;
      pdata=(crc[cnt])?P1:P0;
      if(!stopraw) begin
        cnt_d=cnt-1;
        if(cnt==0) begin
          nhstate=Sdack0;
          cnt_d=10;
        end
      end    
    end

    Sdack0: begin
      pushraw=1;
      pdata=P1;
      if(!stopraw) begin
        cnt_d=cnt-1;
        if(cnt == 0) begin
          nhstate=Sidle;
        end
      end
    end
    
   
  endcase
  


end


always @(posedge(x.clk) or posedge(x.rst)) begin
  if(x.rst) begin
    hstate <= Sidle;
    cnt  <= 0;
    crc  <= 0;
    bcnt <= 0;
    scnt <= 1;
    spol <= P1;
    sstate <= Fidle;
    cntquanta <= 1;
    sbit <= Bidle;
    btcnt <= 1;
    bout <= 1;
    sdata <= P1;
    bnext <= 1;
    dd <= 1;
  end else begin
    hstate <= #1 nhstate;
    cnt  <= #1 cnt_d;
    crc  <= #1 crc_d;
    bcnt <= #1 bcnt_d;
    scnt <= #1 scnt_d;
    spol <= #1 spol_d;
    sstate <=#1 sstate_d;
    cntquanta <= #1 cntquanta_d;
    sbit <= #1 sbit_d;
    btcnt <= #1 btcnt_d;
    bout <= #1 bout_d;
    sdata <= #1 sdata_d;
    dd <= #1 dd_d;
  end
end


endmodule : canxmit
