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