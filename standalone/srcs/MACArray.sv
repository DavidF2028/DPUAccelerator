`timescale 1ns/10ps
module MACArray#(
    parameter bitSize = 8,
    parameter accSize = 20,
    parameter arraySize = 8
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


wire signed [bitSize-1:0] in_wire [arraySize-1:0][arraySize:0];
wire signed [bitSize-1:0] w_wire  [arraySize:0][arraySize-1:0];

genvar i;
genvar j;

generate
    for (i = 0; i < arraySize; i = i + 1) begin // first runthrough inputs
        assign in_wire[i][0] = in[i];
    end

    for (j = 0; j < arraySize; j = j + 1) begin // first runthrough weights
        assign w_wire[0][j] = w[j];
    end
    
    for (i = 0; i < arraySize; i = i + 1) begin // generate each unit
        for(j = 0; j < arraySize; j = j + 1) begin
                MACUnit #(
                .bitSize(bitSize),
                .accSize(accSize)
            ) macUnit (
                .clock(clock),
                .reset(reset),
                .en(en),
                .clear(clear),
                .in(in_wire[i][j]),
                .w(w_wire[i][j]),
                .OUT(OUT_array[i][j]),
                .carryout_in(in_wire[i][j+1]),
                .carryout_w(w_wire[i+1][j])
            );
        end
    end
endgenerate

endmodule