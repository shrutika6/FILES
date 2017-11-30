
interface AHBIF;

    logic mHBUSREQ,mHGRANT,HREADY,mHREADY;
    logic [1:0] HRESP,mHRESP;
    logic HRESET;
    logic HCLK;
    logic [31:0] HRDATA,mHRDATA;
    logic [31:0] HWDATA,mHWDATA;
    logic HLOCK;        // Not used
    logic [1:0] HTRANS,mHTRANS;
    logic [31:0] HADDR,mHADDR;
    logic HWRITE,mHWRITE;
    logic [2:0] HSIZE,mHSIZE;
    logic [2:0] HBURST,mHBURST;
    logic [3:0] HPROT;  // Not used
    logic HSEL;         // slave select
    logic [3:0] HMASTER; // Not used
    logic HMASTLOCK;    // not used
    logic init_done; // for ddr3 initialization
    logic write_done; // indicates write done
     
    clocking cb @(posedge(HCLK));
       
    endclocking : cb

    modport AHBM( input mHGRANT, output mHBUSREQ, 
        input mHREADY,input mHRESP,
        input mHRDATA,output mHTRANS, output mHADDR,
        output mHWRITE, output mHSIZE, output mHBURST, input init_done, output mHWDATA);
    
    modport AHBS( input HCLK, input HRESET, input HSEL, input HADDR,
        input HWRITE, input HTRANS,
        input HSIZE, input HBURST, input HWDATA, 
        output HREADY,
        output HRESP, output HRDATA, output init_done, output write_done);
        
    modport AHBMS(  input mHADDR,
        input mHWRITE, input mHTRANS,
        input mHSIZE, input mHBURST, input mHWDATA, 
        output mHREADY,
        output mHRESP, output mHRDATA, output init_done,output write_done);
        
    modport AHBCLKS( input HCLK, input HRESET);
    
        
endinterface : AHBIF


interface DDR3_sdram;

   wire      RESET;
   reg       ck; 
   reg       ck_n;
   wire      cke;
   wire      cs_n; 
   wire      ras_n; 
   wire      cas_n; 
   wire      we_n; 
   wire [DM_BITS-1:0]       dm; 
   wire [BA_BITS-1:0]       ba; 
   wire [ADDR_BITS-1:0]     a; 
   wire  [DQ_BITS-1:0]      dq0; 
   wire [DQS_BITS-1:0]      dqs;
   wire [DQS_BITS-1:0]      dqs_n;
   wire [DQS_BITS-1:0]      tdqs_n;
   wire      odt;
   
  // Modport used for Memory Initialization and Write
  modport ddr_wr(
    output RESET,
    output cke,
    output cs_n,
    output ras_n,
    output cas_n,
    output we_n,
    output dm, 
    output ba, 
    output a,
    inout dq0, 
    inout dqs,
    inout dqs_n,
    inout tdqs_n,
    output odt
   );

endinterface: DDR3_sdram 
