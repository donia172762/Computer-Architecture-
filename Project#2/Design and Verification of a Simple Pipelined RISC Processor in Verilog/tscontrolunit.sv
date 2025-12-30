module tb_control_unit;

    // Input signals
    reg clk;
    reg reset;
    reg [5:0] opcode;
    reg zero, positive, negative, exception;

    // Output signals
    wire pc_write, reg_read, reg_write, reg_write_addr_sel, mem_read, mem_write;
    wire second_cycle, branch, jump, jr, stall, mem_to_reg;
    wire [1:0] alu_op;
    wire alu_src_b;

    // Instantiate the control unit
    control_unit uut (
        .clk(clk),
        .reset(reset),
        .opcode(opcode),
        .zero(zero),
        .positive(positive),
        .negative(negative),
        .exception(exception),
        .pc_write(pc_write),
        .reg_read(reg_read),
        .reg_write(reg_write),
        .reg_write_addr_sel(reg_write_addr_sel),
        .mem_read(mem_read),
        .mem_write(mem_write),
        .second_cycle(second_cycle),
        .branch(branch),
        .jump(jump),
        .jr(jr),
        .alu_op(alu_op),
        .alu_src_b(alu_src_b),
        .mem_to_reg(mem_to_reg),
        .stall(stall)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // Clock with a period of 10 ns
    end

    // Test procedure
    initial begin
        // Reset
        reset = 1;
        opcode = 6'd0;
        zero = 0;
        positive = 0;
        negative = 0;
        exception = 0;
        #10 reset = 0;

        // Test OR instruction (Opcode=0)
        $display("Testing OR (Opcode=0)");
        opcode = 6'd0;
        #50; // FETCH → DECODE → EXECUTE → WRITE_BACK → FETCH

        // Test ADD instruction (Opcode=1)
        $display("Testing ADD (Opcode=1)");
        opcode = 6'd1;
        #50;

        // Test SUB instruction (Opcode=2)
        $display("Testing SUB (Opcode=2)");
        opcode = 6'd2;
        #50;

        // Test CMP instruction (Opcode=3)
        $display("Testing CMP (Opcode=3)");
        opcode = 6'd3;
        zero = 1; // Case: a == b
        #50;
        zero = 0; positive = 1; // Case: a > b
        #50;
        positive = 0; negative = 1; // Case: a < b
        #50;

        // Test ORI instruction (Opcode=4)
        $display("Testing ORI (Opcode=4)");
        opcode = 6'd4;
        #50;

        // Test ADDI instruction (Opcode=5)
        $display("Testing ADDI (Opcode=5)");
        opcode = 6'd5;
        #50;

        // Test LW instruction (Opcode=6)
        $display("Testing LW (Opcode=6)");
        opcode = 6'd6;
        #60;

        // Test SW instruction (Opcode=7)
        $display("Testing SW (Opcode=7)");
        opcode = 6'd7;
        #60;

        // Test LDW instruction (Opcode=8) without exception
        $display("Testing LDW (Opcode=8, no exception)");
        opcode = 6'd8;
        exception = 0;
        #70;

        // Test SDW instruction (Opcode=9) with exception
        $display("Testing SDW (Opcode=9, with exception)");
        opcode = 6'd9;
        exception = 1; // Simulate odd destination register
        #70;

        // Test BZ instruction (Opcode=10) with zero=1
        $display("Testing BZ (Opcode=10, zero=1)");
        opcode = 6'd10;
        zero = 1; // Branch condition
        #50; // FETCH → DECODE → EXECUTE → FETCH
        zero = 0;

        // Test BZ instruction (Opcode=10) with zero=0
        $display("Testing BZ (Opcode=10, zero=0)");
        opcode = 6'd10;
        zero = 0; // No branch condition
        #30;

        // Test BGZ instruction (Opcode=11)
        $display("Testing BGZ (Opcode=11, positive=1)");
        opcode = 6'd11;
        positive = 1; // Branch condition
        #30;
        positive = 0;

        // Test BGZ instruction (Opcode=11) with positive=0
        $display("Testing BGZ (Opcode=11, positive=0)");
        opcode = 6'd11;
        positive = 0; // No branch condition
        #30;

        // Test BLZ instruction (Opcode=12)
        $display("Testing BLZ (Opcode=12, negative=1)");
        opcode = 6'd12;
        negative = 1; // Branch condition
        #30;
        negative = 0;

        // Test BLZ instruction (Opcode=12) with negative=0
        $display("Testing BLZ (Opcode=12, negative=0)");
        opcode = 6'd12;
        negative = 0; // No branch condition
        #30;

        // Test JR instruction (Opcode=13)
        $display("Testing JR (Opcode=13)");
        opcode = 6'd13;
        #30;

        // Test J instruction (Opcode=14)
        $display("Testing J (Opcode=14)");
        opcode = 6'd14;
        #30;

        // Test CLL instruction (Opcode=15)
        $display("Testing CLL (Opcode=15)");
        opcode = 6'd15;
        #50;

        // Test CLL instruction (Opcode=15) again to verify R14 write
        $display("Testing CLL (Opcode=15, verify R14 write)");
        opcode = 6'd15;
        #50;

        // End simulation
        $display("Test completed");
        #10 $finish;
    end

    // Monitor signals
    initial begin
        $monitor("Time=%0t | State=%0d | Opcode=%0d | pc_write=%b | reg_read=%b | reg_write=%b | reg_write_addr_sel=%b | mem_read=%b | mem_write=%b | second_cycle=%b | branch=%b | jump=%b | jr=%b | alu_op=%b | alu_src_b=%b | mem_to_reg=%b | stall=%b",
            $time, uut.state, opcode, pc_write, reg_read, reg_write, reg_write_addr_sel, mem_read, mem_write, second_cycle, branch, jump, jr, alu_op, alu_src_b, mem_to_reg, stall);
    end

endmodule