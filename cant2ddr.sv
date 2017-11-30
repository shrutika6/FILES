
module cant2ddr  (  AHBIF.AHBCLKS   C, 
                    AHBIF.AHBM      M, 
                    AHBIF.AHBS      S1,
                    AHBIF.AHBMS     S2,
                    DDR3_sdram      D1,
                    DDR3_sdram      D2
                );
                
DDR3_top DDR(       C.HCLK, 
                    C.HRESET, 
                    S2, 
                    D1, 
                    D2
                );
                
endmodule

//`include "4096Mb_ddr3_parameters.vh"
//`include "ahbif.svh"
//`include "canxmit.sv"

// DDR3 Files
//

`include "fifo_async.sv" 
`include "sync.sv" 
`include "initialization.sv" 
`include "ctrl_operation.sv" 
`include "ddr3.v" 
`include "DDR3_top.sv"
