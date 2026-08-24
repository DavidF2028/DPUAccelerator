`timescale 1ns/10ps
module MACUnit#(
    parameter bitSize = 8,
    parameter accSize = 20
)
(
    input                  clock,
    input                  reset,
    input                     en,
    input                   clear,
    input signed [bitSize-1:0]          in,
    input signed [bitSize-1:0]           w,


    output reg signed [accSize-1:0] OUT,
    output reg signed [bitSize-1:0] carryout_in,
    output reg signed [bitSize-1:0] carryout_w
);
always @(negedge reset or posedge clock) begin 
    if(~reset) begin
        OUT <= 0;
        carryout_in <= 0;
        carryout_w <= 0;
    end
    else if (clear) begin
        OUT     <= '0;
        carryout_in <= '0;
        carryout_w  <= '0;
    end
    else if (en) begin
        OUT <= OUT + in * w;
        carryout_in <= in;
        carryout_w <= w;
    end
end 
endmodule