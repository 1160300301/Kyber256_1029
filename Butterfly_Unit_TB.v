module Butterfly_Unit_TB;

    parameter CLK_PERIOD = 10;
    parameter P = 3329;
    
    reg clk, reset;
    reg [1:0] operation;
    reg valid_in;
    reg [11:0] a_in, b_in, omega;
    wire [11:0] a_out, b_out;
    wire valid_out;
    
    // ʵ�������ε�Ԫ
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
    
    // ʱ������
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end
    
    integer errors = 0;
    
    initial begin
        $display("========================================");
        $display("���ε�Ԫ����");
        $display("���ӳ٣�7������");
        $display("========================================\n");
        
        // ��ʼ��
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
        // ����1: NTT��������
        // ========================================
        $display("\n--- ����1: NTT�������� ---");
        
        test_ntt(100, 200, 17);
        test_ntt(1000, 500, 196);
        test_ntt(3000, 300, 17);
        test_ntt(0, 100, 17);
        test_ntt(3328, 1, 17);
        
        // ========================================
        // ����2: INTT��������
        // ========================================
        $display("\n--- ����2: INTT�������� ---");
        
        test_intt(100, 200, 17);
        test_intt(1000, 500, 196);
        test_intt(171, 29, 17);
        
        // ========================================
        // ����3: �߽����
        // ========================================
        $display("\n--- ����3: �߽���� ---");
        
        test_ntt(3328, 3328, 17);
        test_ntt(4095, 4095, 17);
        
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
    
    // ����NTT
    task test_ntt;
        input [11:0] a, b, w;
        integer expected_a, expected_b;
        integer temp;
        begin
            // ��������ֵ
            temp = (w * b) % P;
            expected_a = (a + temp) % P;
            expected_b = (a >= temp) ? (a - temp) : (P + a - temp);
            
            // ��������
            @(posedge clk);
            operation = 2'b00;  // NTT
            valid_in = 1;
            a_in = a;
            b_in = b;
            omega = w;
            
            @(posedge clk);
            valid_in = 0;
            
            // �ȴ������7�����ڣ�
            wait(valid_out);
            @(posedge clk);
            
            // ��֤
            $display("  ����: a=%d, b=%d, omega=%d", a, b, w);
            $display("  ���: a'=%d, b'=%d", a_out, b_out);
            $display("  ����: a'=%d, b'=%d", expected_a, expected_b);
            
            if (a_out == expected_a && b_out == expected_b)
                $display("  ? PASS");
            else begin
                $display("  ? FAIL");
                errors = errors + 1;
            end
            
            repeat(3) @(posedge clk);
        end
    endtask
    
    // ����INTT
    task test_intt;
        input [11:0] a, b, w;
        integer expected_a, expected_b;
        integer diff;
        begin
            // INTT: a' = a+b, b' = omega*(a-b)
            expected_a = (a + b) % P;
            diff = (a >= b) ? (a - b) : (P + a - b);
            expected_b = (w * diff) % P;
            
            // ��������
            @(posedge clk);
            operation = 2'b01;  // INTT
            valid_in = 1;
            a_in = a;
            b_in = b;
            omega = w;
            
            @(posedge clk);
            valid_in = 0;
            
            // �ȴ������7�����ڣ�
            wait(valid_out);
            @(posedge clk);
            
            // ��֤
            $display("  ����: a=%d, b=%d, omega=%d", a, b, w);
            $display("  ���: a'=%d, b'=%d", a_out, b_out);
            $display("  ����: a'=%d, b'=%d", expected_a, expected_b);
            
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