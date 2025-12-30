module alu (
    input [31:0] a, b,        // Two 32-bit inputs (a: Rs or Rs+Imm, b: Rt or Imm or 0)
    input [1:0] alu_op,       // 2-bit operation control (00: OR, 01: ADD, 10: SUB, 11: CMP)
    output reg [31:0] result, // 32-bit result
    output reg zero,          // Zero flag (a == b) for BZ
    output reg positive,      // Positive flag (a > b) for BGZ
    output reg negative,      // Negative flag (a < b) for BLZ
    output reg overflow       // Overflow flag for ADD and SUB
);

always @(*) begin
    // Default values for flags
    zero = 0;
    positive = 0;
    negative = 0;
    overflow = 0;

    case (alu_op)
        2'b00: result = a | b;               // OR operation (for OR, ORI)
        2'b01: begin                         // ADD operation (for ADD, ADDI, LW, SW, LDW, SDW address calc)
            result = a + b;
            overflow = (a[31] == b[31]) && (result[31] != a[31]); // ADD overflow
        end
        2'b10: begin                         // SUB operation (for SUB)
            result = a - b;
            overflow = (a[31] != b[31]) && (result[31] != a[31]); // SUB overflow
        end
        2'b11: begin                         // CMP operation (for CMP, BZ, BGZ, BLZ)
            if (a == b) begin
                result = 32'h00000000;       // Equal: result = 0 (for CMP, BZ)
                zero = 1;
                positive = 0;
                negative = 0;
            end
            else if ($signed(a) > $signed(b)) begin
                result = 32'h00000001;       // Greater: result = 1 (for CMP, BGZ)
                zero = 0;
                positive = 1;
                negative = 0;
            end
            else begin
                result = 32'hFFFFFFFF;       // Less: result = -1 (for CMP, BLZ)
                zero = 0;
                positive = 0;
                negative = 1;
            end
        end
        default: begin
            result = 32'h00000000;           // Default case
            zero = 0;
            positive = 0;
            negative = 0;
            overflow = 0;
        end
    endcase
end

endmodule


module data_memory (
    input clk,                  // Clock signal
    input [31:0] address,       // Address for read/write
    input [31:0] write_data,    // Data to write (for STORE)
    input mem_read,             // Read enable (for LOAD)
    input mem_write,            // Write enable (for STORE)
    input second_cycle,         // Indicates second cycle for LDW/SDW
    output reg [31:0] read_data // Data read from memory (for LOAD)
);

    // Data memory: 16 words, 32-bit each
    reg [31:0] memory [0:15];

    // Initialize memory with test values
    initial begin
        memory[0]  = 32'h00000000;
        memory[1]  = 32'h11111111;
        memory[2]  = 32'h22222222;
        memory[3]  = 32'h33333333;
        memory[4]  = 32'h44444444;
        memory[5]  = 32'h55555555;
        memory[6]  = 32'h66666666;
        memory[7]  = 32'h77777777;
        memory[8]  = 32'h88888888;
        memory[9]  = 32'h99999999;
        memory[10] = 32'hAAAAAAAA;
        memory[11] = 32'hBBBBBBBB;
        memory[12] = 32'hCCCCCCCC;
        memory[13] = 32'hDDDDDDDD;
        memory[14] = 32'hEEEEEEEE;
        memory[15] = 32'hFFFFFFFF;
    end

    // Write operation (synchronous)
    always @(posedge clk) begin
        if (mem_write) begin
            memory[address[5:2] + (second_cycle ? 1 : 0)] <= write_data;
        end
    end

    // Read operation (combinational)
    always @(address, mem_read, second_cycle) begin
        if (mem_read) begin
            read_data = memory[address[5:2] + (second_cycle ? 1 : 0)];
        end else begin
            read_data = 32'h00000000;
        end
    end

endmodule


module extender (
    input [13:0] imm_in,       // 14-bit immediate input from instruction
    input [5:0] opcode,        // 6-bit opcode to determine extension type
    output reg [31:0] imm_out  // 32-bit extended immediate output
);

    // Combinational logic for sign/zero extension
    always @(*) begin
        if (opcode == 6'b000100) begin // ORI instruction (Zero-Extension)
            imm_out = {18'b0, imm_in}; // Zero-extend: pad with 18 zeros
        end
        else begin // Other instructions (Sign-Extension)
            imm_out = {{18{imm_in[13]}}, imm_in}; // Sign-extend: replicate sign bit
        end
    end

endmodule


module instruction_memory (
    input [31:0] address,        // Address input from PC
    output reg [31:0] instruction // Instruction output
);

    // Instruction memory: 16 instructions, 32-bit each
  reg [31:0] memory [0:17];

    initial begin
        $readmemb("instruction_mem.mem", memory);
    end
    always @(address) begin
        instruction = memory[address[5:2]];
    end
endmodule
    

module mux2x1 (
    input [31:0] in0,       // First input
    input [31:0] in1,       // Second input
    input sel,              // Select signal
    output [31:0] out       // Output
);

    // Output assignment based on select signal
    assign out = sel ? in1 : in0;

endmodule



module program_counter (
    input clk,                  // Clock signal
    input reset,                // Reset signal
    input pc_write,             // Enable PC update
    input branch,               // Branch signal
    input jump,                 // Jump signal
    input jr,                   // Jump register signal
    input [13:0] offset,        // Offset for Branch (14 bits, sign-extended)
    input [31:0] jump_addr,     // Target address for JR
    input [13:0] target,        // Target for J/CLL (14 bits, sign-extended)
    output reg [31:0] pc_out,   // Current PC value
    output [31:0] return_addr   // Return address for CLL (PC + 1)
);

    // Internal signals
    wire [31:0] next_pc;
    wire [31:0] branch_addr;
    wire [31:0] j_target_addr;
    wire [31:0] pc_plus_1;

    // Sign-extend offset and target (14 bits to 32 bits) and multiply by 4
    assign branch_addr = pc_out + {{18{offset[13]}}, offset, 2'b00};
    assign j_target_addr = pc_out + {{18{target[13]}}, target, 2'b00};
    assign pc_plus_1 = pc_out + 32'd1;
    assign return_addr = pc_plus_1;

    // Select next PC value
    assign next_pc = jr ? jump_addr :
                     jump ? j_target_addr :
                     branch ? branch_addr :
                     pc_plus_1;

    // Update PC on clock edge if pc_write is enabled
    always @(posedge clk or posedge reset) begin
        if (reset)
            pc_out <= 32'd0;
        else if (pc_write)
            pc_out <= next_pc;
    end

endmodule



module register_file (
    input clk,
    input reset,
    input reg_read,
    input [3:0] rs, rt, rd,
    input reg_write,
    input reg_write_addr_sel, // Selects R14 for CLL
    input stall,              // Stall signal for multi-cycle instructions
    input [5:0] opcode,       // Opcode for LDW/SDW exception check
    input [31:0] write_data,
    input [31:0] return_addr, // Return address for CLL
    output reg [31:0] read_data1, read_data2,
    output reg exception      // Exception signal for odd Rd/Rs in LDW/SDW
);

    reg [31:0] registers [0:15];

    // Initialize registers
    initial begin
        integer i;
        for (i = 0; i < 16; i = i + 1)
            registers[i] = 32'd0;
    end

    // Read data (synchronous)
    always @(posedge clk) begin
        if (reset) begin
            read_data1 <= 32'd0;
            read_data2 <= 32'd0;
        end
        else if (reg_read && !stall) begin
            read_data1 <= registers[rs];
            read_data2 <= registers[rt];
        end
    end

    // Write data
    always @(posedge clk) begin
        if (reset) begin
            registers[15] <= 32'd0; // Reset PC (R15)
        end
        else if (reg_write && !stall) begin
            if (rd != 15) begin
                if (reg_write_addr_sel) begin
                    registers[14] <= return_addr; // Write to R14 for CLL
                end
                else begin
                    registers[rd] <= write_data;
                end
            end
        end
    end

    // Exception logic for LDW (opcode ?? and SDW (opcode 9)
    always @(posedge clk) begin
        if (reset) begin
            exception <= 0;
        end
        else if (reg_write && !stall) begin
            if ((opcode == 6'd8 || opcode == 6'd9) && rd[0] == 1) begin
                exception <= 1; // Odd Rd for LDW/SDW
            end
            else begin
                exception <= 0;
            end
        end
    end

endmodule



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


module processor (
    input clk,
    input reset,
    output [31:0] instruction,
    output [31:0] pc_out
);
    // ??????? (Wires) ???? ????????
    wire [31:0] read_data1, read_data2, alu_result, mem_read_data, write_data;
    wire [31:0] imm_out, jump_addr, return_addr;
    wire [5:0] opcode;
    wire [3:0] rd, rs, rt;
    wire [13:0] imm;
    wire zero, positive, negative, overflow, exception;
    wire pc_write, reg_read, reg_write, reg_write_addr_sel, mem_read, mem_write;
    wire second_cycle, branch, jump, jr, alu_src_b, mem_to_reg, stall;
    wire [1:0] alu_op;

    // ??????? ?????? ?? ????????
    assign opcode = instruction[31:26];
    assign rd = instruction[25:22];
    assign rs = instruction[21:18];
    assign rt = instruction[17:14];
    assign imm = instruction[13:0];

    // ???? ????????
    program_counter pc (
        .clk(clk), .reset(reset), .pc_write(pc_write), .branch(branch),
        .jump(jump), .jr(jr), .offset(imm), .jump_addr(read_data1),
        .target(imm), .pc_out(pc_out), .return_addr(return_addr)
    );

    // ????? ?????????
    instruction_memory imem (
        .address(pc_out), .instruction(instruction)
    );

    // ??? ???????
    register_file rf (
        .clk(clk), .reset(reset), .reg_read(reg_read), .rs(rs), .rt(rt), .rd(rd),
        .reg_write(reg_write), .reg_write_addr_sel(reg_write_addr_sel),
        .stall(stall), .opcode(opcode), .write_data(write_data),
        .return_addr(return_addr), .read_data1(read_data1),
        .read_data2(read_data2), .exception(exception)
    );

    // ??????
    extender ext (
        .imm_in(imm), .opcode(opcode), .imm_out(imm_out)
    );

    // ???? ?????? ??????? (ALU)
    wire [31:0] alu_b;
    mux2x1 mux_alu_b (
        .in0(read_data2), .in1(imm_out), .sel(alu_src_b), .out(alu_b)
    );

    alu alu_inst (
        .a(read_data1), .b(alu_b), .alu_op(alu_op), .result(alu_result),
        .zero(zero), .positive(positive), .negative(negative), .overflow(overflow)
    );

    // ????? ????????
    data_memory dmem (
        .clk(clk), .address(alu_result), .write_data(read_data2),
        .mem_read(mem_read), .mem_write(mem_write), .second_cycle(second_cycle),
        .read_data(mem_read_data)
    );

    // ?????? ?????? ??????? ??? ??? ???????
    mux2x1 mux_write_data (
        .in0(alu_result), .in1(mem_read_data), .sel(mem_to_reg), .out(write_data)
    );

    // ???? ??????
    control_unit cu (
        .clk(clk), .reset(reset), .opcode(opcode), .zero(zero),
        .positive(positive), .negative(negative), .exception(exception),
        .pc_write(pc_write), .reg_read(reg_read), .reg_write(reg_write),
        .reg_write_addr_sel(reg_write_addr_sel), .mem_read(mem_read),
        .mem_write(mem_write), .second_cycle(second_cycle), .branch(branch),
        .jump(jump), .jr(jr), .alu_op(alu_op), .alu_src_b(alu_src_b),
        .mem_to_reg(mem_to_reg), .stall(stall)
    );
endmodule

module processor_tb;
    // ????????? ?????????
    reg clk;
    reg reset;
    wire [31:0] instruction;
    wire [31:0] pc_out;

    // ????? ????? ???????
    processor uut (
        .clk(clk),
        .reset(reset),
        .instruction(instruction),
        .pc_out(pc_out)
    );

    // ????? ????? ??????
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // ???? ?????? 10ns
    end

    // ????? ????? ????? ?????? ????????
    initial begin
        // ????? ????? ????????
        $dumpfile("processor_tb.vcd");
        $dumpvars(0, processor_tb);

        // ????? ?????
        reset = 1;
        #20 reset = 0; // ????? ????? ????? ??? 20ns

        // ???????? ?????? ????????
        #500;

        // ?????? ?? ??????? ????????
        $display("Final Register Values:");
        for (integer i = 0; i < 16; i = i + 1) begin
            $display("R%0d = %h", i, uut.rf.registers[i]);
        end
        $display("Final Data Memory Values:");
        for (integer i = 0; i < 16; i = i + 1) begin
            $display("Memory[%0d] = %h", i, uut.dmem.memory[i]);
        end

        // ????? ????????
        $finish;
    end

    // ?????? ????????
    initial begin
        $monitor("Time=%0t, PC=%h, Instruction=%h, State=%0d, ALU_op=%b, RegWrite=%b, MemRead=%b, MemWrite=%b, Exception=%b, RegData1=%h, RegData2=%h, MemData=%h",
                 $time, pc_out, instruction, uut.cu.state, uut.alu_op, uut.reg_write, uut.mem_read, uut.mem_write, uut.rf.exception, uut.read_data1, uut.read_data2, uut.mem_read_data);
    end
endmodule