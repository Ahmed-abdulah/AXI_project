module vedic_2x2 (
    input  [1:0] a,
    input  [1:0] b,
    output [3:0] product
);
    wire [3:0] partial;
    wire c1, c2;
    
  
    assign partial[0] = a[0] & b[0];
    assign partial[1] = a[1] & b[0];
    assign partial[2] = a[0] & b[1];
    assign partial[3] = a[1] & b[1];
    
    assign product[0] = partial[0];
    assign {c1, product[1]} = partial[1] + partial[2];
    assign {c2, product[2]} = partial[3] + c1;
    assign product[3] = c2;
endmodule
