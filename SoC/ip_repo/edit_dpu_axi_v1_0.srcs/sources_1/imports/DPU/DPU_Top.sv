`timescale 1ns/10ps
module DPU_Top #(
    parameter int bitSize   = 8,
    parameter int accSize   = 20,
    parameter int arraySize = 8,
    parameter int ADDR_WIDTH = 8
)(
    input clock,
    input reset,

    input                       load_ready,

    input [2:0] act_sel,
    output logic busy, 
    output logic done,

    output logic                  in_bram_en,
    output logic [ADDR_WIDTH-1:0] in_bram_addr,
    input  logic [bitSize*arraySize-1:0] in_bram_dout,

    // Weight BRAM Port B
    output logic                  w_bram_en,
    output logic [ADDR_WIDTH-1:0] w_bram_addr,
    input  logic [bitSize*arraySize-1:0] w_bram_dout,

    // Output BRAM Port B
    output logic                  out_bram_en,
    output logic [3:0]            out_bram_we,
    output logic [ADDR_WIDTH-1:0] out_bram_addr,
    output logic [31:0]           out_bram_din 
);

localparam int DRAIN_CYCLES = arraySize;
localparam int TOTAL_CYCLES = 3 * arraySize - 2;
localparam int OUTPUT_COUNT = arraySize * arraySize;
localparam int OUTPUT_WIDTH = (OUTPUT_COUNT <= 1) ? 1 : $clog2(OUTPUT_COUNT);
localparam int ROW_COL_WIDTH = (arraySize <= 1) ? 1 : $clog2(arraySize);
localparam int INDEX_WIDTH = (TOTAL_CYCLES <= 1) ? 1 : $clog2(TOTAL_CYCLES + 1);

logic [OUTPUT_WIDTH-1:0] operation_count;
logic [ROW_COL_WIDTH-1:0] write_row;
logic [ROW_COL_WIDTH-1:0] write_col;

localparam logic [1:0] IDLE         = 2'd0;
localparam logic [1:0] COMPUTE      = 2'd1;
localparam logic [1:0] WRITE_OUTPUT = 2'd2;
localparam logic [1:0] READY        = 2'd3;

logic [1:0] state;
logic [1:0] next_state;


logic core_en; // wire driven
logic core_clear;
logic coreCompute_done;
logic [INDEX_WIDTH-1:0] current_index;


logic signed [bitSize-1:0] in_vector [0:arraySize-1];
logic signed [bitSize-1:0] w_vector  [0:arraySize-1];

genvar g;
generate
    for (g = 0; g < arraySize; g = g + 1) begin : GEN_UNPACK
        assign in_vector[g] =
            in_bram_dout[g*bitSize +: bitSize];

        assign w_vector[g] =
            w_bram_dout[g*bitSize +: bitSize];
    end
    
endgenerate



logic signed [accSize-1:0] compute_out [0:arraySize-1][0:arraySize-1];
logic signed [accSize-1:0] activated_out [0:arraySize-1][0:arraySize-1];



DPUCore #(.bitSize(bitSize), .accSize(accSize), .arraySize(arraySize)) core_TL (
    .clock(clock),
    .reset(reset),
    .clear(core_clear),
    .en(core_en),
    .in(in_vector),
    .w(w_vector),
    .OUT_array(compute_out)
);

logic [INDEX_WIDTH-1:0] feed_count;
logic activation_valid;


logic read_request;
logic read_request_d1;
logic bram_data_valid;

assign busy = (state == COMPUTE) || (state == WRITE_OUTPUT);
assign done = (state == READY);
assign core_clear = (state == IDLE) && load_ready;
assign core_en = bram_data_valid && (state == COMPUTE);

always_ff @(posedge clock or negedge reset) begin
    if (!reset) begin
        operation_count   <= '0;
        coreCompute_done  <= 1'b0;
        current_index     <= '0;

        read_request_d1   <= 1'b0;
        bram_data_valid   <= 1'b0;

        feed_count        <= '0;
        state             <= IDLE;
    end
    else begin
        state <= next_state;

        if (state == IDLE) begin
            read_request_d1 <= 1'b0;
            bram_data_valid <= 1'b0;
        end
        else begin
            read_request_d1 <= read_request;
            bram_data_valid <= read_request_d1;
        end

        case (state)

            IDLE: begin
                current_index    <= '0;
                feed_count       <= '0;
                operation_count  <= '0;
                coreCompute_done <= 1'b0;
            end

            COMPUTE: begin

                if (read_request)
                    current_index <= current_index + 1'b1;

                if (core_en) begin

                    if (feed_count == TOTAL_CYCLES - 1) begin
                        coreCompute_done <= 1'b1;
                        operation_count  <= '0;
                    end
                    else begin
                        feed_count <= feed_count + 1'b1;
                    end

                end
            end

            WRITE_OUTPUT: begin
                if (operation_count < OUTPUT_COUNT - 1)
                    operation_count <= operation_count + 1'b1;
            end

            READY: begin
            end

        endcase
    end
end

always_comb begin
    next_state = state;

    read_request = 1'b0;

    in_bram_en   = 1'b0;
    in_bram_addr = '0;

    w_bram_en   = 1'b0;
    w_bram_addr = '0;

    out_bram_en   = 1'b0;
    out_bram_we   = 4'b0000;
    out_bram_addr = '0;
    out_bram_din  = '0;

    write_row = operation_count / arraySize;
    write_col = operation_count % arraySize;

    case (state)
        IDLE: begin
            if (load_ready)
                next_state = COMPUTE;
        end

        COMPUTE: begin
            if (current_index < TOTAL_CYCLES) begin
                read_request = 1'b1;

                in_bram_en   = 1'b1;
                in_bram_addr = ADDR_WIDTH'(current_index);

                w_bram_en   = 1'b1;
                w_bram_addr = ADDR_WIDTH'(current_index);
            end

            if (coreCompute_done && activation_valid)
                next_state = WRITE_OUTPUT;
        end

        WRITE_OUTPUT: begin
            out_bram_en   = 1'b1;
            out_bram_we   = 4'b1111;
            out_bram_addr = ADDR_WIDTH'(operation_count);

            out_bram_din = {
                {(32-accSize){
                    activated_out[write_row][write_col][accSize-1]
                }},
                activated_out[write_row][write_col]
            };

            if (operation_count == OUTPUT_COUNT - 1)
                next_state = READY;
        end

        READY: begin
            if (!load_ready)
                next_state = IDLE;
        end

        default: begin
            next_state = IDLE;
        end
    endcase
end

ActivationSelect #(.accSize(accSize), .arraySize(arraySize)) activation_unit(
    .clock(clock),
    .reset(reset),
    .in_en(coreCompute_done),
    .sel(act_sel),
    .IN_array(compute_out),
    .out_en(activation_valid),
    .OUT_array(activated_out)
);

// FSM Logic
// States:
// Idle
// Compute
// Activation
// Ready



endmodule