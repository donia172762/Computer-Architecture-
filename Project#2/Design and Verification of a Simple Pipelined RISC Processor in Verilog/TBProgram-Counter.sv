module program_counter_tb;
    // Inputs
    reg clk, reset, pc_write, branch, jump, jr;
    reg [13:0] offset, target;
    reg [31:0] jump_addr;
    // Outputs
    wire [31:0] pc_out, return_addr;

    // Instantiate Program Counter
    program_counter uut (
        .clk(clk),
        .reset(reset),
        .pc_write(pc_write),
        .branch(branch),
        .jump(jump),
        .jr(jr),
        .offset(offset),
        .jump_addr(jump_addr),
        .target(target),
        .pc_out(pc_out),
        .return_addr(return_addr)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Generate waveform
    initial begin
        // Create VCD file for waveform
        $dumpfile("program_counter_tb.vcd");
        $dumpvars(0, program_counter_tb); // Dump all signals in the testbench
    end

    // Test stimulus
    initial begin
        // Reset
        reset = 1; pc_write = 0; branch = 0; jump = 0; jr = 0; offset = 14'd0; target = 14'd0; jump_addr = 32'd0;
        #10 reset = 0;

        // Test normal PC increment
        $display("Testing PC Increment");
        pc_write = 1;
        #10;
        $display("PC=%h (Expected: %h)", pc_out, 32'd1);

        // Test Branch (BZ, BGZ, BLZ - opcode 10, 11, 12)
        $display("Testing Branch");
        branch = 1; offset = 14'd2; pc_write = 1; // PC + 2*4
        #10;
        $display("Branch: PC=%h (Expected: %h)", pc_out, 32'd9);

        // Test Jump (J, CLL - opcode 14, 15)
        $display("Testing Jump");
        jump = 1; branch = 0; target = 14'd2; pc_write = 1;
        #10;
        $display("Jump: PC=%h (Expected: %h)", pc_out, 32'd17);
        $display("CLL Return Addr: %h (Expected: %h)", return_addr, 32'd18); // 0x11 + 1 = 0x12 = 18

        // Test JR (opcode 13)
        $display("Testing JR");
        jump = 0; jr = 1; jump_addr = 32'd20; pc_write = 1;
        #10;
        $display("JR: PC=%h (Expected: %h)", pc_out, 32'd20);

        $finish;
    end
endmodule