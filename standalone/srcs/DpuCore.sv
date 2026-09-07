`timescale 1ns/10ps
module DPUCore#(
    parameter bitSize = 8,
    parameter accSize = 20,
    parameter arraySize = 8 // keep arraySize even
)
(
    input                           clock,
    input                           reset,
    input                              en,
    input                           clear,
    input signed [bitSize-1:0] in [arraySize-1:0],
    input signed [bitSize-1:0] w [arraySize-1:0],

    output signed [accSize-1:0] OUT_array [arraySize-1:0][arraySize-1:0]
);

MACArray #(.bitSize(bitSize), .accSize(accSize), .arraySize(arraySize)) core (
    .clock(clock),
    .reset(reset),
    .clear(clear),
    .en(en),
    .in(in[arraySize-1:0]),
    .w(w[arraySize-1:0]),
    .OUT_array(OUT_array)
);

endmodule