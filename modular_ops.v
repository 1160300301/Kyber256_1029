module Mod_Add(
    input clk,
    input reset,
    input [11:0] a,
    input [11:0] b,
    output reg [11:0] result
);
    parameter P = 13'd3329;
    
    wire [12:0] sum;
    wire [11:0] sum_mod;
    
    assign sum = a + b;
    assign sum_mod = (sum >= P) ? (sum - P) : sum[11:0];
    
    always @(posedge clk) begin
        if (reset)
            result <= 12'd0;
        else
            result <= sum_mod;
    end
    
endmodule

module Mod_Sub(
    input clk,
    input reset,
    input [11:0] a,
    input [11:0] b,
    output reg [11:0] result
);
    parameter P = 13'd3329;
    
    wire [12:0] diff;
    wire [11:0] diff_mod;
    
    assign diff = (a >= b) ? (a - b) : (P + a - b);
    assign diff_mod = diff[11:0];
    
    always @(posedge clk) begin
        if (reset)
            result <= 12'd0;
        else
            result <= diff_mod;
    end
    
endmodule

module Barrett_Reduce(
    input clk,
    input [23:0] Tbr,
    input reset,
    output reg [11:0] Rmdr
);
    parameter P = 13'd3329;
    parameter MU = 13'd5039;
    
    reg [23:0] Tbr1, Tbr2;
    reg [25:0] tq;
    reg [24:0] tq_mul_p;
    
    // 第一拍
    always @(posedge clk) begin
        if (reset) begin
            tq <= 26'd0;
            Tbr1 <= 24'd0;
        end else begin
            tq <= Tbr[23:11] * MU;
            Tbr1 <= Tbr;
        end
    end
    
    // 第二拍
    always @(posedge clk) begin
        if (reset) begin
            tq_mul_p <= 25'd0;
            Tbr2 <= 24'd0;
        end else begin
            tq_mul_p <= tq[25:13] * P;
            Tbr2 <= Tbr1;
        end
    end
    
    // 第三拍
    wire [24:0] Tbr2_ext;
    wire signed [25:0] r1_signed;
    wire [24:0] r1, r2, r3;
    
    assign Tbr2_ext = {1'b0, Tbr2};
    assign r1_signed = {1'b0, Tbr2_ext} - {1'b0, tq_mul_p};
    
    assign r1 = r1_signed[25] ? (r1_signed + P) : r1_signed[24:0];
    assign r2 = (r1 >= P) ? (r1 - P) : r1;
    assign r3 = (r2 >= P) ? (r2 - P) : r2;
    
    always @(posedge clk) begin
        if (reset)
            Rmdr <= 12'd0;
        else
            Rmdr <= r3[11:0];
    end
    
endmodule

module Mod_Mul(
    input clk,
    input reset,
    input [11:0] a,
    input [11:0] b,
    output wire [11:0] result
);
    parameter P = 13'd3329;
    
    // 第一级：乘法
    reg [23:0] product;
    
    always @(posedge clk) begin
        if (reset)
            product <= 24'd0;
        else
            product <= a * b;
    end
    
    // 第二级到第四级：Barrett约简
    Barrett_Reduce barrett_inst (
        .clk(clk),
        .reset(reset),
        .Tbr(product),
        .Rmdr(result)
    );
    
endmodule
