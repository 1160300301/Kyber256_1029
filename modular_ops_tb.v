`timescale 1ns/1ps

module modular_ops_tb;

    parameter CLK_PERIOD = 10;
    parameter P = 3329;
    
    reg clk;
    reg reset;
    
    // �����ź�
    reg [11:0] a, b;
    wire [11:0] add_result;
    wire [11:0] sub_result;
    wire [11:0] mul_result;
    
    // ʵ����ģ��
    Mod_Add mod_add_inst (
        .clk(clk),
        .reset(reset),
        .a(a),
        .b(b),
        .result(add_result)
    );
    
    Mod_Sub mod_sub_inst (
        .clk(clk),
        .reset(reset),
        .a(a),
        .b(b),
        .result(sub_result)
    );
    
    Mod_Mul mod_mul_inst (
        .clk(clk),
        .reset(reset),
        .a(a),
        .b(b),
        .result(mul_result)
    );
    
    // ʱ������
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end
    
    // ��������
    integer i;
    integer errors;
    
    initial begin
        $display("========================================");
        $display("ģ�������̨");
        $display("P = %d", P);
        $display("========================================\n");
        
        // ��ʼ��
        reset = 1;
        a = 0;
        b = 0;
        errors = 0;
        
        repeat(5) @(posedge clk);
        reset = 0;
        @(posedge clk);
        
        // ========================================
        // ����1��ģ�ӷ�
        // ========================================
        $display("\n--- ����1��ģ�ӷ� ---");
        
        test_add(100, 200, (100 + 200) % P);
        test_add(2000, 2000, (2000 + 2000) % P);
        test_add(3328, 1, (3328 + 1) % P);
        test_add(3329, 0, 0);
        test_add(1664, 1665, 0);
        test_add(0, 0, 0);
        
        // ========================================
        // ����2��ģ����
        // ========================================
        $display("\n--- ����2��ģ���� ---");
        
        test_sub(200, 100, 100);
        test_sub(100, 200, (P + 100 - 200) % P);
        test_sub(3329, 1, 3328);
        test_sub(0, 1, P - 1);
        test_sub(3328, 3328, 0);
        test_sub(1, 0, 1);
        
        // ========================================
        // ����3��ģ�˷�
        // ========================================
        $display("\n--- ����3��ģ�˷� ---");
        
        // ��������
        test_mul(100, 200, (100 * 200) % P);
        test_mul(1000, 4, (1000 * 4) % P);
        test_mul(3328, 2, (3328 * 2) % P);
        test_mul(2000, 2000, (2000 * 2000) % P);
        
        // ����ֵ����
        test_mul(0, 100, 0);
        test_mul(1, 3328, 3328);
        test_mul(3329, 100, 0);
        
        // Kyber��ز���
        test_mul(17, 17, (17 * 17) % P);
        test_mul(17, 196, (17 * 196) % P);
        
        // ========================================
        // ����4��Barrett�߽����
        // ========================================
        $display("\n--- ����4��Barrett�߽���� ---");
        
        test_mul(4095, 4095, (4095 * 4095) % P);
        test_mul(3329, 3329, 0);
        test_mul(1664, 2, (1664 * 2) % P);
        test_mul(3328, 3328, (3328 * 3328) % P);
        test_mul(4000, 4000, (4000 * 4000) % P);
        test_mul(3000, 3000, (3000 * 3000) % P);
        
        // ========================================
        // �ܽ�
        // ========================================
        $display("\n========================================");
        if (errors == 0)
            $display("? ���в���ͨ����");
        else
            $display("? ���� %d ������", errors);
        $display("========================================\n");
        
        #100;
        $finish;
    end
    
    // ========================================
    // ��������
    // ========================================
    
    task test_add;
        input [11:0] val_a;
        input [11:0] val_b;
        input [11:0] expected;
        begin
            a = val_a;
            b = val_b;
            @(posedge clk);
            @(posedge clk);  // �ȴ�1������
            
            if (add_result == expected) begin
                $display("  PASS: %d + %d = %d", val_a, val_b, add_result);
            end else begin
                $display("  FAIL: %d + %d = %d (���� %d)", val_a, val_b, add_result, expected);
                errors = errors + 1;
            end
        end
    endtask
    
    task test_sub;
        input [11:0] val_a;
        input [11:0] val_b;
        input [11:0] expected;
        begin
            a = val_a;
            b = val_b;
            @(posedge clk);
            @(posedge clk);  // �ȴ�1������
            
            if (sub_result == expected) begin
                $display("  PASS: %d - %d = %d", val_a, val_b, sub_result);
            end else begin
                $display("  FAIL: %d - %d = %d (���� %d)", val_a, val_b, sub_result, expected);
                errors = errors + 1;
            end
        end
    endtask
    
    task test_mul;
        input [11:0] val_a;
        input [11:0] val_b;
        input [11:0] expected;
        reg [23:0] product;
        begin
            a = val_a;
            b = val_b;
            product = val_a * val_b;
            @(posedge clk);
            
            // �ȴ�4�����ڣ�1���˷� + 3��Barrett��
            repeat(4) @(posedge clk);
            
            if (mul_result == expected) begin
                $display("  PASS: %d * %d = %d (product=%d)", val_a, val_b, mul_result, product);
            end else begin
                $display("  FAIL: %d * %d = %d (���� %d, product=%d)", 
                         val_a, val_b, mul_result, expected, product);
                errors = errors + 1;
            end
        end
    endtask
    
    // �������
    initial begin
        $dumpfile("modular_ops_tb.vcd");
        $dumpvars(0, modular_ops_tb);
    end
    
    // ���Լ�أ�����ע�͵���
    /*
    always @(posedge clk) begin
        if (!reset && a != 0 && b != 0)
            $display("Time=%0t: a=%d, b=%d -> add=%d, sub=%d, mul=%d", 
                     $time, a, b, add_result, sub_result, mul_result);
    end
    */
    
endmodule