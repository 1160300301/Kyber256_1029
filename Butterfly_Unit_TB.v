module Butterfly_Unit_TB;

    parameter CLK_PERIOD = 10;
    parameter P = 3329;
    
    reg clk, reset;
    reg [1:0] operation;
    reg valid_in;
    reg [11:0] a_in, b_in, omega;
    wire [11:0] a_out, b_out;
    wire valid_out;
    
    // 实例化蝶形单元
    Butterfly_Unit dut (
        .clk(clk),
        .reset(reset),
        .operation(operation),
        .valid_in(valid_in),
        .a_in(a_in),
        .b_in(b_in),
        .omega(omega),
        .a_out(a_out),
        .b_out(b_out),
        .valid_out(valid_out)
    );
    
    // 时钟生成
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end
    
    integer errors = 0;
    
    initial begin
        $display("========================================");
        $display("蝶形单元测试");
        $display("总延迟：7个周期");
        $display("========================================\n");
        
        // 初始化
        reset = 1;
        operation = 2'b00;
        valid_in = 0;
        a_in = 0;
        b_in = 0;
        omega = 0;
        
        repeat(5) @(posedge clk);
        reset = 0;
        @(posedge clk);
        
        // ========================================
        // 测试1: NTT蝶形运算
        // ========================================
        $display("\n--- 测试1: NTT蝶形运算 ---");
        
        test_ntt(100, 200, 17);
        test_ntt(1000, 500, 196);
        test_ntt(3000, 300, 17);
        test_ntt(0, 100, 17);
        test_ntt(3328, 1, 17);
        
        // ========================================
        // 测试2: INTT蝶形运算
        // ========================================
        $display("\n--- 测试2: INTT蝶形运算 ---");
        
        test_intt(100, 200, 17);
        test_intt(1000, 500, 196);
        test_intt(171, 29, 17);
        
        // ========================================
        // 测试3: 边界情况
        // ========================================
        $display("\n--- 测试3: 边界情况 ---");
        
        test_ntt(3328, 3328, 17);
        test_ntt(4095, 4095, 17);
        
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
    
    // 测试NTT
    task test_ntt;
        input [11:0] a, b, w;
        integer expected_a, expected_b;
        integer temp;
        begin
            // 计算期望值
            temp = (w * b) % P;
            expected_a = (a + temp) % P;
            expected_b = (a >= temp) ? (a - temp) : (P + a - temp);
            
            // 发送输入
            @(posedge clk);
            operation = 2'b00;  // NTT
            valid_in = 1;
            a_in = a;
            b_in = b;
            omega = w;
            
            @(posedge clk);
            valid_in = 0;
            
            // 等待结果（7个周期）
            wait(valid_out);
            @(posedge clk);
            
            // 验证
            $display("  输入: a=%d, b=%d, omega=%d", a, b, w);
            $display("  输出: a'=%d, b'=%d", a_out, b_out);
            $display("  期望: a'=%d, b'=%d", expected_a, expected_b);
            
            if (a_out == expected_a && b_out == expected_b)
                $display("  ? PASS");
            else begin
                $display("  ? FAIL");
                errors = errors + 1;
            end
            
            repeat(3) @(posedge clk);
        end
    endtask
    
    // 测试INTT
    task test_intt;
        input [11:0] a, b, w;
        integer expected_a, expected_b;
        integer diff;
        begin
            // INTT: a' = a+b, b' = omega*(a-b)
            expected_a = (a + b) % P;
            diff = (a >= b) ? (a - b) : (P + a - b);
            expected_b = (w * diff) % P;
            
            // 发送输入
            @(posedge clk);
            operation = 2'b01;  // INTT
            valid_in = 1;
            a_in = a;
            b_in = b;
            omega = w;
            
            @(posedge clk);
            valid_in = 0;
            
            // 等待结果（7个周期）
            wait(valid_out);
            @(posedge clk);
            
            // 验证
            $display("  输入: a=%d, b=%d, omega=%d", a, b, w);
            $display("  输出: a'=%d, b'=%d", a_out, b_out);
            $display("  期望: a'=%d, b'=%d", expected_a, expected_b);
            
            if (a_out == expected_a && b_out == expected_b)
                $display("  ? PASS");
            else begin
                $display("  ? FAIL");
                errors = errors + 1;
            end
            
            repeat(3) @(posedge clk);
        end
    endtask
    
    initial begin
        $dumpfile("butterfly_tb.vcd");
        $dumpvars(0, Butterfly_Unit_TB);
    end
    
endmodule