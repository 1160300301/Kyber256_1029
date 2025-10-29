module Butterfly_Unit (
    input clk,
    input reset,
    
    // 控制信号
    input [1:0] operation,  // 00: NTT, 01: INTT
    input valid_in,
    
    // 数据输入
    input [11:0] a_in,
    input [11:0] b_in,
    input [11:0] zeta,     // 旋转因子 (twiddle factor)
    
    // 数据输出
    output reg [11:0] a_out,
    output reg [11:0] b_out,
    output reg valid_out
);

    parameter P = 13'd3329;
    
    // 操作类型定义
    localparam OP_NTT  = 2'b00;  // 正向NTT
    localparam OP_INTT = 2'b01;  // 逆向NTT
    
    
    // ==========================================
    // Stage 0: 输入加减法 - 使用 Mod_Add 和 Mod_Sub
    // ==========================================
    
    wire [11:0] add0, sub0;
    
    // 实例化模加法
    Mod_Add mod_add_0 (
        .clk(clk),
        .reset(reset),
        .a(a_in),
        .b(b_in),
        .result(add0)
    );
    
    // 实例化模减法
    Mod_Sub mod_sub_0 (
        .clk(clk),
        .reset(reset),
        .a(a_in),
        .b(b_in),
        .result(sub0)
    );
    
    // ==========================================
    // Stage 1: 寄存输入（模加减已经有1周期延迟）
    // ==========================================
    
    reg [11:0] a_r1, b_r1;
    reg [11:0] zeta_r1;
    reg [1:0] op_r1;
    reg valid_r1;
    
    always @(posedge clk) begin
        if (reset) begin
            a_r1 <= 12'd0;
            b_r1 <= 12'd0;
            zeta_r1 <= 12'd0;
            op_r1 <= 2'b00;
            valid_r1 <= 1'b0;
        end else begin
            a_r1 <= a_in;
            b_r1 <= b_in;
            zeta_r1 <= zeta;
            op_r1 <= operation;
            valid_r1 <= valid_in;
        end
    end
    
    // ==========================================
    // Stage 2-5: 模乘法（4个周期）
    // ==========================================
    
    // 根据操作类型选择乘法输入
    wire [11:0] mul_a, mul_b;
    
    assign mul_a = zeta_r1;
    assign mul_b = (op_r1 == OP_NTT) ? b_r1 : sub0;  // NTT: zeta*b, INTT: zeta*(a-b)
    
    // 模乘法实例
    wire [11:0] mul_result;
    
    Mod_Mul multiplier (
        .clk(clk),
        .reset(reset),
        .a(mul_a),
        .b(mul_b),
        .result(mul_result)  // 4周期后输出
    );
    
    // ==========================================
    // Stage 2-5: 延迟匹配（4个周期）
    // ==========================================
    
    // add0 和 a_r1 需要延迟4个周期以匹配乘法器
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
            // 第1级延迟
            add0_d1 <= add0;
            a_d1 <= a_r1;
            op_d1 <= op_r1;
            valid_d1 <= valid_r1;
            
            // 第2级延迟
            add0_d2 <= add0_d1;
            a_d2 <= a_d1;
            op_d2 <= op_d1;
            valid_d2 <= valid_d1;
            
            // 第3级延迟
            add0_d3 <= add0_d2;
            a_d3 <= a_d2;
            op_d3 <= op_d2;
            valid_d3 <= valid_d2;
            
            // 第4级延迟
            add0_d4 <= add0_d3;
            a_d4 <= a_d3;
            op_d4 <= op_d3;
            valid_d4 <= valid_d3;
        end
    end
    
    // ==========================================
    // Stage 6: 最终计算 - 使用 Mod_Add 和 Mod_Sub
    // ==========================================
    
    wire [11:0] final_add, final_sub;
    
    // 实例化模加法：a + mul_result
    Mod_Add mod_add_final (
        .clk(clk),
        .reset(reset),
        .a(a_d4),
        .b(mul_result),
        .result(final_add)
    );
    
    // 实例化模减法：a - mul_result
    Mod_Sub mod_sub_final (
        .clk(clk),
        .reset(reset),
        .a(a_d4),
        .b(mul_result),
        .result(final_sub)
    );
    
    // ==========================================
    // Stage 7: 输出（模加减又多了1周期延迟）
    // ==========================================
    
    // 需要再延迟1个周期来匹配最终的模加减
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
    
    // 输出逻辑
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
                        // NTT蝶形: a' = a + zeta*b, b' = a - zeta*b
                        a_out <= final_add;
                        b_out <= final_sub;
                    end
                    
                    OP_INTT: begin
                        // INTT蝶形: a' = a + b, b' = zeta*(a-b)
                        // 注意：外部需要在最后统一除以n
                        a_out <= add0_d5;
                        b_out <= mul_result;  // mul_result 已经延迟1周期
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
