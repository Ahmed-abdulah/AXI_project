module mac_array #(
    parameter NUM_CHANNELS = 4,
    parameter DATA_WIDTH = 8,
    parameter ACCUM_WIDTH = 32,
    parameter OUTPUT_WIDTH = 16
)(
    input  clk,
    input  rst_n,
    input  [NUM_CHANNELS-1:0] enable,
    input  [NUM_CHANNELS-1:0] clear_acc,
    input  [DATA_WIDTH*NUM_CHANNELS-1:0] input_data,
    input  [DATA_WIDTH*NUM_CHANNELS-1:0] weight,
    output [OUTPUT_WIDTH*NUM_CHANNELS-1:0] mac_out,
    output [OUTPUT_WIDTH*NUM_CHANNELS-1:0] activated_out,
    output [NUM_CHANNELS-1:0] valid,
    output [NUM_CHANNELS-1:0] overflow
);
    genvar i;
    generate
        for (i = 0; i < NUM_CHANNELS; i = i + 1) begin : mac_channels
            mac_unit #(
                .DATA_WIDTH(DATA_WIDTH),
                .ACCUM_WIDTH(ACCUM_WIDTH),
                .OUTPUT_WIDTH(OUTPUT_WIDTH)
            ) mac_inst (
                .clk(clk),
                .rst_n(rst_n),
                .enable(enable[i]),
                .clear_acc(clear_acc[i]),
                .input_data(input_data[DATA_WIDTH*(i+1)-1:DATA_WIDTH*i]),
                .weight(weight[DATA_WIDTH*(i+1)-1:DATA_WIDTH*i]),
                .mac_out(mac_out[OUTPUT_WIDTH*(i+1)-1:OUTPUT_WIDTH*i]),
                .activated_out(activated_out[OUTPUT_WIDTH*(i+1)-1:OUTPUT_WIDTH*i]),
                .valid(valid[i]),
                .overflow(overflow[i])
            );
        end
    endgenerate
endmodule