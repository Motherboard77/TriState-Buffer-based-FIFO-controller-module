`timescale 1ns / 1ps
module memory_test();

reg clk_in,wr,rd,rst,status;
reg [3:0] data_in;

wire [3:0] data_out;
//wire empty,half,full,idle;

//memory(clk_in,wr,rd,data_in,status,rst,data_out,emp,full,half,idle);
//memory(clk_in,wr,rd,data_in,status,rst,out);
memory uut(clk_in,wr,rd,data_in,status,rst,data_out);

always
#4 clk_in <= ~clk_in;

initial 
begin
clk_in <= 1'b1;
wr <= 1'b0;
rd <= 1'b0;
rst <= 1'b0;
status <= 1'b1;
end

initial
begin
#10
wr <= 1'b1;
rd <= 1'b0;
rst <= 1'b0;
status <= 1'b1;
data_in <= 4'b1001;
#1500000000
wr <= 1'b1;
rd <= 1'b0;
rst <= 1'b0;
status <= 1'b0;
data_in <= 4'b1101;
#1000000000
wr <= 1'b1;
rd <= 1'b0;
rst <= 1'b0;
status <= 1'b0;
data_in <= 4'b0011;
#1000000000
wr <= 1'b0;
rd <= 1'b1;
rst <= 1'b0;
status <= 1'b0;
end

endmodule
