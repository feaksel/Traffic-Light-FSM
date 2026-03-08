// ELE432 - Traffic Light FSM Testbench
`timescale 1ns / 1ps

module tb_traffic_light_fsm;

    logic       clk;
    logic       reset;
    logic       TAORB;
    logic [1:0] LA;
    logic [1:0] LB;

    // Instantiate the design
    traffic_light_fsm DUT (
        .clk    (clk),
        .reset  (reset),
        .TAORB  (TAORB),
        .LA     (LA),
        .LB     (LB)
    );

    // Clock: 10ns period
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Test scenario
    initial begin
        // Reset
        reset = 1;
        TAORB = 1;
        @(posedge clk);
        @(posedge clk);
        reset = 0;

        // Stay in S0 for a few cycles (A=Green, B=Red)
        repeat(3) @(posedge clk);

        // Trigger S0 -> S1: traffic leaves Street A
        TAORB = 0;

        // Wait for S1 yellow delay (5 cycles) + transition to S2
        repeat(7) @(posedge clk);

        // Stay in S2 for a few cycles (A=Red, B=Green)
        repeat(3) @(posedge clk);

        // Trigger S2 -> S3: traffic returns to Street A
        TAORB = 1;

        // Wait for S3 yellow delay (5 cycles) + transition to S0
        repeat(7) @(posedge clk);

        // Confirm back in S0
        repeat(3) @(posedge clk);

        $stop;
    end

endmodule