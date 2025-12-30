module tb_mux2x1;
    reg [31:0] in0;
    reg [31:0] in1;
    reg sel;
    wire [31:0] out;

    // Instantiate the MUX2x1
    mux2x1 mux (
        .in0(in0),
        .in1(in1),
        .sel(sel),
        .out(out)
    );

    // Generate waveform
    initial begin
        // Create VCD file for waveform
        $dumpfile("tb_mux2x1.vcd");
        $dumpvars(0, tb_mux2x1); // Dump all signals in the testbench
    end

    // Test procedure
    initial begin
        // Test 1: sel = 0, in0 = 0x12345678, in1 = 0xABCDEF01
        in0 = 32'h12345678;
        in1 = 32'hABCDEF01;
        sel = 0;
        #10 $display("Test 1: sel=%b, in0=%h, in1=%h, out=%h", sel, in0, in1, out);

        // Test 2: sel = 1, in0 = 0x12345678, in1 = 0xABCDEF01
        sel = 1;
        #10 $display("Test 2: sel=%b, in0=%h, in1=%h, out=%h", sel, in0, in1, out);

        // Test 3: sel = 0, in0 = 0x00000000, in1 = 0xFFFFFFFF
        in0 = 32'h00000000;
        in1 = 32'hFFFFFFFF;
        sel = 0;
        #10 $display("Test 3: sel=%b, in0=%h, in1=%h, out=%h", sel, in0, in1, out);

        // Test 4: sel = 1, in0 = 0x00000000, in1 = 0xFFFFFFFF
        sel = 1;
        #10 $display("Test 4: sel=%b, in0=%h, in1=%h, out=%h", sel, in0, in1, out);

        #10 $finish;
    end
endmodule