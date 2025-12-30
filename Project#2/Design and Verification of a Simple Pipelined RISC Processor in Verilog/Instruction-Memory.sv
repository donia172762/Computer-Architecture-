module instruction_memory (
    input [31:0] address,        // Address input from PC
    output reg [31:0] instruction // Instruction output
);

    // Instruction memory: 16 instructions, 32-bit each
    reg [31:0] memory [0:15];

    // Initialize memory with test instructions covering all ISA
    initial begin
        // Format: [31:26] opcode, [25:22] Rd, [21:18] Rs, [17:14] Rt, [13:0] Imm
        memory[0]  = 32'b000000_0001_0010_0011_00000000000000; // OR R1, R2, R3
        memory[1]  = 32'b000001_0100_0001_0010_00000000000000; // ADD R4, R1, R2
        memory[2]  = 32'b000010_0101_0100_0001_00000000000000; // SUB R5, R4, R1
        memory[3]  = 32'b000011_0110_0101_0100_00000000000000; // CMP R6, R5, R4
        memory[4]  = 32'b000100_0111_0110_0000000000000100; // ORI R7, R6, 4
        memory[5]  = 32'b000101_1000_0111_0000000000000010; // ADDI R8, R7, 2
        memory[6]  = 32'b000110_1001_1000_0000000000000100; // LW R9, 4(R8)
        memory[7]  = 32'b000111_1001_1010_0000000000000100; // SW R9, 4(R10)
        memory[8]  = 32'b001000_1010_1001_0000000000000100; // LDW R10, 4(R9)
        memory[9]  = 32'b001001_1010_1011_0000000000000100; // SDW R10, 4(R11)
        memory[10] = 32'b001010_0000_1010_0000000000000010; // BZ R10, 2
        memory[11] = 32'b001011_0000_1010_0000000000000010; // BGZ R10, 2
        memory[12] = 32'b001100_0000_1010_0000000000000010; // BLZ R10, 2
        memory[13] = 32'b001101_0000_1011_0000000000000000; // JR R11
        memory[14] = 32'b001110_0000_0000_0000000000000010; // J 2
        memory[15] = 32'b001111_0000_0000_0000000000000010; // CLL 2
    end

    // Read instruction based on address
    always @(address) begin
        instruction = memory[address[5:2]];
    end

endmodule