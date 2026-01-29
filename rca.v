module rca #(
    parameter WIDTH = 4
)(
    input  [WIDTH-1:0] a,
    input  [WIDTH-1:0] b,
    input  cin,
    output [WIDTH-1:0] sum,
    output cout
);
    assign {cout, sum} = a + b + cin;
endmodule