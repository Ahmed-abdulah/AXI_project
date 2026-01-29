module bec #(
    parameter WIDTH = 4
)(
    input  [WIDTH-1:0] in,
    output [WIDTH-1:0] out
);
    assign out = in + 1'b1;
endmodule