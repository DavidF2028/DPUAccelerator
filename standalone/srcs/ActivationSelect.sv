`timescale 1ns/10ps
module ActivationSelect#(
    parameter accSize = 20,
    parameter arraySize = 8 // keep arraySize even
)
(
    input                                                    clock,
    input                                                    reset,
    input                                                    in_en,
    input  [2:0]                                               sel, // select activation module
    input signed [accSize-1:0] IN_array [arraySize-1:0][arraySize-1:0],

    output wire out_en,
    output logic signed [accSize-1:0] OUT_array [arraySize-1:0][arraySize-1:0]
);

genvar i, j;

assign out_en = in_en;

generate
    for (i = 0; i < arraySize; i = i + 1) begin : ROW
        for (j = 0; j < arraySize; j = j + 1) begin : COL
            always_comb begin
                case (sel)
                    3'd0: OUT_array[i][j] = IN_array[i][j]; // none
                    3'd1: begin // ReLU
                            if (IN_array[i][j] < 0)
                                OUT_array[i][j] = 0;
                            else
                                OUT_array[i][j] = IN_array[i][j];
                        end
                    3'd2: begin // Leaky ReLU (2^-6 = alpha)
                            if (IN_array[i][j] < 0)
                                OUT_array[i][j] = (IN_array[i][j] >>> 6);
                            else
                                OUT_array[i][j] = IN_array[i][j];
                        end
                    default: OUT_array[i][j] = IN_array[i][j];
                endcase
            end
        end
    end
endgenerate

endmodule