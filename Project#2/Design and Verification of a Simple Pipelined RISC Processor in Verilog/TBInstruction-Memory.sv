module instruction_memory_tb;
    // Inputs
    reg [31:0] address;
    // Outputs
    wire [31:0] instruction;

    // Instantiate Instruction Memory
    instruction_memory uut (
        .address(address),
        .instruction(instruction)
    );

    // Test stimulus
    initial begin
        // Test reading instructions
        $display("Testing Instruction Memory");
        address = 32'd0; #10;
        $display("Addr=%h, Instr=%h (OR R1, R2, R3)", address, instruction);
        address = 32'd4; #10;
        $display("Addr=%h, Instr=%h (ADD R4, R1, R2)", address, instruction);
        address = 32'd8; #10;
        $display("Addr=%h, Instr=%h (SUB R5, R4, R1)", address, instruction);
        address = 32'd12; #10;
        $display("Addr=%h, Instr=%h (CMP R6, R5, R4)", address, instruction);
        address = 32'd16; #10;
        $display("Addr=%h, Instr=%h (ORI R7, R6, 4)", address, instruction);
        address = 32'd20; #10;
        $display("Addr=%h, Instr=%h (ADDI R8, R7, 2)", address, instruction);
        address = 32'd24; #10;
        $display("Addr=%h, Instr=%h (LW R9, 4(R8))", address, instruction);
        address = 32'd28; #10;
        $display("Addr=%h, Instr=%h (SW R9, 4(R10))", address, instruction);
        address = 32'd32; #10;
        $display("Addr=%h, Instr=%h (LDW R10, 4(R9))", address, instruction);
        address = 32'd36; #10;
        $display("Addr=%h, Instr=%h (SDW R10, 4(R11))", address, instruction);
        address = 32'd40; #10;
        $display("Addr=%h, Instr=%h (BZ R10, 2)", address, instruction);
        address = 32'd44; #10;
        $display("Addr=%h, Instr=%h (BGZ R10, 2)", address, instruction);
        address = 32'd48; #10;
        $display("Addr=%h, Instr=%h (BLZ R10, 2)", address, instruction);
        address = 32'd52; #10;
        $display("Addr=%h, Instr=%h (JR R11)", address, instruction);
        address = 32'd56; #10;
        $display("Addr=%h, Instr=%h (J 2)", address, instruction);
        address = 32'd60; #10;
        $display("Addr=%h, Instr=%h (CLL 2)", address, instruction);

        $finish;
    end
endmodule