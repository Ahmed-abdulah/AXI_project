module vedic_mult #(
    parameter WIDTH = 8
)(
    input  [WIDTH-1:0] a,
    input  [WIDTH-1:0] b,
    output [2*WIDTH-1:0] product
);
    generate
        if (WIDTH == 2) begin : base_case
            vedic_2x2 v2x2 (
                .a(a),
                .b(b),
                .product(product)
            );
        end else begin : recursive_case
            localparam HALF_WIDTH = WIDTH / 2;
            
            wire [WIDTH-1:0] q0, q1, q2, q3;
            wire [2*WIDTH-1:0] aligned_q0, aligned_q1, aligned_q2, aligned_q3;
            wire [2*WIDTH-1:0] temp1, temp2;
            
            vedic_mult #(HALF_WIDTH) m0 (
                .a(a[HALF_WIDTH-1:0]),
                .b(b[HALF_WIDTH-1:0]),
                .product(q0)
            );
            
            vedic_mult #(HALF_WIDTH) m1 (
                .a(a[WIDTH-1:HALF_WIDTH]),
                .b(b[HALF_WIDTH-1:0]),
                .product(q1)
            );
            
            vedic_mult #(HALF_WIDTH) m2 (
                .a(a[HALF_WIDTH-1:0]),
                .b(b[WIDTH-1:HALF_WIDTH]),
                .product(q2)
            );
            
            vedic_mult #(HALF_WIDTH) m3 (
                .a(a[WIDTH-1:HALF_WIDTH]),
                .b(b[WIDTH-1:HALF_WIDTH]),
                .product(q3)
            );
            
            assign aligned_q0 = {{WIDTH{1'b0}}, q0};
            assign aligned_q1 = {{HALF_WIDTH{1'b0}}, q1, {HALF_WIDTH{1'b0}}};
            assign aligned_q2 = {{HALF_WIDTH{1'b0}}, q2, {HALF_WIDTH{1'b0}}};
            assign aligned_q3 = {q3, {WIDTH{1'b0}}};
            
            assign temp1 = aligned_q0 + aligned_q1;
            assign temp2 = temp1 + aligned_q2;
            assign product = temp2 + aligned_q3;
        end
    endgenerate
endmodule