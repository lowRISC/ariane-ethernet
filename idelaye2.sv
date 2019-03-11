module idelaye2 (output [4:0] CNTVALUEOUT,
		 output DATAOUT,
		 input C, 
		 input CE,
		 input CINVCTRL,
		 input [4:0] CNTVALUEIN,
		 input DATAIN,
		 input IDATAIN,
		 input INC,
		 input LD,
		 input LDPIPEEN,
		 input REGRST);

    parameter CINVCTRL_SEL = "FALSE";
    parameter DELAY_SRC = "IDATAIN";
    parameter HIGH_PERFORMANCE_MODE    = "FALSE";
    parameter IDELAY_TYPE  = "FIXED";
    parameter integer IDELAY_VALUE = 0;
    parameter [0:0] IS_C_INVERTED = 1'b0;
    parameter [0:0] IS_DATAIN_INVERTED = 1'b0;
    parameter [0:0] IS_IDATAIN_INVERTED = 1'b0;
    parameter PIPE_SEL = "FALSE";
    parameter real REFCLK_FREQUENCY = 200.0;
    parameter SIGNAL_PATTERN    = "DATA";

`ifndef verilator
   
IDELAYE2
 #(
    .IDELAY_VALUE(IDELAY_VALUE),
    .IDELAY_TYPE(IDELAY_TYPE)
) dly (
       .CNTVALUEOUT,
       .DATAOUT,
       .C,
       .CE,
       .CINVCTRL,
       .CNTVALUEIN,
       .DATAIN,
       .IDATAIN,
       .INC,
       .LD,
       .LDPIPEEN,
       .REGRST);

`else
   assign CNTVALUEOUT = CNTVALUEIN;
   assign DATAOUT = DATAIN;
`endif
   
endmodule // IDELAYE2

`endcelldefine
