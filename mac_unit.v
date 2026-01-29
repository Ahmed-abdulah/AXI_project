module mac_unit #(
    parameter DATA_WIDTH = 8,
    parameter ACCUM_WIDTH = 32,
    parameter OUTPUT_WIDTH = 16,
    parameter USE_SQRT_CSLA = 1,
    parameter ENABLE_ACTIVATION = 1,
    parameter FRAC_BITS = 11
)(
    input  clk,
    input  rst_n,
    input  enable,
    input  clear_acc,
    input  [DATA_WIDTH-1:0] input_data,
    input  [DATA_WIDTH-1:0] weight,
    output [OUTPUT_WIDTH-1:0] mac_out,
    output [OUTPUT_WIDTH-1:0] activated_out,
    output valid,
    output overflow
);
    localparam MULT_WIDTH = 2 * DATA_WIDTH;
    
    wire [MULT_WIDTH-1:0] mult_result;
    reg [ACCUM_WIDTH-1:0] accumulator;
    reg [ACCUM_WIDTH-1:0] next_acc;
    wire [ACCUM_WIDTH:0] acc_sum;
    reg overflow_reg;
    reg valid_reg;
    
    vedic_mult #(
        .WIDTH(DATA_WIDTH)
    ) multiplier (
        .a(input_data),
        .b(weight),
        .product(mult_result)
    );
    
    assign acc_sum = {1'b0, accumulator} + {{(ACCUM_WIDTH-MULT_WIDTH+1){1'b0}}, mult_result};
    
    always @(*) begin
        if (enable) begin
            if (clear_acc) begin
                next_acc = {{(ACCUM_WIDTH-MULT_WIDTH){1'b0}}, mult_result};
            end else begin
                next_acc = acc_sum[ACCUM_WIDTH-1:0];
            end
        end else if (clear_acc) begin
            next_acc = {ACCUM_WIDTH{1'b0}};
        end else begin
            next_acc = accumulator;
        end
    end
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            accumulator <= {ACCUM_WIDTH{1'b0}};
        else
            accumulator <= next_acc;
    end
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            overflow_reg <= 1'b0;
        else if (clear_acc)
            overflow_reg <= 1'b0;
        else if (enable && acc_sum[ACCUM_WIDTH])
            overflow_reg <= 1'b1;
    end
    
    assign overflow = overflow_reg;
    
    assign mac_out = accumulator[OUTPUT_WIDTH-1:0];
    
    generate
        if (ENABLE_ACTIVATION) begin : gen_activation
            sigmoid_activation #(
                .WIDTH(OUTPUT_WIDTH),
                .FRAC_BITS(FRAC_BITS)
            ) activation (
                .x(mac_out),
                .y(activated_out)
            );
        end else begin : no_activation
            assign activated_out = mac_out;
        end
    endgenerate
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            valid_reg <= 1'b0;
        else
            valid_reg <= enable;
    end
    
    assign valid = valid_reg;
    
endmodule