module Butterfly_Unit (
    input clk,
    input reset,
    
    // �����ź�
    input [1:0] operation,  // 00: NTT, 01: INTT, 10: PWM
    input valid_in,
    
    // ��������
    input [11:0] a_in,
    input [11:0] b_in,
    input [11:0] omega,     // ��ת���� (twiddle factor)
    
    // �������
    output reg [11:0] a_out,
    output reg [11:0] b_out,
    output reg valid_out
);

    parameter P = 13'd3329;
    
    // �������Ͷ���
    localparam OP_NTT  = 2'b00;  // ����NTT
    localparam OP_INTT = 2'b01;  // ����NTT
    localparam OP_PWM  = 2'b10;  // ��� (Pointwise Multiplication)
    
    // ==========================================
    // Stage 0: ����Ӽ��� - ʹ�� Mod_Add �� Mod_Sub
    // ==========================================
    
    wire [11:0] add0, sub0;
    
    // ʵ����ģ�ӷ�
    Mod_Add mod_add_0 (
        .clk(clk),
        .reset(reset),
        .a(a_in),
        .b(b_in),
        .result(add0)
    );
    
    // ʵ����ģ����
    Mod_Sub mod_sub_0 (
        .clk(clk),
        .reset(reset),
        .a(a_in),
        .b(b_in),
        .result(sub0)
    );
    
    // ==========================================
    // Stage 1: �Ĵ����루ģ�Ӽ��Ѿ���1�����ӳ٣�
    // ==========================================
    
    reg [11:0] a_r1, b_r1;
    reg [11:0] omega_r1;
    reg [1:0] op_r1;
    reg valid_r1;
    
    always @(posedge clk) begin
        if (reset) begin
            a_r1 <= 12'd0;
            b_r1 <= 12'd0;
            omega_r1 <= 12'd0;
            op_r1 <= 2'b00;
            valid_r1 <= 1'b0;
        end else begin
            a_r1 <= a_in;
            b_r1 <= b_in;
            omega_r1 <= omega;
            op_r1 <= operation;
            valid_r1 <= valid_in;
        end
    end
    
    // ==========================================
    // Stage 2-5: ģ�˷���4�����ڣ�
    // ==========================================
    
    // ���ݲ�������ѡ��˷�����
    wire [11:0] mul_a, mul_b;
    
    assign mul_a = omega_r1;
    assign mul_b = (op_r1 == OP_NTT) ? b_r1 : sub0;  // NTT: omega*b, INTT: omega*(a-b)
    
    // ģ�˷�ʵ��
    wire [11:0] mul_result;
    
    Mod_Mul multiplier (
        .clk(clk),
        .reset(reset),
        .a(mul_a),
        .b(mul_b),
        .result(mul_result)  // 4���ں����
    );
    
    // ==========================================
    // Stage 2-5: �ӳ�ƥ�䣨4�����ڣ�
    // ==========================================
    
    // add0 �� a_r1 ��Ҫ�ӳ�4��������ƥ��˷���
    reg [11:0] add0_d1, add0_d2, add0_d3, add0_d4;
    reg [11:0] a_d1, a_d2, a_d3, a_d4;
    reg [1:0] op_d1, op_d2, op_d3, op_d4;
    reg valid_d1, valid_d2, valid_d3, valid_d4;
    
    always @(posedge clk) begin
        if (reset) begin
            add0_d1 <= 12'd0; add0_d2 <= 12'd0; add0_d3 <= 12'd0; add0_d4 <= 12'd0;
            a_d1 <= 12'd0; a_d2 <= 12'd0; a_d3 <= 12'd0; a_d4 <= 12'd0;
            op_d1 <= 2'b00; op_d2 <= 2'b00; op_d3 <= 2'b00; op_d4 <= 2'b00;
            valid_d1 <= 1'b0; valid_d2 <= 1'b0; valid_d3 <= 1'b0; valid_d4 <= 1'b0;
        end else begin
            // ��1���ӳ�
            add0_d1 <= add0;
            a_d1 <= a_r1;
            op_d1 <= op_r1;
            valid_d1 <= valid_r1;
            
            // ��2���ӳ�
            add0_d2 <= add0_d1;
            a_d2 <= a_d1;
            op_d2 <= op_d1;
            valid_d2 <= valid_d1;
            
            // ��3���ӳ�
            add0_d3 <= add0_d2;
            a_d3 <= a_d2;
            op_d3 <= op_d2;
            valid_d3 <= valid_d2;
            
            // ��4���ӳ�
            add0_d4 <= add0_d3;
            a_d4 <= a_d3;
            op_d4 <= op_d3;
            valid_d4 <= valid_d3;
        end
    end
    
    // ==========================================
    // Stage 6: ���ռ��� - ʹ�� Mod_Add �� Mod_Sub
    // ==========================================
    
    wire [11:0] final_add, final_sub;
    
    // ʵ����ģ�ӷ���a + mul_result
    Mod_Add mod_add_final (
        .clk(clk),
        .reset(reset),
        .a(a_d4),
        .b(mul_result),
        .result(final_add)
    );
    
    // ʵ����ģ������a - mul_result
    Mod_Sub mod_sub_final (
        .clk(clk),
        .reset(reset),
        .a(a_d4),
        .b(mul_result),
        .result(final_sub)
    );
    
    // ==========================================
    // Stage 7: �����ģ�Ӽ��ֶ���1�����ӳ٣�
    // ==========================================
    
    // ��Ҫ���ӳ�1��������ƥ�����յ�ģ�Ӽ�
    reg [11:0] add0_d5;
    reg [1:0] op_d5;
    reg valid_d5;
    
    always @(posedge clk) begin
        if (reset) begin
            add0_d5 <= 12'd0;
            op_d5 <= 2'b00;
            valid_d5 <= 1'b0;
        end else begin
            add0_d5 <= add0_d4;
            op_d5 <= op_d4;
            valid_d5 <= valid_d4;
        end
    end
    
    // ����߼�
    always @(posedge clk) begin
        if (reset) begin
            a_out <= 12'd0;
            b_out <= 12'd0;
            valid_out <= 1'b0;
        end else begin
            valid_out <= valid_d5;
            
            if (valid_d5) begin
                case (op_d5)
                    OP_NTT: begin
                        // NTT����: a' = a + omega*b, b' = a - omega*b
                        a_out <= final_add;
                        b_out <= final_sub;
                    end
                    
                    OP_INTT: begin
                        // INTT����: a' = a + b, b' = omega*(a-b)
                        // ע�⣺�ⲿ��Ҫ�����ͳһ����n
                        a_out <= add0_d5;
                        b_out <= mul_result;  // mul_result �Ѿ��ӳ�1����
                    end
                    
                    OP_PWM: begin
                        // ��ˣ���NTT��ͬ
                        a_out <= final_add;
                        b_out <= final_sub;
                    end
                    
                    default: begin
                        a_out <= 12'd0;
                        b_out <= 12'd0;
                    end
                endcase
            end
        end
    end
    
endmodule