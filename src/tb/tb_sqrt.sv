//-------------------------------------------------------------------
// Testbench for sqrt module
//-------------------------------------------------------------------
module tb_sqrt();

//-------------------------------------------------------------------
// Clock and reset
//-------------------------------------------------------------------
bit clk = 0;
always #5 clk <= ~clk;

bit rst = 1;
initial begin
    repeat(3) @(negedge clk);
    rst = 0;
end

//-------------------------------------------------------------------
// DUT
//-------------------------------------------------------------------
`ifndef DIN_W `define DIN_W 32 `endif
localparam DIN_W  = `DIN_W;
localparam DOUT_W = DIN_W / 2 + DIN_W % 2;

logic [DIN_W-1:0]  din = 0;
logic              din_valid = 0;
logic              din_ready;
logic [DOUT_W-1:0] dout;
logic              dout_valid;

sqrt #(
    .DIN_W (DIN_W)
) dut (
    // System
    .clk (clk),
    .rst (rst),
    // Input data
    .din       (din),
    .din_valid (din_valid),
    .din_ready (din_ready),
    // Output data
    .dout       (dout),
    .dout_valid (dout_valid)
);

//-------------------------------------------------------------------
// Testbench body
//-------------------------------------------------------------------
localparam DIN_MIN = 0;
localparam DIN_MAX = (2**DIN_W)/2 - 1;

`ifndef ITER_N `define ITER_N 8 `endif
localparam ITER_N = `ITER_N;

logic [DIN_W-1:0]  stimuli_din [ITER_N];
logic [DOUT_W-1:0] test_dout   [ITER_N];
logic [DOUT_W-1:0] golden_dout [ITER_N];

initial begin : env_init
`ifdef PYMODEL
    $readmemh(`PYMODEL_STIMULI, stimuli_din);
    $readmemh(`PYMODEL_GOLDEN, golden_dout);
`else
    // stimuli mem init
    for (int i=0; i<ITER_N; i=i+1) begin
        stimuli_din[i] = $random();
    end
    // corner cases
    stimuli_din[0] = DIN_MAX;
    stimuli_din[1] = DIN_MIN;

    // golden mem init
    for (int i=0; i<ITER_N; i=i+1) begin
        golden_dout[i] = $floor($sqrt(stimuli_din[i]));
    end
`endif
end

task push_data;
    wait(din_ready);
    @(posedge clk);
    din_valid <= 1'b1;
    for (int i=0; i<ITER_N; i=i+1) begin
        din <= stimuli_din[i];
        @(posedge clk);
        wait(din_ready);
        @(posedge clk);
    end
    wait(dout_valid);
    @(posedge clk);
    din_valid <= 1'b0;
endtask

task pull_data;
    for (int i=0; i<ITER_N; i=i+1) begin
        wait(dout_valid);
        @(posedge clk);
        test_dout[i] = dout;
        @(posedge clk);
    end
endtask

function int verify();
    int err_cnt;
    for (int i=0; i<ITER_N; i=i+1) begin
        if (test_dout[i] !== golden_dout[i]) begin
            err_cnt = err_cnt + 1;
            $display("Error! N=%0d, expected 0x%04x, got 0x%04x!", i, golden_dout[i], test_dout[i]);
        end
    end
    return err_cnt;
endfunction

initial begin : main
    int err_cnt;

    wait(!rst);
    repeat(3) @(posedge clk);

    fork
        push_data();
        pull_data();
    join
    err_cnt = verify();

    if (err_cnt)
        $display("!@# TEST FAILED - %0d ERRORS #@!", err_cnt);
    else
        $display("!@# TEST PASSED #@!");

    repeat(3) @(posedge clk);
    $finish;
end

initial begin : timeout
    #500000000;
    $display("!@# TEST FAILED - TIMEOUT #@!");
    $finish;
end

`ifdef __ICARUS__
initial begin : icarus_dump
    $dumpfile("dump.vcd");
    $dumpvars(0, `TOP_NAME);
end
`endif

endmodule