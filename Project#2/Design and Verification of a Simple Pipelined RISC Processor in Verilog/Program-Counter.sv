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