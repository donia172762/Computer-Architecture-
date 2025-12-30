module control_unit (
    input clk,                    // Clock signal
    input reset,                  // Reset signal
    input [5:0] opcode,           // Operation code (6 bits)
    input zero,                   // Zero flag from ALU (for BZ)
    input positive,               // Positive flag from ALU (for BGZ)
    input negative,               // Negative flag from ALU (for BLZ)
    input exception,              // Exception signal from register file
    output reg pc_write,          // Enable PC write
    output reg reg_read,          // Enable register read
    output reg reg_write,         // Enable register write
    output reg reg_write_addr_sel,// Select R14 for CLL
    output reg mem_read,          // Enable memory read
    output reg mem_write,         // Enable memory write
    output reg second_cycle,      // Second cycle signal for LDW/SDW
    output reg branch,            // Branch signal (BZ, BGZ, BLZ)
    output reg jump,              // Jump signal (J, CLL)
    output reg jr,                // Jump register signal (JR)
    output reg [1:0] alu_op,      // ALU control signal
    output reg alu_src_b,         // Select second ALU input (Rt or Imm)
    output reg mem_to_reg,        // Select write data (ALU or memory)
    output reg stall              // Stall signal for LDW/SDW
);

    // State definitions
    localparam FETCH = 3'd0,
               DECODE = 3'd1,
               EXECUTE = 3'd2,
               MEMORY = 3'd3,
               WRITE_BACK = 3'd4,
               LDW_SDW_SECOND = 3'd5;

    reg [2:0] state, next_state;

    // State register: Transition to next state on positive clock edge or reset
    always @(posedge clk or posedge reset) begin
        if (reset)
            state <= FETCH;
        else
            state <= next_state;
    end

    // Next state logic: Determine next state based on current state and opcode
    always @(*) begin
        case (state)
            FETCH: next_state = DECODE; // Transition to DECODE after fetching instruction
            DECODE: begin
                case (opcode)
                    6'd8, 6'd9: next_state = EXECUTE; // LDW, SDW
                    default: next_state = EXECUTE;    // Other instructions
                endcase
            end
            EXECUTE: begin
                case (opcode)
                    6'd6, 6'd7: next_state = MEMORY; // LW, SW
                    6'd8, 6'd9: next_state = MEMORY; // LDW, SDW
                    6'd10, 6'd11, 6'd12, 6'd13, 6'd14: next_state = FETCH; // BZ, BGZ, BLZ, JR, J
                    6'd15: next_state = WRITE_BACK;  // CLL (write return address to R14)
                    default: next_state = WRITE_BACK; // OR, ADD, SUB, CMP, ORI, ADDI
                endcase
            end
            MEMORY: begin
                case (opcode)
                    6'd8, 6'd9: next_state = LDW_SDW_SECOND; // LDW, SDW
                    default: next_state = WRITE_BACK;         // LW, SW
                endcase
            end
            LDW_SDW_SECOND: next_state = WRITE_BACK; // Transition to WRITE_BACK after second cycle
            WRITE_BACK: next_state = FETCH;          // Return to FETCH
            default: next_state = FETCH;             // Default state
        endcase
    end

    // Control signals: Set control signals based on state and opcode
    always @(*) begin
        // Default values
        pc_write = 0;
        reg_read = 0;
        reg_write = 0;
        reg_write_addr_sel = 0;
        mem_read = 0;
        mem_write = 0;
        second_cycle = 0;
        branch = 0;
        jump = 0;
        jr = 0;
        alu_op = 2'b00;
        alu_src_b = 0;
        mem_to_reg = 0;
        stall = 0;

        case (state)
            FETCH: begin
                pc_write = 1; // Update program counter (PC)
            end
            DECODE: begin
                reg_read = 1; // Read registers
                if (opcode == 6'd8 || opcode == 6'd9) begin
                    stall = 1; // Stall fetching next instruction for LDW/SDW
                end
            end
            EXECUTE: begin
                case (opcode)
                    6'd0, 6'd4: alu_op = 2'b00; // OR, ORI
                    6'd1, 6'd5, 6'd6, 6'd7, 6'd8, 6'd9: alu_op = 2'b01; // ADD, ADDI, LW, SW, LDW, SDW
                    6'd2: alu_op = 2'b10; // SUB
                    6'd3, 6'd10, 6'd11, 6'd12: alu_op = 2'b11; // CMP, BZ, BGZ, BLZ
                    6'd13, 6'd14, 6'd15: alu_op = 2'b01; // JR, J, CLL
                endcase
                alu_src_b = (opcode == 6'd4 || opcode == 6'd5 || opcode == 6'd6 || opcode == 6'd7 || opcode == 6'd8 || opcode == 6'd9); // Select Imm for ORI, ADDI, LW, SW, LDW, SDW
                branch = (opcode == 6'd10 && zero) || (opcode == 6'd11 && positive) || (opcode == 6'd12 && negative); // Branch for BZ, BGZ, BLZ
                jump = (opcode == 6'd14 || opcode == 6'd15); // Jump for J, CLL
                jr = (opcode == 6'd13); // Jump register for JR
            end
            MEMORY: begin
                mem_read = (opcode == 6'd6 || opcode == 6'd8); // Memory read for LW, LDW
                mem_write = (opcode == 6'd7 || opcode == 6'd9); // Memory write for SW, SDW
            end
            LDW_SDW_SECOND: begin
                second_cycle = 1; // Second cycle signal for LDW/SDW
                mem_read = (opcode == 6'd8); // Memory read for LDW
                mem_write = (opcode == 6'd9); // Memory write for SDW
                stall = 1; // Stall fetching next instruction
            end
            WRITE_BACK: begin
                reg_write = (opcode == 6'd0 || opcode == 6'd1 || opcode == 6'd2 || opcode == 6'd3 || opcode == 6'd4 || opcode == 6'd5 || opcode == 6'd6 || opcode == 6'd8 || opcode == 6'd15); // Register write for OR, ADD, SUB, CMP, ORI, ADDI, LW, LDW, CLL
                mem_to_reg = (opcode == 6'd6 || opcode == 6'd8); // Write memory data for LW, LDW
                reg_write_addr_sel = (opcode == 6'd15); // Select R14 for CLL
                if (opcode == 6'd9 && exception) begin
                    reg_write = 0; // Prevent register write if exception in SDW
                end
            end
        endcase
    end

endmodule