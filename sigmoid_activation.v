module sigmoid_activation #(
    parameter WIDTH = 16,
    parameter FRAC_BITS = 11
)(
    input  signed [WIDTH-1:0] x,
    output [WIDTH-1:0] y
);
    localparam signed [WIDTH-1:0] NEG_THRESHOLD = -(4 << FRAC_BITS);
    localparam signed [WIDTH-1:0] POS_THRESHOLD = (4 << FRAC_BITS);
    localparam [WIDTH-1:0] ZERO_VAL = {WIDTH{1'b0}};
    localparam [WIDTH-1:0] HALF_VAL = (1 << (WIDTH-1));
    localparam [WIDTH-1:0] ONE_VAL  = {WIDTH{1'b1}};
    
    reg [WIDTH-1:0] y_reg;
    
    always @(*) begin
        if ($signed(x) < NEG_THRESHOLD)
            y_reg = ZERO_VAL;
        else if ($signed(x) > POS_THRESHOLD)
            y_reg = ONE_VAL;
        else
            y_reg = HALF_VAL + {{3{x[WIDTH-1]}}, x[WIDTH-1:3]};
    end
    
    assign y = y_reg;
endmodule