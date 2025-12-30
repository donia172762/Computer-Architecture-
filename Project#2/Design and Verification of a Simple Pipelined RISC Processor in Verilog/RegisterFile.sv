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

    // Exception logic for LDW (opcode 8) and SDW (opcode 9)
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