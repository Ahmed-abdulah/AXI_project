module sqrt_csla #(
    parameter WIDTH = 16
)(
    input  [WIDTH-1:0] a,
    input  [WIDTH-1:0] b,
    input  cin,
    output [WIDTH-1:0] sum,
    output cout
);
    generate
        if (WIDTH <= 4) begin : small_adder
            assign {cout, sum} = a + b + cin;
        end else if (WIDTH == 16) begin : sqrt_16bit
      
            wire c1, c2, c3, c4;
            wire [1:0] s0, s4;
            wire [2:0] s1, s1_0, bec1_out;
            wire [3:0] s2, s2_0, bec2_out;
            wire [4:0] s3, s3_0, bec3_out;
            wire cout_dummy1, cout_dummy2, cout_dummy3;
            
            rca #(2) g0 (.a(a[1:0]), .b(b[1:0]), .cin(cin), .sum(s0), .cout(c1));
            
            // Group 1: 3-bit with BEC
            rca #(3) g1_0 (.a(a[4:2]), .b(b[4:2]), .cin(1'b0), .sum(s1_0), .cout(cout_dummy1));
            bec #(3) bec1 (.in(s1_0), .out(bec1_out));
            assign s1 = c1 ? bec1_out : s1_0;
            assign c2 = c1 ? (&s1_0) : 1'b0;
            
            // Group 2: 4-bit with BEC
            rca #(4) g2_0 (.a(a[8:5]), .b(b[8:5]), .cin(1'b0), .sum(s2_0), .cout(cout_dummy2));
            bec #(4) bec2 (.in(s2_0), .out(bec2_out));
            assign s2 = c2 ? bec2_out : s2_0;
            assign c3 = c2 ? (&s2_0) : 1'b0;
            
            // Group 3: 5-bit with BEC
            rca #(5) g3_0 (.a(a[13:9]), .b(b[13:9]), .cin(1'b0), .sum(s3_0), .cout(cout_dummy3));
            bec #(5) bec3 (.in(s3_0), .out(bec3_out));
            assign s3 = c3 ? bec3_out : s3_0;
            assign c4 = c3 ? (&s3_0) : 1'b0;
            
            // Group 4: 2-bit RCA
            rca #(2) g4 (.a(a[15:14]), .b(b[15:14]), .cin(c4), .sum(s4), .cout(cout));
            
            assign sum = {s4, s3, s2, s1, s0};
        end else begin : general_adder
            // General case for other widths
            assign {cout, sum} = a + b + cin;
        end
    endgenerate
endmodule