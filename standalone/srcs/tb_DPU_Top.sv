`timescale 1ns/1ps

module DPU_Top_tb;

parameter bitSize = 8;
parameter accSize = 20;
parameter arraySize = 8;

reg clock;
reg reset;
reg load_ready;

reg signed [bitSize-1:0] in_array [arraySize-1:0][arraySize-1:0];
reg signed [bitSize-1:0] w_array  [arraySize-1:0][arraySize-1:0];

reg [2:0] act_sel;

wire busy;
wire done;

wire signed [accSize-1:0] out_array [arraySize-1:0][arraySize-1:0];

DPU_Top #(
    .bitSize(bitSize),
    .accSize(accSize),
    .arraySize(arraySize)
) dut (
    .clock(clock),
    .reset(reset),
    .load_ready(load_ready),
    .in_array(in_array),
    .w_array(w_array),
    .act_sel(act_sel),
    .busy(busy),
    .done(done),
    .out_array(out_array)
);

//
// Clock
//
always #5 clock = ~clock;

integer i, j;

initial begin

    clock = 0;
    reset = 0;
    load_ready = 0;
    act_sel = 3'd0;

    // Clear matrices
    for(i = 0; i < arraySize; i = i + 1)
        for(j = 0; j < arraySize; j = j + 1) begin
            in_array[i][j] = 0;
            w_array[i][j]  = 0;
        end

    //
    // Example matrices
    //

    // Identity input
    for(i = 0; i < arraySize; i = i + 1)
        in_array[i][i] = 1;

    // Simple weights
    for(i = 0; i < arraySize; i = i + 1)
        for(j = 0; j < arraySize; j = j + 1)
            w_array[i][j] = 10*i + j;

    #20;
    reset = 1;

    #10;
    load_ready = 1;

    wait(done);

    $display("Output Matrix:");

    for(i = 0; i < arraySize; i = i + 1) begin
        for(j = 0; j < arraySize; j = j + 1)
            $write("%4d ", out_array[i][j]);
        $write("\n");
    end

    #20;
    $finish;

end

endmodule