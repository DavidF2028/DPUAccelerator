`timescale 1ns/10ps
module DPU_Top #(
    parameter int bitSize   = 8,
    parameter int accSize   = 20,
    parameter int arraySize = 8
)(
    input clock,
    input reset,

    input                       load_ready,
    input signed [bitSize-1:0] in_array [arraySize-1:0][arraySize-1:0],
    input signed [bitSize-1:0] w_array [arraySize-1:0][arraySize-1:0],

    input [2:0] act_sel,
    output logic busy, 
    output logic done,

    output logic signed [accSize-1:0] out_array [arraySize-1:0][arraySize-1:0] 
);

localparam int DRAIN_CYCLES = arraySize;
localparam int TOTAL_CYCLES = 3 * arraySize - 2;
localparam int INDEX_WIDTH = $clog2(TOTAL_CYCLES + 1);

logic core_en;
logic core_clear;
logic coreCompute_done;
logic [INDEX_WIDTH-1:0] current_index;


logic signed [bitSize-1:0] current_in [arraySize-1:0];
logic signed [bitSize-1:0] current_w [arraySize-1:0];
logic signed [accSize-1:0] compute_out [arraySize-1:0][arraySize-1:0]; // in between Out array

assign core_clear = ~load_ready;
assign core_en = load_ready && (~coreCompute_done);
assign busy = load_ready && ~done;

DPUCore #(.bitSize(bitSize), .accSize(accSize), .arraySize(arraySize)) core_TL (
    .clock(clock),
    .reset(reset),
    .clear(core_clear),
    .en(core_en),
    .in(current_in),
    .w(current_w),
    .OUT_array(compute_out)
);


integer i;

always_ff @(posedge clock or negedge reset) begin
    if (!reset || !load_ready) begin
        current_index    <= '0;
        coreCompute_done <= 1'b0;

        for (i = 0; i < arraySize; i = i + 1) begin
            current_in[i] <= '0;
            current_w[i]  <= '0;
        end
    end
    else if (current_index < TOTAL_CYCLES) begin 
        for (i = 0; i < arraySize; i = i + 1) begin
            if ((current_index - i < arraySize) && (current_index >= i)) begin
            current_in[i] <= in_array[i][current_index - i];
            current_w[i]  <= w_array[current_index - i][i];
            end
            else begin
                current_in[i] <= '0;
                current_w[i]  <= '0;
            end
        end
        current_index    <= current_index + 1'b1;
        coreCompute_done <= 1'b0;
    end 
    else begin 
        for (i = 0; i < arraySize; i = i + 1) begin
            current_in[i] <= '0;
            current_w[i]  <= '0;
        end

        coreCompute_done <= 1'b1;
    end 
end


ActivationSelect #(.accSize(accSize), .arraySize(arraySize)) activation_unit(
    .clock(clock),
    .reset(reset),
    .in_en(coreCompute_done),
    .sel(act_sel),
    .IN_array(compute_out),
    .out_en(done),
    .OUT_array(out_array)
);

// FSM Logic
// States:
// Idle
// Compute
// Activation
// Ready



endmodule