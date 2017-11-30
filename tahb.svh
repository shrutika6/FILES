// Generated UVM Template -- Created on 2017-03-27 20:42:49.979994262 -0700 PDT
//    input file tahb.uv

package cant ;


import uvm_pkg::*;

`include "cant_defs.svh"

`protect
`uvm_analysis_imp_decl(_drivedin)
`uvm_analysis_imp_decl(_regvals)
`uvm_analysis_imp_decl(_expFrame)
`uvm_analysis_imp_decl(_startbit)
`uvm_analysis_imp_decl(_set_mem)



// class chkframe template
class chkframe extends uvm_scoreboard ;
  `uvm_component_utils(chkframe)

   uvm_analysis_imp_expFrame #(EXPframe,chkframe) expFrame;
   uvm_analysis_port #(reg) drivedin;
   uvm_tlm_analysis_fifo #(reg) rbit;
   uvm_analysis_imp_startbit #(reg,chkframe) startbit;
// init code

  EXPframe e;
  int fpnt;
  reg rb;
  string ohmy;



   function new(string name="chkframe",uvm_component par=null);
     super.new(name,par);
// included new code

    set_report_max_quit_count(5);

   endfunction : new


//  The build phase is to create any components or other
//  elements required
   function void build_phase(uvm_phase phase);
     super.build_phase(phase);
     expFrame= new("expFrame",this);
     drivedin= new("drivedin",this);
     rbit= new("rbit",this);
     startbit= new("startbit",this);
   endfunction : build_phase


//  The connect phase is to bind messages and interfaces
   function void connect_phase(uvm_phase phase);
   endfunction : connect_phase

   // Write function for message expFrame
   function void write_expFrame(input EXPframe din);


    e=din;
    fpnt=0;

   endfunction : write_expFrame

   // Write function for message startbit
   function void write_startbit(input reg din);


  if (e.fdata[fpnt]==DA) begin
    drivedin.write(1'b0);  
  end else begin
    drivedin.write(1'b1);
  end

   endfunction : write_startbit


// A run_phase template. Remove the following comments if used
   task run_phase(uvm_phase phase); 
//           Needs some form forever and waiting statement here

 forever begin
  rbit.get(rb);
//  `uvm_info("debug",$sformatf("Got %h",rb),UVM_LOW)
  if(e.fdata[fpnt] < 2 && rb !== e.fdata[fpnt]) begin
     `uvm_error("error",$sformatf("Expecting a %h, got  %h",e.fdata[fpnt],rb))
     ohmy="";
     for(int ix=0; ix < e.flen; ix=ix+1) begin
         if(ix != fpnt) begin
           ohmy={ohmy,($sformatf("%d %s\n",e.fdata[ix],e.dname[ix]))};
         end else begin
           ohmy={ohmy,$sformatf("--->(%d %s)<---\n",e.fdata[ix],e.dname[ix])};
         end
     end
     `uvm_info("debug",ohmy,UVM_LOW)
  end
  fpnt=fpnt+1;
  if(fpnt >= e.flen) fpnt=e.flen-1;
 end

   endtask : run_phase
endclass : chkframe


// class drv1 template
class drv1 extends uvm_driver #(Si) ;
  `uvm_component_utils(drv1)

   uvm_analysis_port #(Si) expstart;
   uvm_analysis_port #(Si) expwrite;
   uvm_analysis_port #(Si) set_mem;
   virtual cantintf ci;
   virtual AHBIF ai;
// init code

    Si req,expStart;
    int deathcount;
    reg [31:0] dbase,rdata;
    reg [31:0] busy;
    reg [31:0] wv,checkval;
    
    task writereg(input reg[31:0] addr,input [31:0] dw);
        #1;
        ai.HADDR <= addr;
        ai.HTRANS <= HTRANSnonseq;
        ai.HWRITE <= 1;
        ai.HBURST <= 0; // a single transfer...
        ai.HSIZE <= 2;
        ai.HSEL <= 1;
        @(posedge(ai.HCLK));
        while(ai.HREADY == 0) @(posedge(ai.HCLK));
        #1;
        ai.HWDATA <= dw;
        ai.HWRITE <= 0;
        ai.HTRANS <= HTRANSidle;
    endtask : writereg
    
    task readreg(input reg[31:0] addr, output [31:0] rdata);
        #1;
        ai.HADDR <= addr;
        ai.HTRANS <= HTRANSnonseq;
        ai.HWRITE <= 0;
        ai.HBURST <= 0; // a single transfer...
        ai.HSIZE <= 2;
        ai.HSEL <= 1;
        @(posedge(ai.HCLK));
        while(ai.HREADY == 0) @(posedge(ai.HCLK));
        @(posedge(ai.HCLK));
        rdata = ai.HRDATA;
        #1;
        ai.HWDATA <= 0;
        ai.HWRITE <= 0;
        ai.HTRANS <= HTRANSidle;
    
    endtask : readreg



   function new(string name="drv1",uvm_component par=null);
     super.new(name,par);
   endfunction : new


//  The build phase is to create any components or other
//  elements required
   function void build_phase(uvm_phase phase);
     super.build_phase(phase);
     set_mem= new("set_mem",this);
     expstart= new("expstart",this);
     expwrite= new("expwrite",this);
   endfunction : build_phase


//  The connect phase is to bind messages and interfaces
   function void connect_phase(uvm_phase phase);
      if (!uvm_config_db #(virtual AHBIF)::get(this, "*","AHBIF", ai)) begin
         `uvm_error("connect", "failed to find interface AHBIF in DB")
      end
      if (!uvm_config_db #(virtual cantintf)::get(this, "*","cantintf", ci)) begin
         `uvm_error("connect", "failed to find interface cantintf in DB")
      end
   endfunction : connect_phase


// A run_phase template. Remove the following comments if used
   task run_phase(uvm_phase phase); 
//           Needs some form forever and waiting statement here

  // my code here
forever begin  
  seq_item_port.get_next_item(req); // Gets the sequence_item
  dbase=32'hF000_FF00;
  if(req.do_reset) begin
    ci.rst<=1;
    ai.HRESET<=1;
    ai.HTRANS <= 0;
    ai.HSEL <= 0;
    ai.HSIZE <= 2;
    ai.HWRITE <= 0;
    ai.HBURST <= 0;
    repeat(3) @(posedge(ai.HCLK)) #1; 
    ci.rst<=0;
    ai.HRESET<=0;
    repeat(4) @(posedge(ai.HCLK)) #1;
  end else if(req.wbmbusy) begin
    repeat(10)@(posedge(ai.HCLK)) #1;
    readreg(req.caddr,rdata);
    while(rdata[0]==1) begin
       repeat(10) @(posedge(ai.HCLK)) #1;
       readreg(req.caddr,rdata);
    end
    repeat(100) @(posedge(ai.HCLK)) #1;
  end else if(req.wreg) begin
    writereg(req.caddr,req.cdata);
  end else if(req.setmem) begin
    set_mem.write(req);
  end else if(req.waitclks != 0) begin
    repeat(req.waitclks) @(posedge(ai.HCLK)) #1;
  end else if(req.ccode != 0) begin
    case(req.ccode)
      1: begin
        expStart=new("expStartBM");
        expstart.write(req.cpy(expStart));
        expwrite.write(expStart);
      end
      default:
          `uvm_error("Morris",$sformatf("Unknown Si ccode %d",req.ccode))
    endcase
  end else begin
    expStart = new("expStart");
    expstart.write(req.cpy(expStart));
    writereg(dbase+4,req.xmitdata[31:0]);
    writereg(dbase,req.xmitdata[63:32]);
    writereg(dbase+8,{req.quantaDiv,req.propQuanta,req.seg1Quanta,
        req.datalen,req.format,req.frameType,5'b0});
    writereg(dbase+12,{req.id,3'b0});
    writereg(dbase+16,$random);
    repeat(3) @(posedge(ai.HCLK)) #1;
    deathcount=(120+req.datalen*9)*(req.quantaDiv)*(1+req.propQuanta+2*req.seg1Quanta)/2;
    busy=1;
    while(deathcount > -1000 && busy[0] === 1) begin
        wv=$urandom_range(0,4);
        if(wv==4) begin
            readreg(dbase+16,busy);
        end else begin
            readreg(dbase+(4*wv),checkval);
        end
//        readreg(dbase+16,busy);
        deathcount -= 1;
    end
    if(busy[0] === 1'bx) begin
       `uvm_error("error","busy reads back as 'X'") 
    end

    if(deathcount <= 0) begin
       ci.oops<= 1;
       `uvm_error("error","Ran out of clocks for message") 
    end
  end
  seq_item_port.item_done();
end

   endtask : run_phase
endclass : drv1


// class seqr1 template
class seqr1 extends uvm_sequencer #(Si) ;
  `uvm_component_utils(seqr1)



   function new(string name="seqr1",uvm_component par=null);
     super.new(name,par);
   endfunction : new
endclass : seqr1


// class inmon template
class inmon extends uvm_monitor ;
  `uvm_component_utils(inmon)

   uvm_analysis_port #(Si) regvals;
   uvm_tlm_analysis_fifo #(Si) expstart;
   virtual cantintf ci;
// init code

    Si req;
    Si exp;



   function new(string name="inmon",uvm_component par=null);
     super.new(name,par);
   endfunction : new


//  The build phase is to create any components or other
//  elements required
   function void build_phase(uvm_phase phase);
     super.build_phase(phase);
     regvals= new("regvals",this);
     expstart= new("expstart",this);
   endfunction : build_phase


//  The connect phase is to bind messages and interfaces
   function void connect_phase(uvm_phase phase);
      if (!uvm_config_db #(virtual cantintf)::get(this, "*","cantintf", ci)) begin
         `uvm_error("connect", "failed to find interface cantintf in DB")
      end
   endfunction : connect_phase


// A run_phase template. Remove the following comments if used
   task run_phase(uvm_phase phase); 
//           Needs some form forever and waiting statement here

 forever begin
    @(posedge(ci.clk)) begin
      if(ci.rst==0 && ci.startXmit==1) begin
        req = new("regs");        
        req.quantaDiv = ci.quantaDiv;
        req.propQuanta=ci.propQuanta;
        req.seg1Quanta=ci.seg1Quanta;
        req.xmitdata=ci.xmitdata;
        req.datalen=ci.datalen;
        req.id = ci.id;
        req.format = ci.format;
        req.frameType=ci.frameType;
        regvals.write(req);
        if(expstart.is_empty()) begin
           `uvm_error("error","startXmit received, and no expected data") 
        end else begin
           expstart.get(exp);
           if(!exp.cmp(req)) begin
            `uvm_error("error","startXmit data does not match expected");
            `uvm_info("expected",exp.pdata(),UVM_LOW);
            `uvm_info("Received",req.pdata(),UVM_LOW);
           end
        end
      end
    end
 end

   endtask : run_phase
   function void check_phase(uvm_phase phase);

  if(!expstart.is_empty()) begin
     `uvm_error("error","Not all expected frames were started") 
  end


   endfunction : check_phase
endclass : inmon


// class pfind template
class pfind extends uvm_scoreboard ;
  `uvm_component_utils(pfind)

   uvm_tlm_analysis_fifo #(DBIT) dbit;
   uvm_analysis_imp_regvals #(Si,pfind) regvals;
   uvm_analysis_port #(reg) rbit;
   uvm_analysis_port #(reg) startbit;
// init code

  typedef enum int { Bidle,Bedge,Bpost } bstate;
  bstate svar;
  DBIT db;
  reg oldval;
  reg fell,rose,oldbit;
  int oldcnt;
  Si regsi;
  int cntr;
  logic lastval;



   function new(string name="pfind",uvm_component par=null);
     super.new(name,par);
// included new code


svar = Bidle;
oldval=1;
oldcnt=0;
lastval=0;


   endfunction : new


//  The build phase is to create any components or other
//  elements required
   function void build_phase(uvm_phase phase);
     super.build_phase(phase);
     dbit= new("dbit",this);
     regvals= new("regvals",this);
     rbit= new("rbit",this);
     startbit= new("startbit",this);
   endfunction : build_phase


//  The connect phase is to bind messages and interfaces
   function void connect_phase(uvm_phase phase);
   endfunction : connect_phase

   // Write function for message regvals
   function void write_regvals(input Si din);


  regsi=din;

   endfunction : write_regvals


// A run_phase template. Remove the following comments if used
   task run_phase(uvm_phase phase); 
//           Needs some form forever and waiting statement here

 forever begin
  dbit.get(db);
//  `uvm_info("debug",$sformatf("s %h st %d t %f",db.dout,svar,$realtime),UVM_LOW)
  if(db.dout == 0 && oldval==1) fell=1; else fell=0;
  if(db.dout == 1 && oldval==0) rose=1; else rose=0;
  case(svar)
    Bidle: begin
      oldcnt=1;
      if(fell) begin
        svar = Bedge;
        cntr = regsi.quantaDiv;
        cntr *= (1+regsi.propQuanta+regsi.seg1Quanta);
        
      end
    end
    
    Bedge: begin
      if(cntr <= 1) begin
         cntr = regsi.quantaDiv;
         cntr *= (regsi.seg1Quanta);
         svar = Bpost;
         if(db.dout == lastval) begin
            oldcnt=oldcnt+1;
            if(oldcnt > 5 && db.dout==1) begin
            svar = Bidle;    
            end
         end else begin
            oldcnt=1;            
         end
         lastval = db.dout;
//         `uvm_info("debug",$sformatf("sample %h at %f ns %d",db.dout,$realtime,svar),UVM_LOW)
         rbit.write(db.dout);
      end else begin
         cntr=cntr-1; 
      end
    end
    
    Bpost: begin
      if(cntr <= 1) begin
          svar = Bedge;
          cntr = regsi.quantaDiv;
          cntr *= (1+regsi.propQuanta+regsi.seg1Quanta);
          startbit.write(1'b1);
      end else begin
         cntr = cntr-1;
      end
    end
    
  endcase
  oldval = db.dout;
 end

   endtask : run_phase
endclass : pfind


// class bittime template
class bittime extends uvm_scoreboard ;
  `uvm_component_utils(bittime)

   uvm_tlm_analysis_fifo #(DBIT) dbit;
   uvm_analysis_imp_regvals #(Si,bittime) regvals;
// init code


DBIT db;
Si regsi;
reg oldval;
int bcnt;
int modres;
int bsize;



   function new(string name="bittime",uvm_component par=null);
     super.new(name,par);
// included new code

  regsi=null;
  oldval=1'bX;
  bcnt=0;

   endfunction : new


//  The build phase is to create any components or other
//  elements required
   function void build_phase(uvm_phase phase);
     super.build_phase(phase);
     dbit= new("dbit",this);
     regvals= new("regvals",this);
   endfunction : build_phase


//  The connect phase is to bind messages and interfaces
   function void connect_phase(uvm_phase phase);
   endfunction : connect_phase

   // Write function for message regvals
   function void write_regvals(input Si din);


  regsi=din;
  bsize = (1+regsi.propQuanta+2*regsi.seg1Quanta)*regsi.quantaDiv;

   endfunction : write_regvals


// A run_phase template. Remove the following comments if used
   task run_phase(uvm_phase phase); 
//           Needs some form forever and waiting statement here

 forever begin
    dbit.get(db);
    if(db.dout===0'b1 && oldval === 1'b1) begin
        bcnt=0;
    end else if(db.dout===1'b1 && oldval === 1'b0) begin
        modres = bcnt % bsize;
        if(modres !=0) begin
           `uvm_error("error",$sformatf("bit time error. Remainder of %d is %d clocks",bsize,modres)) 
        end
        bcnt = 0;
    end else begin
        bcnt += 1;
//        `uvm_info("bit",$sformatf("bit %h bcnt %d",db.dout,bcnt),UVM_LOW)
    end
    oldval = db.dout;
 end

   endtask : run_phase
endclass : bittime


// class datamon template
class datamon extends uvm_monitor ;
  `uvm_component_utils(datamon)

   uvm_analysis_port #(DBIT) dbit;
   uvm_analysis_imp_drivedin #(reg,datamon) drivedin;
   virtual cantintf ci;
// init code

DBIT req;
reg dother;
reg ddut;



   function new(string name="datamon",uvm_component par=null);
     super.new(name,par);
   endfunction : new


//  The build phase is to create any components or other
//  elements required
   function void build_phase(uvm_phase phase);
     super.build_phase(phase);
     dbit= new("dbit",this);
     drivedin= new("drivedin",this);
   endfunction : build_phase


//  The connect phase is to bind messages and interfaces
   function void connect_phase(uvm_phase phase);
      if (!uvm_config_db #(virtual cantintf)::get(this, "*","cantintf", ci)) begin
         `uvm_error("connect", "failed to find interface cantintf in DB")
      end
   endfunction : connect_phase

   // Write function for message drivedin
   function void write_drivedin(input reg din);


  dother=din;
  ci.din <= dother & ddut;

   endfunction : write_drivedin


// A run_phase template. Remove the following comments if used
   task run_phase(uvm_phase phase); 
//           Needs some form forever and waiting statement here

 forever begin
    @(posedge(ci.clk)) begin
      if(ci.rst != 1) begin
          req = new("bitmsg");
          req.dout = ci.dout;
          ddut = ci.dout;
          req.ddrive= ci.ddrive;
          ci.din <= ddut & dother;
          req.din = ci.din;
          dbit.write(req);
      end
    end
 end

   endtask : run_phase
endclass : datamon


// class expframe template
class expframe extends uvm_scoreboard ;
  `uvm_component_utils(expframe)

   uvm_analysis_port #(EXPframe) expFrame;
   uvm_analysis_imp_regvals #(Si,expframe) regvals;
// init code

  Si d;
  EXPframe e;
  reg [14:0] crc;
  int bscnt;
  reg lbit;
  
  function void calcCrc(reg di);
     reg nxb=di ^ crc[14];
     crc=crc << 1;
     if(nxb) begin
       crc = crc ^ 15'h4599;       
     end
//     `uvm_info("debug",$sformatf("crc %4h di %h",crc,di),UVM_LOW)
  endfunction : calcCrc

  function void addbit(Ebit bt,string bname);
//    `uvm_info("debug",$sformatf("Adding %d cnt %d lbit %d",bt,bscnt,lbit),UVM_LOW)
    e.fdata[e.flen]=bt;
    e.dname[e.flen]=bname;
    e.flen += 1;
  endfunction : addbit

  function void addbin(reg di,string nm,reg docrc=1);
    if(di === lbit) begin
      if(bscnt>=5) begin
         bscnt=1;
         addbit((di==0)?D1:D0,"stf");
         lbit= ~di;
      end else bscnt=bscnt+1;
    end else begin
      bscnt = 1;
      lbit=di;
    end
    addbit((di===1'b1)?D1:D0,nm);
    lbit=di;
    if(docrc) calcCrc(di);
  endfunction : addbin



   function new(string name="expframe",uvm_component par=null);
     super.new(name,par);
   endfunction : new


//  The build phase is to create any components or other
//  elements required
   function void build_phase(uvm_phase phase);
     super.build_phase(phase);
     expFrame= new("expFrame",this);
     regvals= new("regvals",this);
   endfunction : build_phase


//  The connect phase is to bind messages and interfaces
   function void connect_phase(uvm_phase phase);
   endfunction : connect_phase

   // Write function for message regvals
   function void write_regvals(input Si din);


    d=din;
    e= new();
    e.flen=0;
    crc=0;
    bscnt=1;
    lbit=1'b1;
    case(d.frameType)
      XMITdataframe,XMITremoteframe: begin
        addbin(0,"sof");
        for( int ix = 28; ix >=18; ix=ix-1) begin
            addbin(d.id[ix],$sformatf("id%02d",ix));
        end
        if(d.format) begin // extended frame
            addbin(1,"srr");
            addbin(0,"ide");       // the extended field (Check this)
            for(int ix = 17; ix >= 0; ix=ix-1) addbin(d.id[ix],$sformatf("id%02d",ix));
        end
        addbin( (d.frameType==XMITremoteframe)?1:0,"rtr" );
        addbin(0,"r1");
        addbin(0,"r0");
        for(int ix=3; ix >=0; ix=ix-1) begin
           addbin(d.datalen[ix],$sformatf("dlen%02d",ix)); 
        end
        if( d.frameType == XMITdataframe) begin
          for(int ix=8; ix > 8-d.datalen; ix=ix-1) begin
            for(int iy=1; iy < 9; iy=iy+1) begin
               addbin(d.xmitdata[ix*8-iy],$sformatf("dbit%02d",ix*8-iy)); 
            end
          end
        end
        for(int ix=14; ix >=0; ix=ix-1) begin
           addbin(crc[ix],$sformatf("crc%02d",ix),0); 
        end
        addbit(DA,"ack");
        addbit(D1,"ack delim");
        for(int ix=7; ix > 0; ix=ix-1) addbit(D1,"eof");
      end
      XMITerrorframe,XMIToverloadframe: begin
        for(int ix=0; ix < 6; ix=ix+1) addbit(D0,"err");
      end
    endcase
    expFrame.write(e);
    

   endfunction : write_regvals


// A run_phase template. Remove the following comments if used
   task run_phase(uvm_phase phase); 
//           Needs some form forever and waiting statement here
   endtask : run_phase
endclass : expframe


// class ahbs template
class ahbs extends uvm_monitor ;
  `uvm_component_utils(ahbs)

   virtual AHBIF ai;
// init code

  logic [31:0] mem[logic[31:0]];
  
  task arbitrate();
  
  endtask : arbitrate
  
  task arb_done();
  
  endtask : arb_done





   function new(string name="ahbs",uvm_component par=null);
     super.new(name,par);
   endfunction : new


//  The build phase is to create any components or other
//  elements required
   function void build_phase(uvm_phase phase);
     super.build_phase(phase);
   endfunction : build_phase


//  The connect phase is to bind messages and interfaces
   function void connect_phase(uvm_phase phase);
      if (!uvm_config_db #(virtual AHBIF)::get(this, "*","AHBIF", ai)) begin
         `uvm_error("connect", "failed to find interface AHBIF in DB")
      end
   endfunction : connect_phase


// A run_phase template. Remove the following comments if used
   task run_phase(uvm_phase phase); 
//           Needs some form forever and waiting statement here

      ai.mHGRANT<=0;
      ai.mHREADY<=1;
      fork
        forever begin
          @(ai.HCLK);
          if(ai.mHBUSREQ && ai.mHREADY) begin
            arbitrate();
            #1;
            ai.mHGRANT=1;
            repeat(2) @(ai.HCLK);
            #1;
            while(ai.mHTRANS != 0) @(ai.HCLK);
            #1; // Now for some outputs
            ai.mHGRANT=0;
            arb_done();
          end
        end
      join_none



   endtask : run_phase
endclass : ahbs


// class slavemon template
class slavemon extends uvm_monitor ;
  `uvm_component_utils(slavemon)

   uvm_tlm_analysis_fifo #(Si) expwrite;
   uvm_analysis_imp_set_mem #(Si,slavemon) set_mem;
   virtual AHBIF ai;
// init code

reg [31:0] mem[reg[31:0]];
reg wnext;
reg [31:0] waddr;
Si exp;



   function new(string name="slavemon",uvm_component par=null);
     super.new(name,par);
   endfunction : new


//  The build phase is to create any components or other
//  elements required
   function void build_phase(uvm_phase phase);
     super.build_phase(phase);
     expwrite= new("expwrite",this);
     set_mem= new("set_mem",this);
   endfunction : build_phase


//  The connect phase is to bind messages and interfaces
   function void connect_phase(uvm_phase phase);
      if (!uvm_config_db #(virtual AHBIF)::get(this, "*","AHBIF", ai)) begin
         `uvm_error("connect", "failed to find interface AHBIF in DB")
      end
   endfunction : connect_phase

   // Write function for message set_mem
   function void write_set_mem(input Si din);


  mem[din.memaddr]=din.memdata;

   endfunction : write_set_mem


// A run_phase template. Remove the following comments if used
   task run_phase(uvm_phase phase); 
//           Needs some form forever and waiting statement here

fork
 forever begin
  ai.mHREADY <= 1;
  @(posedge(ai.HCLK));
  if(ai.mHREADY==1 && ai.mHTRANS[1]==1) begin
    if( ai.mHWRITE == 0) begin
        ai.mHRDATA <= #1 mem[ai.mHADDR];
//        `uvm_error("debug",$sformatf("%08x <= [%08x]",mem[ai.mHADDR],ai.mHADDR))
    end else begin
//        `uvm_error("debug",$sformatf("mwr %h",ai.mHWRITE))
        ai.mHRDATA <= #1 32'h4311;
        #1 wnext=1;
        waddr = ai.mHADDR;
    end
  end
 end
 forever begin
    @(posedge(ai.HCLK));
    if(wnext) begin
       if(expwrite.is_empty()) begin
          `uvm_error("error",$sformatf("Unexpected write occurred at %08h",waddr)) 
       end else begin
         expwrite.get(exp);
         if(exp.caddr !== waddr) begin
           `uvm_error("error",$sformatf("Expecting a write to %08h, received one to %08h",exp.caddr,waddr))
         end
         if(exp.cdata !== ai.mHWDATA) begin
            `uvm_error("error",$sformatf("Expecting write data %08h, received %08h",exp.cdata,ai.mHWDATA))
         end
       end
       mem[waddr]=ai.mHWDATA; 
    end
    wnext=0;
 end
join_none

   endtask : run_phase
   function void check_phase(uvm_phase phase);

  if(!expwrite.is_empty()) begin
     `uvm_error("error",$sformatf("Expecting %d more writes to memory",expwrite.used())) 
  end


   endfunction : check_phase
endclass : slavemon


// class agent1 template
class agent1 extends uvm_agent ;
  `uvm_component_utils(agent1)

   seqr1 sqr1 ;
   inmon imon ;
   pfind pf ;
   bittime btime ;
   slavemon smon ;
   drv1 d1 ;
   expframe expf ;
   chkframe cframe ;
   ahbs ahbmemslave ;
   datamon dmon ;


   function new(string name="agent1",uvm_component par=null);
     super.new(name,par);
   endfunction : new


//  The build phase is to create any components or other
//  elements required
   function void build_phase(uvm_phase phase);
     super.build_phase(phase);
      ahbmemslave = ahbs::type_id::create("ahbmemslave",this);
      dmon = datamon::type_id::create("dmon",this);
      expf = expframe::type_id::create("expf",this);
      cframe = chkframe::type_id::create("cframe",this);
      pf = pfind::type_id::create("pf",this);
      btime = bittime::type_id::create("btime",this);
      smon = slavemon::type_id::create("smon",this);
      d1 = drv1::type_id::create("d1",this);
      sqr1 = seqr1::type_id::create("sqr1",this);
      imon = inmon::type_id::create("imon",this);
   endfunction : build_phase


//  The connect phase is to bind messages and interfaces
   function void connect_phase(uvm_phase phase);
      pf.startbit.connect(cframe.startbit);
      d1.set_mem.connect(smon.set_mem);
      d1.expstart.connect(imon.expstart.analysis_export);
      dmon.dbit.connect(pf.dbit.analysis_export);
      dmon.dbit.connect(btime.dbit.analysis_export);
      cframe.drivedin.connect(dmon.drivedin);
      imon.regvals.connect(expf.regvals);
      imon.regvals.connect(pf.regvals);
      imon.regvals.connect(btime.regvals);
      expf.expFrame.connect(cframe.expFrame);
      pf.rbit.connect(cframe.rbit.analysis_export);
      d1.expwrite.connect(smon.expwrite.analysis_export);
      d1.seq_item_port.connect(sqr1.seq_item_export);
   endfunction : connect_phase
endclass : agent1


// class env1 template
class env1 extends uvm_env ;
  `uvm_component_utils(env1)

   agent1 a1 ;


   function new(string name="env1",uvm_component par=null);
     super.new(name,par);
   endfunction : new


//  The build phase is to create any components or other
//  elements required
   function void build_phase(uvm_phase phase);
     super.build_phase(phase);
      a1 = agent1::type_id::create("a1",this);
   endfunction : build_phase


//  The connect phase is to bind messages and interfaces
   function void connect_phase(uvm_phase phase);
   endfunction : connect_phase
endclass : env1


// class seq1 template
class seq1 extends uvm_sequence #(Si) ;
  `uvm_object_utils(seq1)

// init code

  Si r,w;
  reg [31:0] oldblk,newblk,baseblk;
  
  task wreg(reg [31:0] addr, reg [31:0] dataval);
    start_item(r);
      r.wreg=1;
      r.caddr=addr;
      r.cdata=dataval;
    finish_item(r);
    r.wreg=0;
  
  endtask : wreg
  
  task wmem(reg [31:0] addr, reg [31:0] dataval);
    start_item(r);
    r.do_reset=0;
    r.waitclks=0;
    r.setmem=1;
    r.memaddr=addr;
    r.memdata=dataval;
    finish_item(r);
    r.setmem=0;
  endtask : wmem
  
  task setblk(reg [31:0] blkaddr);
    wmem(blkaddr+32'h00,w.xmitdata[63:32]);
    wmem(blkaddr+32'h04,w.xmitdata[31:0]);
    wmem(blkaddr+32'h08,{w.quantaDiv,w.propQuanta,w.seg1Quanta,
        w.datalen,w.format,w.frameType,5'b0});
    wmem(blkaddr+32'h0c,{w.id,3'b0});
    w.caddr=32'hf000_0010+$urandom_range(0,50)*4;
    w.cdata=$random;
    wmem(blkaddr+32'h10,w.caddr);
    wmem(blkaddr+32'h14,w.cdata);
    wmem(blkaddr+32'h18,32'h0);
  endtask : setblk
  
  task dpblk(input Si w,input reg [31:0] blkaddr);
    $display("Block items at %08h",blkaddr);
    $display("  data %016h",w.xmitdata);
    $display("  cmd  %08h",{w.quantaDiv,w.propQuanta,w.seg1Quanta,
        w.datalen,w.format,w.frameType,5'b0});
    $display("  id   %08h",{w.id,3'b0});
    $display("  addr %08h",w.caddr);
    $display("  data %08h",w.cdata);
  
  endtask : dpblk
  
  task makeblk(reg [31:0] oldblk,reg[31:0] newblk);
    if(oldblk != 0) wmem(oldblk+32'h18,newblk); // set the link
    w.randomize() with { quantaDiv>0 && quantaDiv<6;
        propQuanta > 0 && propQuanta<8;
        seg1Quanta<=6; seg1Quanta>0;
      datalen < 9; datalen>=0;
      };
    w.frameType=cantidef::XMITdataframe;
    w.caddr = 32'h3000_0000+$urandom_range(0,1000)*4;
    w.cdata = $random();
    w.ccode=1;  // expect a start on this...
    setblk(newblk);
    start_item(r);
    w.cpy(r);
    finish_item(r);
    
    dpblk(w,newblk);
  
  endtask : makeblk



   function new(string name="seq1");
      super.new(name);
   endfunction : new


// A sequence body template. put tests there
   task body;


//  `uvm_info("prelimary","This is a preliminary test bench",UVM_LOW)
  r=Si::type_id::create("td");
  w=Si::type_id::create("wd");
  r.waitclks=0;
  start_item(r);
  r.randomize();
  r.do_reset=1;
  finish_item(r);
  start_item(r);
  r.do_reset=0;
  r.randomize() with { quantaDiv==4; propQuanta==3; seg1Quanta==6;
      datalen < 9; datalen>0; format==0;
      frameType==cantidef::XMITdataframe; id==29'h1000000;};
  finish_item(r);
  repeat(5) begin
    start_item(r);
    r.do_reset=0;
    r.randomize() with { quantaDiv==4; propQuanta==3;
        seg1Quanta<=6; seg1Quanta>0;
      datalen < 9; datalen>0; format==0;
      };
      r.frameType=cantidef::XMITdataframe;
    finish_item(r);
  end
  repeat(5) begin
    start_item(r);
    r.do_reset=0;
    r.randomize() with { quantaDiv>0 && quantaDiv<6;
        propQuanta > 0 && propQuanta<8;
        seg1Quanta<=6; seg1Quanta>0;
      datalen < 9; datalen>=0; format==0;
      };
      r.frameType=cantidef::XMITremoteframe;
    finish_item(r);
  end
  repeat(5) begin
    start_item(r);
    r.do_reset=0;
    r.randomize() with { quantaDiv==4; propQuanta==3;
        seg1Quanta<=6; seg1Quanta>0;
      datalen < 9; datalen>0; format==1;
      };
      r.frameType=cantidef::XMITdataframe;
    finish_item(r);
  end
  repeat(5) begin
    start_item(r);
    r.do_reset=0;
    r.randomize() with { quantaDiv>0 && quantaDiv<6;
        propQuanta > 0 && propQuanta<8;
        seg1Quanta<=6; seg1Quanta>0;
      datalen < 9; datalen>=0; format==1;
      };
      r.frameType=cantidef::XMITremoteframe;
    finish_item(r);
  end
  start_item(r);
  r.waitclks=5000;
  finish_item(r);
  r.waitclks=0;
  oldblk=0;
  baseblk=32'h1010;
  repeat(1) begin
    oldblk=0;
    repeat(15) begin
        oldblk=0;
        newblk=baseblk+$urandom_range(0,500)*16;
        wreg(32'hf000_ff14,newblk);
        repeat($urandom_range(10,20)) begin
          
          makeblk(oldblk,newblk);
          oldblk=newblk;
          newblk += $urandom_range(3,22)*32;
        end
        wreg(32'hf000_ff18,0);
        start_item(r);
        r.ccode=0;
        r.caddr=32'hf000_ff18;
        r.wbmbusy=1;
        finish_item(r);
        r.wbmbusy=0;
        r.waitclks=0;
        baseblk = baseblk+32'h2020;
    end
  end
  start_item(r);
  r.waitclks=5000;
  finish_item(r);

   endtask : body
endclass : seq1


// class t1 template
class t1 extends uvm_test ;
  `uvm_component_utils(t1)

   env1 e1 ;
   seq1 s1 ;


   function new(string name="t1",uvm_component par=null);
     super.new(name,par);
   endfunction : new


//  The build phase is to create any components or other
//  elements required
   function void build_phase(uvm_phase phase);
     super.build_phase(phase);
      e1 = env1::type_id::create("e1",this);
      s1 = seq1::type_id::create("s1",this);
   endfunction : build_phase


//  The connect phase is to bind messages and interfaces
   function void connect_phase(uvm_phase phase);
   endfunction : connect_phase


// The test run_phase starts the tests
   task run_phase(uvm_phase phase);
      // Keep simulation running by raising the objection
      phase.raise_objection(this,"start sequence");
//      Change sequence order as needed
      s1.start(e1.a1.sqr1);
      phase.drop_objection(this,"end sequence");
   endtask : run_phase
endclass : t1

`endprotect

endpackage : cant
