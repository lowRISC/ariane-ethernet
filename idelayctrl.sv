
module idelayctrl #(
  parameter SIM_DEVICE = "7SERIES"
)(
  output logic RDY,
  input wire REFCLK,
  input wire RST
);

`ifdef verilator
   // This is a placeholder
   always @(posedge REFCLK or posedge RST)
     begin
	if (RST == 1'b1)
	  begin
	     RDY <= 1'b0;
	  end
	else
	  begin
	     RDY <= 1'b1;
	  end
     end
`else
   
IDELAYCTRL ctrl(.RDY, .REFCLK, .RST);
	
`endif
   
endmodule
