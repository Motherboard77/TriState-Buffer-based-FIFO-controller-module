`timescale 1ns / 1ps

module control_block(clk1,write,read,wr_clk,rd_clk,wr_en,rd_en);
input clk1;
input write,read;
output wire wr_clk;
output wire rd_clk;
output wire wr_en,rd_en;
wire clk_out;    //1 Hz output
wire timer;
wire [1:0] CON;   //CONTROL BITS
wire [1:0] op;    //outputs of 2nd stage buffers

clock_div CLK1(clk1,clk_out,timer);

bufif1 BF1(CON[0],clk_out,write);
bufif1 BF2(CON[1],clk_out,read);

bufif1 BF3(op[0],CON[0],write);
bufif1 BF4(op[1],CON[1],read);

bufif1 BF5(wr_clk,clk_out,op[0]);
bufif1 BF6(rd_clk,clk_out,op[1]);
bufif1 BF7(wr_en,write,op[0]);
bufif1 BF8(rd_en,read,op[1]);

endmodule

module clock_div(clk_in,clk_out,timer);
input clk_in;
output reg clk_out;
output reg timer;         //1 bit timer to track 1 positive edge of 1Hz 
reg [26:0] count;   //for clock divider to 1 Hz

initial
begin
clk_out <= 1'b1;
count=27'b000000000000000000000000000;
timer <= 1'b0;
end

always @(posedge clk_in)
    begin
        if(count == 27'b01110111_00110101_10010100_000)  //0.5 ms
		begin
		  clk_out <= ~clk_out;                             //toggle at 0.5 s
		  timer <= 1'b1;                                   //set timer
		end
		else if(count == 27'b11101110_01101011_00101000_000)
		begin
		  clk_out <= ~clk_out;                             //toggle at 1 s
		  count <= 27'b00000000_00000000_00000000_000;     //reset count
		end
		else if(count <= 27'b00111011_10011010_11001010_000)  //31250000 
		begin
		  timer <= 1'b0;
		end
        else
		begin
		  count <= count + 1'b1;
		end
    end
endmodule

//module memory(clk_in,wr,rd,data_in,status,rst,data_out,emp,full,half,idle);
module memory(clk_in,wr,rd,data_in,status,rst,out);
input clk_in,wr,rd,rst;
input [3:0] data_in;  //4 bit data input
input status;         //at status=1, give output based on mem-pointer
//output reg [3:0] data_out;
reg [3:0] data_out;
//output reg emp,full,half,idle;
reg emp,full,half,idle;
output wire [3:0] out;

parameter mem_size = 31 ;
parameter DATA_WIDTH = 3 ;
reg [DATA_WIDTH:0] temp_mem[0:mem_size]; //32 memory locations with word size of 4 bit
//reg [5:0] read_pointer;                    //points to current filled in position, used for status check
//reg [5:0] write_pointer;                   //write pointer tells where to write the data, read pointer tells from where to extract the data

integer read_pointer;
integer write_pointer;

wire wr_clk,rd_clk,wr_en,rd_en;
integer i;

initial
begin
//read_pointer <= 6'b000_000;
//write_pointer <= 6'b000_000;
read_pointer = 0;
write_pointer = 0;
end

control_block CB1(clk_in,wr,rd,wr_clk,rd_clk,wr_en,rd_en);

//DATA WRITE
always @(wr_clk or rd_clk or status)
begin
    if(wr_en == 1)
    begin
        //if(write_pointer != 6'b100_000)
        //begin
            temp_mem[write_pointer] <= data_in;
            write_pointer = write_pointer + 1;//write_pointer = write_pointer + 1'b1;
        //end
    end
    else if(wr_en == 0 & rd_en == 0)
        begin
        idle <= 1;       //idle state
        end
    else if(wr_en == 1 & rd_en == 0)
        begin
        idle <=1;
        end
    else if(rd_en == 1)
        begin
            //if(read_pointer != 6'b100_000)    //32
            //begin
                data_out <= temp_mem[read_pointer];
                read_pointer = read_pointer + 1;//read_pointer = read_pointer + 1'b1;
            //end
        end
    else if(wr_en == 0 & rd_en == 0)
        begin
        idle <= 1;       //idle state
        end
    else if(wr_en == 1 & rd_en == 0)
        begin
        idle <=1;
        end
    else if(rst == 1)
        begin
                    //read_pointer <= 6'b000_000;
                    //write_pointer <= 6'b000_000;
            read_pointer = 0;
            write_pointer = 0;
            for(i=0; i<mem_size+1; i=i+1)
            begin
            temp_mem[i] <= 4'b0000;
            end
         end
    else
        begin
            read_pointer = read_pointer;//read_pointer <= read_pointer;
            write_pointer = write_pointer;//write_pointer <= write_pointer;
        end
end

always @(status)
begin
if(status == 1)
            begin
                if(read_pointer == write_pointer)   //EMPTY MEM BLOCK
                begin
                emp <=1; full<=0; half<=0; //idle<=0;
                end
                else if(read_pointer == 15)//read_pointer == 6'b001111 
                begin
                emp <=0; full<=0; half<=1; //idle<=0;
                end
                else if(write_pointer == 32) //write_pointer == 6'b100000
                begin
                emp<=0; full<=1; half<=0;//idle<=0;
                end
                else if(write_pointer > 0)
                begin
                emp<=0; full<=0; half<=0;//idle<=0;
                end
            end
        else if(status == 0)
            begin
                emp <= 0; full <= 0; half <= 0;//idle <= 0;
            end
end


selector SEL(data_out,emp,full,half,idle,status,out);

endmodule


//the selector selets any one of the 4 combination of the DATA OUT or the STATUS pins
module selector(data_out,mem_state1,mem_state2,mem_state3,mem_state4,status,out);
input [3:0] data_out;
input mem_state1,mem_state2,mem_state3,mem_state4;
input status;
output wire [3:0] out;
//tristate buffer (output,input,control);
//LATCH THE DATA TO THE OUTPUT IF STATUS==0
bufif0 BF1(out[0],data_out[0],status);
bufif0 BF2(out[1],data_out[1],status);
bufif0 BF3(out[2],data_out[2],status);
bufif0 BF4(out[3],data_out[3],status);

//LATCH THE MEM_STATE TO THE OUTPUT IF STATUS==1
bufif1 BF5(out[0],mem_state1,status);
bufif1 BF6(out[1],mem_state2,status);
bufif1 BF7(out[2],mem_state3,status);
bufif1 BF8(out[3],mem_state4,status);

endmodule