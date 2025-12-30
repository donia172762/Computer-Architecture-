
module control_unit (
    input clk,                  // إشارة الساعة
    input reset,                // إشارة إعادة الضبط
    input [5:0] opcode,         // الأوبكود من التعليمة
    input zero,                 // إشارة الصفر من ALU (لـ BZ)
    input positive,             // إشارة الموجب من ALU (لـ BGZ)
    input negative,             // إشارة السالب من ALU (لـ BLZ)
    output reg pc_write,        // تمكين كتابة PC
    output reg imem_read,       // قراءة ذاكرة التعليمات
    output reg reg_read,        // قراءة السجلات
    output reg reg_write,       // كتابة السجلات
    output reg [1:0] alu_op,    // عملية ALU
    output reg alu_src,         // مصدر المدخل الثاني لـ ALU (0: سجل، 1: قيمة فورية)
    output reg mem_read,        // قراءة ذاكرة البيانات
    output reg mem_write,       // كتابة ذاكرة البيانات
    output reg mem_to_reg,      // مصدر الكتابة (0: ALU، 1: الذاكرة)
    output reg branch,          // التحكم بالتفرع
    output reg jump,            // التحكم بالقفز
    output reg reg_write_addr_sel, // اختيار R14 لـ CLL
    output reg second_cycle     // إشارة الدورة الثانية لـ LDW/SDW
);

    // تعريف الحالات
    parameter FETCH    = 3'b000;
    parameter DECODE   = 3'b001;
    parameter EXECUTE  = 3'b010;
    parameter MEMORY   = 3'b011;
    parameter WRITEBACK = 3'b100;

    reg [2:0] state, next_state;

    // الانتقال بين الحالات مع إعادة الضبط
    always @(posedge clk or posedge reset) begin
        if (reset)
            state <= FETCH;
        else
            state <= next_state;
    end

    // منطق الدورة الثانية لـ LDW/SDW
    always @(posedge clk or posedge reset) begin
        if (reset)
            second_cycle <= 0;
        else if (state == MEMORY && (opcode == 6'b001000 || opcode == 6'b001001)) // LDW or SDW
            second_cycle <= 1;
        else if (state == WRITEBACK)
            second_cycle <= 0;
    end

    // منطق الحالة التالية وإشارات التحكم
    always @(*) begin
        // القيم الافتراضية
        pc_write = 0;
        imem_read = 0;
        reg_read = 0;
        reg_write = 0;
        alu_op = 2'b00;
        alu_src = 0;
        mem_read = 0;
        mem_write = 0;
        mem_to_reg = 0;
        branch = 0;
        jump = 0;
        reg_write_addr_sel = 0;
        next_state = state;

        case (state)
            FETCH: begin
                imem_read = 1;   // جلب التعليمة
                next_state = DECODE;
            end
            DECODE: begin
                reg_read = 1;    // قراءة السجلات
                next_state = EXECUTE;
            end
            EXECUTE: begin
                reg_read = 1;    // قراءة السجلات لمعظم التعليمات
                case (opcode)
                    6'b000000: alu_op = 2'b00; // OR
                    6'b000001: alu_op = 2'b01; // ADD
                    6'b000010: alu_op = 2'b10; // SUB
                    6'b000011: alu_op = 2'b11; // CMP
                    6'b000100: begin // ORI
                        alu_op = 2'b00;
                        alu_src = 1;
                    end
                    6'b000101: begin // ADDI
                        alu_op = 2'b01;
                        alu_src = 1;
                    end
                    6'b000110: begin // LW
                        alu_op = 2'b01;
                        alu_src = 1;
                    end
                    6'b000111: begin // SW
                        alu_op = 2'b01;
                        alu_src = 1;
                    end
                    6'b001000: begin // LDW
                        alu_op = 2'b01;
                        alu_src = 1;
                    end
                    6'b001001: begin // SDW
                        alu_op = 2'b01;
                        alu_src = 1;
                    end
                    6'b001010: alu_op = 2'b11; // BZ
                    6'b001011: alu_op = 2'b11; // BGZ
                    6'b001100: alu_op = 2'b11; // BLZ
                    6'b001101: begin // JR
                        jump = 1;
                    end
                    6'b001110: jump = 1; // J
                    6'b001111: begin // CLL
                        jump = 1;
                        reg_write_addr_sel = 1;
                    end
                    default: alu_op = 2'b00;
                endcase
                next_state = (opcode >= 6'b000110 && opcode <= 6'b001100) ? MEMORY : WRITEBACK;
            end
            MEMORY: begin
                case (opcode)
                    6'b000110: begin // LW
                        mem_read = 1;
                        next_state = WRITEBACK;
                    end
                    6'b000111: begin // SW
                        mem_write = 1;
                        next_state = WRITEBACK;
                    end
                    6'b001000: begin // LDW
                        mem_read = 1;
                        next_state = second_cycle ? WRITEBACK : MEMORY; // الدورة الثانية
                    end
                    6'b001001: begin // SDW
                        mem_write = 1;
                        next_state = second_cycle ? WRITEBACK : MEMORY; // الدورة الثانية
                    end
                    6'b001010: begin // BZ
                        if (zero) begin
                            branch = 1;
                            pc_write = 1;
                        end
                        next_state = FETCH;
                    end
                    6'b001011: begin // BGZ
                        if (positive) begin
                            branch = 1;
                            pc_write = 1;
                        end
                        next_state = FETCH;
                    end
                    6'b001100: begin // BLZ
                        if (negative) begin
                            branch = 1;
                            pc_write = 1;
                        end
                        next_state = FETCH;
                    end
                    6'b001101: begin // JR
                        jump = 1;
                        pc_write = 1;
                        next_state = FETCH;
                    end
                    6'b001110: begin // J
                        jump = 1;
                        pc_write = 1;
                        next_state = FETCH;
                    end
                    6'b001111: begin // CLL
                        jump = 1;
                        pc_write = 1;
                        reg_write = 1;
                        next_state = FETCH;
                    end
                endcase
            end
            WRITEBACK: begin
                reg_write = 1;
                mem_to_reg = (opcode == 6'b000110 || opcode == 6'b001000) ? 1 : 0; // LW أو LDW
                pc_write = 1; // تحديث PC في نهاية التعليمة
                next_state = FETCH;
            end
            default: begin
                next_state = FETCH;
            end
        endcase
    end

endmodule