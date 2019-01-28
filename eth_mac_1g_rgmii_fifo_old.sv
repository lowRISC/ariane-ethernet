/*

Copyright (c) 2015-2018 Alex Forencich

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

*/

// Language: Verilog 2001

/*
 * 1G Ethernet MAC with RGMII interface and TX and RX FIFOs
 */
module eth_mac_1g_rgmii_fifo #
(
    // target ("SIM", "GENERIC", "XILINX", "ALTERA")
    parameter TARGET = "GENERIC",
    // IODDR style ("IODDR", "IODDR2")
    // Use IODDR for Virtex-4, Virtex-5, Virtex-6, 7 Series, Ultrascale
    // Use IODDR2 for Spartan-6
    parameter IODDR_STYLE = "IODDR2",
    // Clock input style ("BUFG", "BUFR", "BUFIO", "BUFIO2")
    // Use BUFR for Virtex-5, Virtex-6, 7-series
    // Use BUFG for Ultrascale
    // Use BUFIO2 for Spartan-6
    parameter CLOCK_INPUT_STYLE = "BUFIO2",
    // Use 90 degree clock for RGMII transmit ("TRUE", "FALSE")
    parameter USE_CLK90 = "TRUE",
    parameter ENABLE_PADDING = 1,
    parameter MIN_FRAME_LENGTH = 64,
    parameter TX_FIFO_ADDR_WIDTH = 12,
    parameter TX_FRAME_FIFO = 1,
    parameter TX_DROP_BAD_FRAME = TX_FRAME_FIFO,
    parameter TX_DROP_WHEN_FULL = 0,
    parameter RX_FIFO_ADDR_WIDTH = 12,
    parameter RX_FRAME_FIFO = 1,
    parameter RX_DROP_BAD_FRAME = RX_FRAME_FIFO,
    parameter RX_DROP_WHEN_FULL = RX_FRAME_FIFO
)
(
    input wire        gtx_clk,
    input wire        gtx_clk90,
    input wire        gtx_rst,
    input wire        logic_clk,
    input wire        logic_rst,

    /*
     * AXI input
     */
    input wire [7:0]  tx_axis_tdata,
    input wire        tx_axis_tvalid,
    output wire       tx_axis_tready,
    input wire        tx_axis_tlast,
    input wire        tx_axis_tuser,

    /*
     * AXI output
     */
    output wire [7:0] rx_axis_tdata,
    output wire       rx_axis_tvalid,
    output wire       rx_axis_tlast,
    output wire       rx_axis_tuser,

    /*
     * RGMII interface
     */
    input wire        rgmii_rx_clk,
    input wire [3:0]  rgmii_rxd,
    input wire        rgmii_rx_ctl,
    output wire       rgmii_tx_clk,
    output wire [3:0] rgmii_txd,
    output wire       rgmii_tx_ctl,
    output wire       mac_gmii_tx_en,

    /*
     * Status
     */
    output wire       tx_fifo_overflow,
    output wire       tx_fifo_bad_frame,
    output wire       tx_fifo_good_frame,
    output wire       rx_error_bad_frame,
    output wire       rx_error_bad_fcs,
    output wire       rx_fifo_overflow,
    output wire       rx_fifo_bad_frame,
    output wire       rx_fifo_good_frame,
    output wire [1:0] speed,
    output wire [31:0] rx_fcs_reg,
    output wire [31:0] tx_fcs_reg,

    /*
     * Configuration
     */
    input wire [7:0]  ifg_delay
);

wire tx_clk;
wire rx_clk;
wire tx_rst;
wire rx_rst;

// synchronize MAC status signals into logic clock domain
wire rx_error_bad_frame_int;
wire rx_error_bad_fcs_int;

reg [1:0] rx_sync_reg_1;
reg [1:0] rx_sync_reg_2;
reg [1:0] rx_sync_reg_3;
reg [1:0] rx_sync_reg_4;

assign rx_error_bad_frame = rx_sync_reg_3[0] ^ rx_sync_reg_4[0];
assign rx_error_bad_fcs = rx_sync_reg_3[1] ^ rx_sync_reg_4[1];

always @(posedge rx_clk or posedge rx_rst) begin
    if (rx_rst) begin
        rx_sync_reg_1 <= 2'd0;
    end else begin
        rx_sync_reg_1 <= rx_sync_reg_1 ^ {rx_error_bad_frame_int, rx_error_bad_frame_int};
    end
end

always @(posedge logic_clk or posedge logic_rst) begin
    if (logic_rst) begin
        rx_sync_reg_2 <= 2'd0;
        rx_sync_reg_3 <= 2'd0;
        rx_sync_reg_4 <= 2'd0;
    end else begin
        rx_sync_reg_2 <= rx_sync_reg_1;
        rx_sync_reg_3 <= rx_sync_reg_2;
        rx_sync_reg_4 <= rx_sync_reg_3;
    end
end

wire [7:0] rx_axis_tdata_fifo;
wire       rx_axis_tvalid_fifo;
wire       rx_axis_tlast_fifo;
wire       rx_axis_tuser_fifo;

wire [1:0] speed_int;

reg [1:0] speed_sync_reg_1;
reg [1:0] speed_sync_reg_2;

assign speed = speed_sync_reg_2;

always @(posedge logic_clk) begin
    speed_sync_reg_1 <= speed_int;
    speed_sync_reg_2 <= speed_sync_reg_1;
end

eth_mac_1g_rgmii #(
    .TARGET(TARGET),
    .IODDR_STYLE(IODDR_STYLE),
    .CLOCK_INPUT_STYLE(CLOCK_INPUT_STYLE),
    .USE_CLK90(USE_CLK90),
    .ENABLE_PADDING(ENABLE_PADDING),
    .MIN_FRAME_LENGTH(MIN_FRAME_LENGTH)
)
eth_mac_1g_rgmii_inst (
    .gtx_clk(gtx_clk),
    .gtx_clk90(gtx_clk90),
    .gtx_rst(gtx_rst),
    .tx_clk(tx_clk),
    .tx_rst(tx_rst),
    .rx_clk(rx_clk),
    .rx_rst(rx_rst),
    .tx_axis_tdata(tx_axis_tdata),
    .tx_axis_tvalid(tx_axis_tvalid),
    .tx_axis_tready(tx_axis_tready),
    .tx_axis_tlast(tx_axis_tlast),
    .tx_axis_tuser(tx_axis_tuser),
    .rx_axis_tdata(rx_axis_tdata_fifo),
    .rx_axis_tvalid(rx_axis_tvalid_fifo),
    .rx_axis_tlast(rx_axis_tlast_fifo),
    .rx_axis_tuser(rx_axis_tuser_fifo),
    .rgmii_rx_clk(rgmii_rx_clk),
    .rgmii_rxd(rgmii_rxd),
    .rgmii_rx_ctl(rgmii_rx_ctl),
    .rgmii_tx_clk(rgmii_tx_clk),
    .rgmii_txd(rgmii_txd),
    .rgmii_tx_ctl(rgmii_tx_ctl),
    .mac_gmii_tx_en(mac_gmii_tx_en),
    .rx_error_bad_frame(rx_error_bad_frame_int),
    .rx_error_bad_fcs(rx_error_bad_fcs_int),
    .rx_fcs_reg(rx_fcs_reg),
    .tx_fcs_reg(tx_fcs_reg),
    .speed(speed_int),
    .ifg_delay(ifg_delay)
);

   logic         rx_empty, rx_almost_empty, rx_rd_en, rx_wr_en;
   logic         rx_tvalid_0, rx_tlast_0, rx_tuser_0;
   logic         rx_tvalid_1, rx_tlast_1, rx_tuser_1;
   
   logic [7:0]   rx_tdata_0, rx_tdata_1;
   
always @(posedge rx_clk or posedge rx_rst) begin
   if (rx_rst) begin
      rx_wr_en <= 1'b0;
   end else begin
      rx_tvalid_0 <= rx_axis_tvalid_fifo;
      rx_tlast_0 <= rx_axis_tlast_fifo;
      rx_tuser_0 <= rx_axis_tuser_fifo;
      rx_tdata_0 <= rx_axis_tdata_fifo;
      rx_tvalid_1 <= rx_tvalid_0;
      rx_tlast_1 <= rx_tlast_0;
      rx_tuser_1 <= rx_tuser_0;
      rx_tdata_1 <= rx_tdata_0;
      rx_wr_en <= rx_axis_tvalid_fifo ^ rx_tvalid_0;
   end
end
  
     FIFO18E1 #(
                .ALMOST_EMPTY_OFFSET(13'h5),       // Sets the almost empty threshold
                .ALMOST_FULL_OFFSET(13'h0080),     // Sets almost full threshold
                .DATA_WIDTH(36),                    // Sets data width to 4-36
                .DO_REG(1),                        // Enable output register (1-0) Must be 1 if EN_SYN = FALSE
                .EN_SYN("FALSE"),                  // Specifies FIFO as dual-clock (FALSE) or Synchronous (TRUE)
                .FIFO_MODE("FIFO18"),              // Sets mode to FIFO18 or FIFO18_36
                .FIRST_WORD_FALL_THROUGH("FALSE"), // Sets the FIFO FWFT to FALSE, TRUE
                .INIT(36'h000000000),              // Initial values on output port
                .SIM_DEVICE("7SERIES"),            // Must be set to "7SERIES" for simulation behavior
                .SRVAL(36'h000000000)              // Set/Reset value for output port
                )
      rx_fifo (
                        // Read Data: 32-bit (each) output: Read output data
                        .DO({rx_axis_tvalid,rx_axis_tlast,rx_axis_tuser,rx_axis_tdata}), // 32-bit output: Data output
                        // Status: 1-bit (each) output: Flags and other FIFO status outputs
                        .ALMOSTEMPTY(rx_almost_empty),// 1-bit output: Almost empty flag
                        .EMPTY(rx_empty),          // 1-bit output: Empty flag
                        // Read Control Signals: 1-bit (each) input: Read clock, enable and reset input signals
                        .RDCLK(logic_clk),         // 1-bit input: Read clock
                        .RDEN(rx_rd_en),           // 1-bit input: Read enable
                        .REGCE(1'b1),              // 1-bit input: Clock enable
                        .RST(rx_rst),              // 1-bit input: Asynchronous Reset
                        .RSTREG(1'b0),             // 1-bit input: Output register set/reset
                        // Write Control Signals: 1-bit (each) input: Write clock and enable input signals
                        .WRCLK(rx_clk),         // 1-bit input: Write clock
                        .WREN(rx_wr_en),           // 1-bit input: Write enable
                        // Write Data: 32-bit (each) input: Write input data
                        .DI({rx_tvalid_1,rx_tlast_1,rx_tuser_1,rx_tdata_1}),      
                        // 32-bit input: Data input
                        .DIP(4'b0)                 // 4-bit input: Parity input
                        );

always @(posedge logic_clk)
     if (logic_rst == 1'b0)
       begin
          rx_rd_en <= 1'b0;
       end
     else
       begin
          if (rx_empty)
              rx_rd_en <= 1'b0;
          else if (!rx_almost_empty)
              rx_rd_en <= 1'b1;
       end
   
endmodule
