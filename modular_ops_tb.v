`timescale 1ns/1ps

module modular_ops_tb;

    parameter CLK_PERIOD = 10;
    parameter P = 3329;
    
    reg clk;
    reg reset;
    
    // 测试信号
    reg [11:0] a, b;
    wire [11:0] add_result;
    wire [11:0] sub_result;
    wire [11:0] mul_result;
    
    // 实例化模块
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
    
    // 时钟生成
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end
    
    // 测试流程
    integer i;
    integer errors;
    
    initial begin
        $display("========================================");
        $display("模运算测试台");
        $display("P = %d", P);
        $display("========================================\n");
        
        // 初始化
        reset = 1;
        a = 0;
        b = 0;
        errors = 0;
        
        repeat(5) @(posedge clk);
        reset = 0;
        @(posedge clk);
        
        // ========================================
        // 测试1：模加法
        // ========================================
        $display("\n--- 测试1：模加法 ---");
        
        test_add(100, 200, (100 + 200) % P);
        test_add(2000, 2000, (2000 + 2000) % P);
        test_add(3328, 1, (3328 + 1) % P);
        test_add(3329, 0, 0);
        test_add(1664, 1665, 0);
        test_add(0, 0, 0);
        
        // ========================================
        // 测试2：模减法
        // ========================================
        $display("\n--- 测试2：模减法 ---");
        
        test_sub(200, 100, 100);
        test_sub(100, 200, (P + 100 - 200) % P);
        test_sub(3329, 1, 3328);
        test_sub(0, 1, P - 1);
        test_sub(3328, 3328, 0);
        test_sub(1, 0, 1);
        
        // ========================================
        // 测试3：模乘法
        // ========================================
        $display("\n--- 测试3：模乘法 ---");
        
        // 基本测试
        test_mul(100, 200, (100 * 200) % P);
        test_mul(1000, 4, (1000 * 4) % P);
        test_mul(3328, 2, (3328 * 2) % P);
        test_mul(2000, 2000, (2000 * 2000) % P);
        
        // 特殊值测试
        test_mul(0, 100, 0);
        test_mul(1, 3328, 3328);
        test_mul(3329, 100, 0);
        
        // Kyber相关测试
        test_mul(17, 17, (17 * 17) % P);
        test_mul(17, 196, (17 * 196) % P);
        
        // ========================================
        // 测试4：Barrett边界情况
        // ========================================
        $display("\n--- 测试4：Barrett边界情况 ---");
        
        test_mul(4095, 4095, (4095 * 4095) % P);
        test_mul(3329, 3329, 0);
        test_mul(1664, 2, (1664 * 2) % P);
        test_mul(3328, 3328, (3328 * 3328) % P);
        test_mul(4000, 4000, (4000 * 4000) % P);
        test_mul(3000, 3000, (3000 * 3000) % P);
        
        // ========================================
        // 总结
        // ========================================
        $display("\n========================================");
        if (errors == 0)
            $display("? 所有测试通过！");
        else
            $display("? 发现 %d 个错误", errors);
        $display("========================================\n");
        
        #100;
        $finish;
    end
    
    // ========================================
    // 测试任务
    // ========================================
    
    task test_add;
        input [11:0] val_a;
        input [11:0] val_b;
        input [11:0] expected;
        begin
            a = val_a;
            b = val_b;
            @(posedge clk);
            @(posedge clk);  // 等待1个周期
            
            if (add_result == expected) begin
                $display("  PASS: %d + %d = %d", val_a, val_b, add_result);
            end else begin
                $display("  FAIL: %d + %d = %d (期望 %d)", val_a, val_b, add_result, expected);
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
            @(posedge clk);  // 等待1个周期
            
            if (sub_result == expected) begin
                $display("  PASS: %d - %d = %d", val_a, val_b, sub_result);
            end else begin
                $display("  FAIL: %d - %d = %d (期望 %d)", val_a, val_b, sub_result, expected);
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
            
            // 等待4个周期（1个乘法 + 3个Barrett）
            repeat(4) @(posedge clk);
            
            if (mul_result == expected) begin
                $display("  PASS: %d * %d = %d (product=%d)", val_a, val_b, mul_result, product);
            end else begin
                $display("  FAIL: %d * %d = %d (期望 %d, product=%d)", 
                         val_a, val_b, mul_result, expected, product);
                errors = errors + 1;
            end
        end
    endtask
    
    // 波形输出
    initial begin
        $dumpfile("modular_ops_tb.vcd");
        $dumpvars(0, modular_ops_tb);
    end
    
    // 调试监控（可以注释掉）
    /*
    always @(posedge clk) begin
        if (!reset && a != 0 && b != 0)
            $display("Time=%0t: a=%d, b=%d -> add=%d, sub=%d, mul=%d", 
                     $time, a, b, add_result, sub_result, mul_result);
    end
    */
    
endmodule