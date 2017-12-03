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


////////////////////////////////////////////////////
integer err_count=0;
class mjerr;
  static task err(string loc, string msg);
    begin
      if(err_count < 10) begin
      `uvm_error(loc,msg)
      end
      if(err_count == 10) begin
        `uvm_error("Suppressed","10 or more errors seen, reporting suppressed")
        
      end
      err_count = err_count + 1;
    end
  endtask : err

endclass : mjerr
///////////////////////////////////////////////////

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
string Hello;


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
	//Hello="";
     for(int ix=0; ix < e.flen; ix=ix+1) begin
         if(ix != fpnt) begin
           ohmy={ohmy,($sformatf("%d %s\n",e.fdata[ix],e.dname[ix]))};
	//Hello={Hello,($sformatf("%d %s\n",e.fdata[ix],e.dname[ix]))};
         end else begin
           ohmy={ohmy,$sformatf("--->(%d %s)<---\n",e.fdata[ix],e.dname[ix])};
	//Hello={Hello,$sformatf("--->(%d %s)<---\n",e.fdata[ix],e.dname[ix])};
         end
     end
     `uvm_info("debug",ohmy,UVM_LOW)
	//`uvm_info("debug",Hello,UVM_LOW)
  end
  fpnt=fpnt+1;
  if(fpnt >= e.flen) fpnt=e.flen-1;
 end

   endtask : run_phase
endclass : chkframe


// class drv1 template
class drv1 extends uvm_driver #(Si) ;
  `uvm_component_utils(drv1)
   uvm_analysis_port #(logic) CheckInitDone; // wait for DDR3 to initialize 
   uvm_analysis_port #(reg) sreq;      // arbitration request
  uvm_tlm_analysis_fifo #(reg) sresp; // arbitration respons
  uvm_analysis_port #(reg) sdone;     // release arbitration
  reg [1:0] respid;                         // Did we win arbitration???
   uvm_analysis_port #(Si) expstart;
   uvm_analysis_port #(Si) expwrite;
   uvm_analysis_port #(Si) set_mem;
   virtual cantintf ci;
   virtual AHBIF if0;
   virtual AHBIF ai;
// init code
string HI;
    Si req,expStart;
    int deathcount;
    reg [31:0] dbase,rdata;
    reg [31:0] busy;
    reg [31:0] wv,checkval;
    logic init_done, write_done;
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
     sreq = new("sreq",this);
      sresp = new("sresp",this);
      sdone = new("sdone",this);
     CheckInitDone = new("CheckInitDone",this);     //////////////////////////////////////
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
   

   /////////////////////////////////////////////
  task arbitrate();
    begin
      sreq.write(1);
      respid=0;
      while(respid != 1) begin
        sresp.get(respid);
      end
    end
  endtask : arbitrate
  
  task arb_done();
    begin
      sdone.write(1);
    end
  endtask : arb_done




   task wait_for_init_done();
    begin
      init_done = 1'b0;
      while(init_done != 1'b1) begin
        init_done <= if0.init_done;
        `uvm_info("InitializeDDR", "Waiting for init_done....", UVM_DEBUG)
        `uvm_info("InitializeDDR", $sformatf("init_done: %b", init_done), UVM_DEBUG)
        repeat (100) @(if0.cb);
      end 
    end 
  endtask : wait_for_init_done
  
  task wait_for_write_done();
    begin
      write_done = 1'b0;
      while(write_done != 1'b1) begin
        write_done <= if0.write_done;
        `uvm_info("WriteToDDR3", "Waiting for writes....", UVM_DEBUG)
        `uvm_info("WriteToDDR3", $sformatf("write_done: %b", write_done), UVM_LOW)
        repeat (10) @(if0.cb);
      end 
    end 
  endtask : wait_for_write_done
//////////////////////////////////////////////////////////////////////
  
  
// A run_phase template. Remove the following comments if used
   task run_phase(uvm_phase phase); 
//           Needs some form forever and waiting statement here

  // my code here
forever begin  
  seq_item_port.get_next_item(req); // Gets the sequence_item
`uvm_info("Req code", $sformatf("req code: %d",req.ccode), UVM_LOW)
  dbase=32'hF000_FF00;
`uvm_info("Req reset", $sformatf("req reset: %d",req.do_reset), UVM_LOW)
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
    //ci.startXmit<=1;
    ai.HRESET<=0;
    repeat(4) @(posedge(ai.HCLK)) #1;
`uvm_info("Req busy", $sformatf("req busy: %d",req.wbmbusy), UVM_LOW)
  end else if(req.wbmbusy) begin
    repeat(10)@(posedge(ai.HCLK)) #1;
    readreg(req.caddr,rdata);
    while(rdata[0]==1) begin
       repeat(10) @(posedge(ai.HCLK)) #1;
       readreg(req.caddr,rdata);
    end
    repeat(100) @(posedge(ai.HCLK)) #1;
`uvm_info("Req reg", $sformatf("req reg: %d",req.wreg), UVM_LOW)
  end else if(req.wreg) begin
    writereg(req.caddr,req.cdata);
`uvm_info("Req reg", $sformatf("req mem: %d",req.setmem), UVM_LOW)
  end else if(req.setmem) begin
    set_mem.write(req);
`uvm_info("Req reg", $sformatf("req reg: %d",req.waitclks), UVM_LOW)
  end else if(req.waitclks != 0) begin
    repeat(req.waitclks) @(posedge(ai.HCLK)) #1;
`uvm_info("req code", $sformatf("if value received: %b", req.ccode), UVM_LOW)
  end else if(req.ccode != 0) begin

    case(req.ccode)
      1: begin
        expStart=new("expStartBM");
        expstart.write(req.cpy(expStart));
	`uvm_info("debug",HI, UVM_LOW)
        expwrite.write(expStart);
      end
      2: begin      /////////////////////////////////////////////////////////
                //ai.HSEL=0;
                //$display("%b", ai.init_done);
                wait_for_init_done();
                `uvm_info("InitializeDDR", $sformatf("init_done: %b", if0.init_done), UVM_DEBUG)
                CheckInitDone.write(1'b1); // write to write_drv 
                @(if0.cb) #1;
              end
      3: begin
                wait_for_write_done();
                `uvm_info("WriteToDDR3", $sformatf("Done Waiting: %b", ai.write_done), UVM_LOW)
              end       //////////////////////////////////////////////////////////////////////////////
      default:
          `uvm_error("Morris",$sformatf("Unknown Si ccode %d",req.ccode))
    endcase
  end else begin
    expStart = new("expStart");
    expstart.write(req.cpy(expStart));
`uvm_info("expect start", $sformatf("expect start: %d", expStart), UVM_LOW)
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
    virtual AHBIF ai; // handles the interface items	
    Si req;
    Si exp;

string HI;

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
      if (!uvm_config_db #(virtual AHBIF)::get(null, "uvm_test_top","AHBIF", this.ai)) begin   //////////////////////////////////////////////////////
          mjerr::err("connect", "AHBIF not found");
      end
      
   endfunction : connect_phase


// A run_phase template. Remove the following comments if used
   task run_phase(uvm_phase phase); 
//           Needs some form forever and waiting statement here
 //begin
   //   ai.mHGRANT=0; // <= #1 0;
   //   ai.mHREADY=1; // <= #1 1;
   //   xfrp1=0;
   //   fork
     //   forever begin
       //  @(ai.cb);
         // if(xfrp1) begin
           //`uvm_info("memaccess",$sformatf("[%h] -> %h",addrp1,mem[addrp1]),UVM_LOW)
            //ai.mHRDATA= #1 mem[addrp1];
          //end else begin
           // ai.mHRDATA= #1 0;
          //end
        //end
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
	`uvm_info("debug",HI, UVM_LOW)
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
//join_none
//end
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
  //sdone.write(2);
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
          if(ai.mHBUSREQ /*&&  ai.mHREADY */) begin
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
   virtual AHBIF if0;
// init code

reg [31:0] mem[reg[31:0]];
reg wnext;
reg [31:0] waddr;
Si exp;

reg [31:0] addrx,datax;

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
      if (!uvm_config_db #(virtual AHBIF)::get(this, "*","AHBIF", if0)) begin
         `uvm_error("connect", "failed to find interface AHBIF in DB")
      end
   endfunction : connect_phase

   // Write function for message set_mem
   function void write_set_mem(input Si din);


  //mem[din.memaddr]=din.memdata;

   endfunction : write_set_mem


// A run_phase template. Remove the following comments if used
   task run_phase(uvm_phase phase); 
//           Needs some form forever and waiting statement here

fork
 forever begin
  if0.mHREADY <= 1;
  @(posedge(if0.HCLK));
  if(if0.mHREADY==1 && if0.mHTRANS[1]==1 && if0.mHGRANT) begin
    if( if0.mHWRITE == 0) begin
        //if0.mHRDATA <= #1 mem[if0.mHADDR];
//        `uvm_error("debug",$sformatf("%08x <= [%08x]",mem[if0.mHADDR],if0.mHADDR))
    end else begin
//        `uvm_error("debug",$sformatf("mwr %h",if0.mHWRITE))
        if0.mHRDATA <= #1 32'h4311;
        #1 wnext=1;
        waddr = if0.mHADDR;
    end
  end
 end
 forever begin
    @(posedge(if0.HCLK));
    if(wnext) begin
       if(expwrite.is_empty()) begin
          `uvm_error("error",$sformatf("Unexpected write occurred at %08h",waddr)) 
       end else begin
         expwrite.get(exp);
         if(exp.caddr !== waddr) begin
           `uvm_error("error",$sformatf("Expecting a write to %08h, received one to %08h",exp.caddr,waddr))
         end
         if(exp.cdata !== if0.mHWDATA) begin
            `uvm_error("error",$sformatf("Expecting write data %08h, received %08h",exp.cdata,if0.mHWDATA))
         end
       end
       mem[addrx]=datax; 
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




//--------------------------------------------
// This is a simple monitor to look at the bus
// Master signals, and respond with memory data
//
class bm_mon extends uvm_monitor;

`uvm_component_utils(bm_mon)

virtual AHBIF if0; // handles the interface items

  uvm_analysis_port #(reg ) sreq;      // arbitration request
  uvm_tlm_analysis_fifo #(reg) sresp; // arbitration respons
  uvm_analysis_port #(reg) sdone;     // release arbitration
  reg [1:0] respid;                         // Did we win arbitration???
  logic xfrp1;
  logic [31:0] addrp1;
  logic [31:0] mem[logic[31:0]];

  function new(string name="bm_mon",uvm_component par=null);
    super.new(name,par);
  endfunction : new
  
  function void connect_phase(uvm_phase phase);
      if (!uvm_config_db #(virtual AHBIF)::get(null, "uvm_test_top",
        "ahbif", this.if0)) begin
          mjerr::err("connect", "ahbif not found");
         end 
  endfunction: connect_phase;

  function void build_phase(uvm_phase phase);
    logic [31:0] aix;
    begin
      sreq = new("bmreq",this);
      sdone = new("bmdone",this);
      sresp = new("bmresp",this);
      //for(aix=0; aix < 1024; aix=aix+4) begin
        //mem[32'h123450+aix]=aix+((aix+1)<<8)+((aix+2)<<16)+((aix+3)<<24);
//        `uvm_info("mem",$sformatf("mem[%h]=%h",32'h123450+aix,mem[32'h123450+aix]),UVM_LOW)
     // end
      
    end
  endfunction : build_phase
  
  task arbitrate();
    begin
      sreq.write(2);
      respid=0;
      while(respid != 2) begin
        sresp.get(respid);
      end
    end
  endtask : arbitrate
  
  task arb_done();
    begin
      sdone.write(2);
    end
  endtask : arb_done

  
  task run_phase(uvm_phase phase);
    begin
      if0.mHGRANT<= #1 0;
      if0.mHREADY<= #1 1;
      xfrp1=0;
      fork
//        forever begin
//          @(if0.cb);
//          if(xfrp1) begin
//            `uvm_info("memaccess",$sformatf("[%h] -> %h",addrp1,mem[addrp1]),UVM_LOW)
//            if0.mHRDATA= #1 mem[addrp1];
//          end else begin
//            if0.mHRDATA= #1 0;
//          end
//        end
        forever begin
          @(if0.cb);
          if(if0.mHREADY && if0.mHTRANS[1] && if0.mHGRANT) begin
            //if0.mHRDATA = #1 mem[if0.mHADDR];
//            addrp1 = #1 if0.mHADDR;
//            xfrp1= #1 1;
            if(if0.mHWRITE) begin
              mjerr::err("bus_master","Master cannot perform write on this project");
            end
          end else begin
//            addrp1=#1 0;
//            xfrp1=#1 0;
              if0.mHRDATA=#1 32'h4321;
          end
        end
        forever begin
          @(if0.cb);
          if(if0.mHBUSREQ) begin
            arbitrate();
            #1;
            if0.mHGRANT=1;
            repeat(2) @(if0.cb);
            #1;
            while(if0.mHTRANS != HTRANSidle) @(if0.cb);
            #1; // Now for some outputs
            if0.mHGRANT=0;
            arb_done();
          end
        end
      join_none
    end
  endtask : run_phase
endclass : bm_mon


//--------------------------------------------
// This handles arbitration of the bus signals
// It is a brain dead round robin arbitrator
//
class bmarbitrator extends uvm_component;

`uvm_component_utils(bmarbitrator)

reg [1:0] reqid;
reg [1:0] doneid;
uvm_tlm_analysis_fifo #(reg) bmreq;
uvm_tlm_analysis_fifo #(reg) bmdone;
uvm_analysis_port     #(reg) bmresp;

  function new(string name="bmarb",uvm_component par=null);
    super.new(name,par);
  endfunction : new

  function void build_phase(uvm_phase phase);
    begin
      bmreq = new("bmreq",this);
      bmdone = new("bmdone",this);
      bmresp = new("bmresp",this);
    end
  endfunction : build_phase
  
  task run_phase(uvm_phase phase);
    fork
      forever begin
        bmreq.get(reqid);
//        `uvm_info("BM",$sformatf("req %d",reqid),UVM_LOW);
        bmresp.write(reqid);
        bmdone.get(doneid);
//        `uvm_info("BM_done",$sformatf("req_done %d",doneid),UVM_LOW)
        if(reqid != doneid) begin
          mjerr::err("internal","arb grant,done mismatch");
        end
      end
    join_none
  endtask : run_phase
  
endclass : bmarbitrator










/////////////////////////////////////////////////////////////////////////////
class write_drv extends uvm_driver;

    `uvm_component_utils(write_drv)
    
    virtual AHBIF if0;
    
    uvm_analysis_imp #(logic, write_drv) CheckInitDone_imp;
    
    integer fin,res, N;
    string sin;
    logic [31:0] addrx,datax;
    logic cmd, seq_write=0;
    logic pop_en=0;
    
    logic init_done, WaitForIt;

     
    logic [31:0] wdata_q[$];
    logic [31:0] wdata,waddr;

    //slave_si wi;
    
    function write(logic t);
        `uvm_info("CheckInitDone_imp", $sformatf("init_done: %b", t), UVM_DEBUG)
        init_done = t;
    endfunction : write
    
    function new(string name="write_drv", uvm_component parent = null);
        super.new(name, parent);
    endfunction : new
  
    function void build_phase(uvm_phase phase);
        CheckInitDone_imp = new("CheckInitDone_imp", this);
    endfunction : build_phase
    
    function void connect_phase(uvm_phase phase);
        if (!uvm_config_db #(virtual AHBIF)::get(null, "uvm_test_top", "AHBIF", this.if0)) begin
            mjerr::err("connect", "AHBIF not found");
        end 
    endfunction : connect_phase;

    task push_data;
        while( $fgets(sin,fin)) begin
            res=$sscanf(sin,"%h",datax);
            if(res != 32'd0) begin
                wdata_q.push_back(datax);
            end
        //$display("push_data = %h res = %d",datax,res);
        end
    endtask : push_data
    
      
    task pop_data;
        @(if0.cb);
            //$display("The size of wr data fifo = %0d seq_write= %d %t",N,seq_write,$time);
            if(wdata_q.size() == N && if0.init_done) begin
                //if0.mHADDR      <=  32'h0001_0200;
                //waddr           <=  32'h0001_0200;
                if0.mHADDR      <= #1 32'h0001_0200;
                waddr           <=  32'h0001_0200;
                if0.mHWRITE     <= #1 1'b1;
                if0.mHTRANS     <= #1 2'b10;
                seq_write       <=  1'b1;
            end
            
            if (seq_write == 1'b1 && wdata_q.size() != 0) begin
                //if (if0.mHRESP == 2'b00) begin
	         if(if0.mHREADY==1) begin
                    //write_out   <=  write_data.pop_front();
                    if0.mHADDR  <= #1 waddr + 4;
                    waddr       <=  waddr + 4;     
                    if0.mHWDATA <= #1 wdata_q.pop_front();
                    if0.mHTRANS <= #1 2'b11;
                    if0.mHWRITE <= #1 1'b1;
                end

                /*else begin
                    if0.mHADDR  <=  write_out.addr;
                    if0.mHWDATA <=  write_out.data;
                   */ 
            //`uvm_info("POP_DATA",$sformatf(" Addr: %4h, Data: %4h, HWRITE: %b size = %d",if0.mHADDR, if0.mHWDATA, if0.mHWRITE,wdata_q.size()), UVM_LOW);
            end 
            
            if (wdata_q.size() == 0)begin
            @(if0.cb);
                if0.mHTRANS <=  #1 2'b00;
                if0.mHWRITE <= #1 1'b0;
             // $display ("here \n");
            //    seq_write   <=  1'b0;
            end
    endtask : pop_data

    task wait_for_something();
        begin
        WaitForIt = 1'b0;
        while(WaitForIt != 1'b1) begin
            WaitForIt <= if0.init_done;
            `uvm_info("WaitForIt", "Waiting for init_done....", UVM_DEBUG)
            `uvm_info("WaitForIt", $sformatf("init_done: %b", WaitForIt), UVM_DEBUG)
            repeat (2) @(if0.cb);
        end 
    end 
  endtask : wait_for_something

    task run_phase(uvm_phase phase);
    
      //   string tstring1="wrt2_sort.txt";
         string tstring1="write_data.txt";
        //uvm_cmdline_processor cp=uvm_cmdline_processor::get_inst();
        begin
            //wi = slave_si::type_id::create("wi");
          //  cp.get_arg_value("+272test=",tstring1);
            `uvm_info("write_file",$sformatf(tstring1),UVM_LOW)
            fin=$fopen(tstring1,"r");
            if(fin == 0) begin
                $display("Could not open write.txt Simulation failed to start");
                $finish;
            end
            
            push_data;
            
            wait_for_something();

            N = wdata_q.size();
            
            while (wdata_q.size() != 0) begin 
                
                pop_data;
                `uvm_info("POP_DATA_WHILE_AFTER_POP",$sformatf(" Addr: %4h, Data: %4h, HWRITE: %b",if0.HADDR, if0.HWDATA, if0.HWRITE), UVM_DEBUG);
            end 
    
            
            //$display("wdata: %4h, waddr: %4h", wdata, waddr);
            /*
            while($fgets(wdata,waddr)) begin
                start_item(wi);
                wi.wdata <= wdata;
                wi.waddr <= waddr;
                finish_item(wi);
            end
            */
        end
        $fclose(fin);
    
    endtask : run_phase

endclass : write_drv 
//////////////////////////////////////////////////////////////////////////////////////////


// class agent1 template
class agent1 extends uvm_agent ;
  `uvm_component_utils(agent1)

   seqr1 sqr1 ;
   inmon imon ;
   pfind pf ;
   bittime btime ;
   slavemon smon ;
   bm_mon bm;
   bmarbitrator bma;
   drv1 d1 ;
   expframe expf ;
   chkframe cframe ;
   ahbs ahbmemslave ;
   datamon dmon ;
   write_drv write_drv_h ; 

   function new(string name="agent1",uvm_component par=null);
     super.new(name,par);
   endfunction : new


//  The build phase is to create any components or other
//  elements required
   function void build_phase(uvm_phase phase);
     super.build_phase(phase);
      ahbmemslave = ahbs::type_id::create("ahbmemslave",this);
      dmon = datamon::type_id::create("dmon",this);
     //bm = bm_mon::type_id::create("bm_mon",this);
     // bma = bmarbitrator::type_id::create("bmarb",this);
      expf = expframe::type_id::create("expf",this);
      cframe = chkframe::type_id::create("cframe",this);
      pf = pfind::type_id::create("pf",this);
      btime = bittime::type_id::create("btime",this);
      smon = slavemon::type_id::create("smon",this);
      d1 = drv1::type_id::create("d1",this);
      sqr1 = seqr1::type_id::create("sqr1",this);
      imon = inmon::type_id::create("imon",this);
      write_drv_h = write_drv::type_id::create("write_drv_h", this);
      //file0.bm = bm;
   endfunction : build_phase


//  The connect phase is to bind messages and interfaces
   function void connect_phase(uvm_phase phase);
      pf.startbit.connect(cframe.startbit);
      d1.set_mem.connect(smon.set_mem);
      d1.expstart.connect(imon.expstart.analysis_export);
    //  d1.sreq.connect(bma.bmreq.analysis_export);
      dmon.dbit.connect(pf.dbit.analysis_export);
      dmon.dbit.connect(btime.dbit.analysis_export);
      
   //  bm.sreq.connect(bma.bmreq.analysis_export);
    //  bm.sdone.connect(bma.bmdone.analysis_export);
     //d1.sdone.connect(bma.bmdone.analysis_export);
     //bma.bmresp.connect(d1.sresp.analysis_export);
      //bma.bmresp.connect(bm.sresp.analysis_export);
      cframe.drivedin.connect(dmon.drivedin);
      imon.regvals.connect(expf.regvals);
      imon.regvals.connect(pf.regvals);
      imon.regvals.connect(btime.regvals);
      expf.expFrame.connect(cframe.expFrame);
      pf.rbit.connect(cframe.rbit.analysis_export);
      d1.expwrite.connect(smon.expwrite.analysis_export);
      d1.seq_item_port.connect(sqr1.seq_item_export);
      d1.CheckInitDone.connect(write_drv_h.CheckInitDone_imp); 
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

  Si r,w, si;
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

   
   //////////////////////////////////////////////////////////
   task doreset();
    begin
	 
      //add
      repeat(1) begin
        start_item(si);
        finish_item(si);
      end
      
        start_item(si);
        si.init_reset();
        si.action=Si::InitializeDDR;
        finish_item(si);
        
        repeat(1) begin
        start_item(si);
        finish_item(si);
        end 
        
        start_item(si);
        //si.init_reset();
        si.action=Si::WriteToDDR3;
        finish_item(si);
        
        repeat(1) begin
        start_item(si);
        finish_item(si);
        end
        
      //end
      
    end
  endtask : doreset 
  ///////////////////////////////////////////////////////////////////////////////////
  
  
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
  repeat(1) begin
    start_item(r);
    r.do_reset=0;
    r.randomize() with { quantaDiv==4; propQuanta==3;
        seg1Quanta<=6; seg1Quanta>0;
      datalen < 9; datalen>0; format==0;
      };
      r.frameType=cantidef::XMITdataframe;
    finish_item(r);
  end
  repeat(1) begin
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
  repeat(1) begin
    start_item(r);
    r.do_reset=0;
    r.randomize() with { quantaDiv==4; propQuanta==3;
        seg1Quanta<=6; seg1Quanta>0;
      datalen < 9; datalen>0; format==1;
      };
      r.frameType=cantidef::XMITdataframe;
    finish_item(r);
  end
  repeat(1) begin
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
   bm_mon bm;

   function new(string name="t1",uvm_component par=null);
     super.new(name,par);
   endfunction : new


//  The build phase is to create any components or other
//  elements required
   function void build_phase(uvm_phase phase);
     super.build_phase(phase);
      e1 = env1::type_id::create("e1",this);
      s1 = seq1::type_id::create("s1",this);
      //bm = bm_mon::type_id::create("bm_mon",this);
      //s1.bm=bm;
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
