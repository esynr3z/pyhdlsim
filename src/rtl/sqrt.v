//==============================================================================
// Square root:
//   result = floor(sqrt(a))
//
// References:
//   "An FPGA Implementation of a Fixed-Point Square Root Operation", Krerk Piromsopa, 2002
//    https://www.researchgate.net/publication/2532597_An_FPGA_Implementation_of_a_Fixed-Point_Square_Root_Operation
//=============================================================================
module sqrt #(
    parameter DIN_W  = 32,
    parameter DOUT_W = DIN_W / 2 + DIN_W % 2 // modulus to support odd width
)(
    // System
    input wire clk,
    input wire rst,
    // Input data
    input  wire [DIN_W-1:0] din,
    input  wire             din_valid,
    output wire             din_ready,
    // Output data
    output wire [DOUT_W-1:0] dout,
    output reg               dout_valid
);

//-----------------------------------------------------------------------------
// Local parameters
//-----------------------------------------------------------------------------
localparam RADICAND_W  = DIN_W + DIN_W % 2; // modulus to support odd width
localparam SOLUTION_W  = DOUT_W;
localparam REMAINDER_W = SOLUTION_W + 2;
localparam ALU_W       = REMAINDER_W;
localparam CALC_CNT_W  = $clog2(SOLUTION_W);

//-----------------------------------------------------------------------------
// Local variables
//-----------------------------------------------------------------------------
reg [RADICAND_W-1:0]  radicand;
reg [SOLUTION_W-1:0]  solution;
reg [REMAINDER_W-1:0] remainder;

wire                 calc_start;
wire                 calc_end;
reg                  calc_busy;
reg [CALC_CNT_W-1:0] calc_cnt;

wire [ALU_W-1:0] alu_res;
wire [ALU_W-1:0] alu_arg0;
wire [ALU_W-1:0] alu_arg1;
wire             alu_addsub;

//-----------------------------------------------------------------------------
// Control
//-----------------------------------------------------------------------------
// Start calculation
assign calc_start = din_valid;

always @(posedge clk or posedge rst) begin
    if (rst)
        calc_busy <= 1'b0;
    else if (calc_end)
        calc_busy <= 1'b0;
    else if (calc_start)
        calc_busy <= 1'b1;
end

assign din_ready = ~calc_busy;

// End calculation
assign calc_end = (calc_cnt == (DOUT_W - 1));

always @(posedge clk or posedge rst) begin
    if (rst)
        calc_cnt <= 0;
    else if (calc_busy)
        calc_cnt <= calc_cnt + 1;
    else if (calc_start)
        calc_cnt <= 0;
end

// Data output
always @(posedge clk or posedge rst) begin
    if (rst)
        dout_valid <= 1'b0;
    else
        dout_valid <= calc_end;
end

assign dout = solution;

//-----------------------------------------------------------------------------
// Calculation
//-----------------------------------------------------------------------------
// Radicand, solution and remainder
always @(posedge clk) begin
    if (rst) begin
        radicand  <= 0;
        solution  <= 0;
        remainder <= 0;
    end else if (calc_busy) begin
        radicand  <= {radicand[(RADICAND_W-2)-1:0], 2'b00};
        solution  <= {solution[(SOLUTION_W-1)-1:0], ~alu_res[ALU_W-1]};
        remainder <= alu_res;
    end else if (calc_start) begin
        radicand  <= din;
        solution  <= 0;
        remainder <= 0;
    end
end

// ALU
assign alu_addsub = remainder[REMAINDER_W-1];
assign alu_arg0 = {solution, remainder[REMAINDER_W-1], 1'b1};
assign alu_arg1 = {remainder[(REMAINDER_W-2)-1:0], radicand[RADICAND_W-1:RADICAND_W-2]};
assign alu_res = alu_addsub ? alu_arg0 + alu_arg1 : alu_arg1 - alu_arg0;

endmodule
