module extender_tb;

    // المدخلات
    reg [13:0] imm_in;
    reg [5:0] opcode;
    
    // المخرجات
    wire [31:0] imm_out;
    
    // تهيئة الوحدة المختبرة (UUT)
    extender uut (
        .imm_in(imm_in),
        .opcode(opcode),
        .imm_out(imm_out)
    );
    
    // إجراء الاختبار
    initial begin
        // تهيئة المدخلات
        imm_in = 14'h0000;
        opcode = 6'b000000;
        
        // مراقبة المخرجات
        $monitor("Time=%0t opcode=%b imm_in=%h imm_out=%h", $time, opcode, imm_in, imm_out);
        
        // الحالة الاختبارية 1: الكود الافتراضي (توسيع الإشارة، المدخل صفر)
        #10;
        opcode = 6'b000000; // Default
        imm_in = 14'h0000;  // 0
        #10;
        
        // الحالة الاختبارية 2: ORI (توسيع الصفر) مع قيمة فورية إيجابية
        opcode = 6'b000100; // ORI
        imm_in = 14'h1234;  // 0x1234
        #10;
        
        // الحالة الاختبارية 3: ORI (توسيع الصفر) مع أقصى قيمة فورية إيجابية
        opcode = 6'b000100; // ORI
        imm_in = 14'h3FFF;  // 0x3FFF
        #10;
        
        // الحالة الاختبارية 4: ADDI (توسيع الإشارة) مع قيمة فورية إيجابية
        opcode = 6'b000101; // ADDI
        imm_in = 14'h1234;  // 0x1234
        #10;
        
        // الحالة الاختبارية 5: ADDI (توسيع الإشارة) مع قيمة فورية سالبة
        opcode = 6'b000101; // ADDI
        imm_in = 14'hF234;  // -3532
        #10;
        
        // الحالة الاختبارية 6: LW (توسيع الإشارة) مع قيمة فورية إيجابية
        opcode = 6'b000110; // LW
        imm_in = 14'h1FFF;  // 0x1FFF
        #10;
        
        // الحالة الاختبارية 7: LW (توسيع الإشارة) مع قيمة فورية سالبة
        opcode = 6'b000110; // LW
        imm_in = 14'hE000;  // -8192
        #10;
        
        // الحالة الاختبارية 8: BZ (توسيع الإشارة) مع قيمة فورية إيجابية
        opcode = 6'b001010; // BZ
        imm_in = 14'h0100;  // 0x0100
        #10;
        
        // الحالة الاختبارية 9: BZ (توسيع الإشارة) مع قيمة فورية سالبة
        opcode = 6'b001010; // BZ
        imm_in = 14'hFF00;  // -256
        #10;
        
        // الحالة الاختبارية 10: J (توسيع الإشارة) مع قيمة فورية إيجابية
        opcode = 6'b001110; // J
        imm_in = 14'h2000;  // 0x2000
        #10;
        
        // الحالة الاختبارية 11: J (توسيع الإشارة) مع قيمة فورية سالبة
        opcode = 6'b001110; // J
        imm_in = 14'hE000;  // -8192
        #10;
        
        // إنهاء المحاكاة
        #10;
        $display("Testbench completed successfully!");
        $finish;
    end

    // تسجيل الموجة
    initial begin
        $dumpfile("extender_tb.vcd"); // ملف VCD الناتج
        $dumpvars(0, extender_tb);    // تسجيل جميع الإشارات في الـ testbench
    end

    // التأكيدات للتحقق من المخرجات
    always @(imm_out) begin
        if (opcode == 6'b000100) begin // ORI: توسيع الصفر
            if (imm_out != {18'b0, imm_in})
                $display("Error: ORI zero-extension failed at time %0t, imm_in=%h, imm_out=%h", $time, imm_in, imm_out);
        end else begin // باقي الأكواد: توسيع الإشارة
            if (imm_out != {{18{imm_in[13]}}, imm_in})
                $display("Error: Sign-extension failed at time %0t, opcode=%b, imm_in=%h, imm_out=%h", $time, opcode, imm_in, imm_out);
        end
    end

endmodule