// A very simple top level for the can transmitter
//
`timescale 1ns/10ps
`include "4096Mb_ddr3_parameters.vh"

`include "cant_idef.svh"

import cantidef::*;

`include "cant_intf.svh"
`include "AHBIF.svh"

`include "CAN_veri_1.svh"

`include "canxmit.sv"

`include "ahb.sv"

`include "cant2ddr.sv"
module top();

import uvm_pkg::*;
import cant::*;

logic [63:0] tck_ddr =  938;
logic [63:0] tck_ahb = 10000;
cantintf ci();
AHBIF ai();
AHBIF if0();
DDR3_sdram D1();
DDR3_sdram D2();
/*
initial begin

forever # ci.clk=~ci.clk;
forever #(tck_ahb/2) ai.HCLK <= ~ai.HCLK;
end
*/
initial begin
  ci.clk=1;
  ai.HCLK=1;
  repeat(2000000) begin

  #(tck_ddr/2)  #5 ci.clk=~ci.clk;
     #(tck_ahb/2) ai.HCLK=~ai.HCLK;
  end
  $display("Used up the clocks");
  $finish;
end

initial begin
D1.ck=1;
forever #(tck_ddr/2) D1.ck <= ~D1.ck;
end 

initial begin
D2.ck=1;
forever #(tck_ddr/2) D2.ck <= ~D2.ck;
end 

initial begin
  ci.rst=0;
  ai.HRESET=0;
  //if0.HRESET=0;
end

initial
  begin
    ai.mHGRANT=0;
    if0.mHGRANT=0;
  end

initial begin
    #0;
    uvm_config_db #(virtual cantintf)::set(null, "*", "cantintf" , ci);
    uvm_config_db #(virtual AHBIF)::set(null,"*", "AHBIF",ai);
  //  uvm_config_db #(virtual AHBIF)::set(null,"*", "AHBIF",if0);
    run_test("t1");
    $display("Test came back to me");
    #100;
    $finish;


end

initial begin
//  $vcdpluson;
 //$vcdplusmemon;
  $dumpfile("ahb.vpd");
  $dumpvars(9,top);
end


canxmit c(ci.xmit);
ahb a(ai.AHBM,ai.AHBS,ci.tox);

cant2ddr TOP (  ai.AHBCLKS, 
                    ai.AHBM, 
                    ai.AHBS,
                    ai.AHBMS,
                       D1,
                        D2
                );



endmodule : top
