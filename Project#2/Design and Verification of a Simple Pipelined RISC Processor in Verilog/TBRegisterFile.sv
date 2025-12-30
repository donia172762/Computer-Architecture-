module register_file_tb;
    // Inputs
    reg clk, reset, reg_read, reg_write, reg_write_addr_sel, stall;
    reg [3:0] rs, rt, rd;
    reg [5:0] opcode;
    reg [31:0] write_data, return_addr;
    // Outputs
    wire [31:0] read_data1, read_data2;
    wire exception;

    // Instantiate Register File
    register_file uut (
        .clk(clk),
        .reset(reset),
        .reg_read(reg_read),
        .rs(rs),
        .rt(rt),
        .rd(rd),
        .reg_write(reg_write),
        .reg_write_addr_sel(reg_write_addr_sel),
        .stall(stall),
        .opcode(opcode),
        .write_data(write_data),
        .return_addr(return_addr),
        .read_data1(read_data1),
        .read_data2(read_data2),
        .exception(exception)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Waveform dumping
    initial begin
        $dumpfile("register_file_tb.vcd"); // Output VCD file
        $dumpvars(0, register_file_tb);   // Dump all variables in the testbench
    end

    // Test stimulus
    initial begin
        // Reset
        reset = 1; reg_read = 0; reg_write = 0; rs = 4'd0; rt = 4'd0; rd = 4'd0; opcode = 6'd0; write_data = 32'd0; return_addr = 32'd0; stall = 0;
        #10 reset = 0;

        // Test Write and Read (OR, ADD, SUB, CMP, ORI, ADDI, LW)
        $display("Testing Write and Read");
        reg_write = 1; rd = 4'd1; write_data = 32'h12345678; opcode = 6'd0;
        #10;
        reg_read = 1; rs = 4'd1; rt = 4'd0;
        #10;
        $display("Write R1=%h, Read R1=%h (Expected: %h)", write_data, read_data1, 32'h12345678);

        // Test LDW Exception (opcode 8, odd Rd)
        $display("Testing LDW Exception");
        opcode = 6'd8; rd = 4'd1; reg_write = 1; // Odd Rd
        #10;
        $display("LDW Odd Rd: exception=%b (Expected: 1)", exception);

        // Test SDW Exception (opcode 9, odd Rd)
        $display("Testing SDW Exception");
        opcode = 6'd9; rd = 4'd1; reg_write = 1; // Odd Rd
        #10;
        $display("SDW Odd Rd: exception=%b (Expected: 1)", exception);

        // Test CLL (opcode 15)
        $display("Testing CLL");
        opcode = 6'd15; reg_write_addr_sel = 1; return_addr = 32'h000000FF; reg_write = 1;
        #10;
        reg_read = 1; rs = 4'd14;
        #10;
        $display("CLL: R14=%h (Expected: %h)", read_data1, 32'h000000FF);

        #10 $finish; // Ensure simulation terminates
    end
endmodule