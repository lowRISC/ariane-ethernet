`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04.02.2018 14:12:22
// Design Name: 
// Module Name: infer_ram
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

// See LICENSE for license details.

module infer_dpram #(RAM_SIZE=16, BYTE_WIDTH=8) // RAM_SIZE is in words
(
input ram_clk_a, ram_en_a,
input [BYTE_WIDTH-1:0] ram_we_a,
input [RAM_SIZE-1:0] ram_addr_a,
input [BYTE_WIDTH*8-1:0] ram_wrdata_a,
output [BYTE_WIDTH*8-1:0] ram_rddata_a,
input ram_clk_b, ram_en_b,
input [BYTE_WIDTH-1:0] ram_we_b,
input [RAM_SIZE-1:0] ram_addr_b,
input [BYTE_WIDTH*8-1:0] ram_wrdata_b,
output [BYTE_WIDTH*8-1:0] ram_rddata_b);

   localparam RAM_LINE          = 2 ** RAM_SIZE;   

   reg [BYTE_WIDTH*8-1:0] ram [0 : RAM_LINE-1];
   reg [RAM_SIZE-1:0]    ram_addr_delay_a;
   reg [RAM_SIZE-1:0]    ram_addr_delay_b;
   
   always @(posedge ram_clk_a)
    begin
     if(ram_en_a) begin
        ram_addr_delay_a <= ram_addr_a;
        foreach (ram_we_a[i])
          if(ram_we_a[i])
            begin
               ram[ram_addr_a][i*8 +:8] <= ram_wrdata_a[i*8 +: 8];
            end
     end
    end

   assign ram_rddata_a = ram[ram_addr_delay_a];
   
   always @(posedge ram_clk_b)
    begin
     if(ram_en_b) begin
        ram_addr_delay_b <= ram_addr_b;
        foreach (ram_we_b[i])
          if(ram_we_b[i])
            begin
               ram[ram_addr_b][i*8 +:8] <= ram_wrdata_b[i*8 +: 8];
            end
     end
    end

   assign ram_rddata_b = ram[ram_addr_delay_b];
   
endmodule
