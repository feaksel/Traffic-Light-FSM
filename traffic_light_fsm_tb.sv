// ============================================================================
// ELE432 - Advanced Digital Design
// Testbench for Traffic Light Controller FSM
// ============================================================================
//
// WHAT IS A TESTBENCH?
// A testbench is a non-synthesizable module that:
//   1. Generates a clock signal
//   2. Drives inputs to the design (stimulus)
//   3. Observes outputs (response)
//   4. Optionally checks correctness automatically
//
// Testbenches use constructs like #delays, initial blocks, and $display
// that don't map to real hardware — they're simulation-only.
// ============================================================================

`timescale 1ns / 1ps   // Time unit = 1ns, precision = 1ps
                        // This means #1 = 1 nanosecond

module traffic_light_fsm_tb;

    // ========================================================================
    // Signal Declarations
    // ========================================================================
    // In a testbench, we declare:
    //   - 'logic' for signals we DRIVE (inputs to DUT)
    //   - 'logic' or 'wire' for signals we OBSERVE (outputs from DUT)
    // DUT = Device Under Test (the module we're testing)
    
    logic       clk;
    logic       reset;
    logic       TAORB;
    logic [1:0] LA;
    logic [1:0] LB;

    // Light encoding (same as in the design, for readability in the testbench)
    localparam logic [1:0] GREEN  = 2'b00;
    localparam logic [1:0] YELLOW = 2'b01;
    localparam logic [1:0] RED    = 2'b10;

    // ========================================================================
    // Instantiate the DUT (Device Under Test)
    // ========================================================================
    // This connects our testbench signals to the actual FSM module.
    // The .port(signal) syntax is called "named port connection" —
    // it's clearer than positional connection because you see which
    // port connects to which signal.
    
    traffic_light_fsm DUT (
        .clk    (clk),
        .reset  (reset),
        .TAORB  (TAORB),
        .LA     (LA),
        .LB     (LB)
    );

    // ========================================================================
    // Clock Generation
    // ========================================================================
    // The clock toggles every 5ns, giving a period of 10ns (100 MHz).
    // This runs forever in the background during simulation.
    //
    // initial begin ... end runs once at time 0.
    // 'forever' creates an infinite loop (simulation-only construct).
    
    initial begin
        clk = 0;
        forever #5 clk = ~clk;   // Toggle every 5ns → 10ns period
    end

    // ========================================================================
    // Helper Function: Convert light encoding to a readable string
    // ========================================================================
    // This makes $display output much easier to read.
    
    function string light_to_str(input logic [1:0] light);
        case (light)
            GREEN:   return "GREEN ";
            YELLOW:  return "YELLOW";
            RED:     return "RED   ";
            default: return "???   ";
        endcase
    endfunction

    // ========================================================================
    // Monitor: Print state on every clock edge
    // ========================================================================
    // $monitor automatically triggers whenever any of its arguments change.
    // We use an always block instead here for more control over formatting.
    
    // Print header at the start
    initial begin
        $display("============================================================");
        $display(" Traffic Light FSM - Simulation Results");
        $display("============================================================");
        $display(" Time  | RST | TAORB | State | Timer | Street A | Street B ");
        $display("-------|-----|-------|-------|-------|----------|----------");
    end

    // Print state after every rising clock edge
    always @(posedge clk) begin
        #1;  // Small delay so we see the updated values after the clock edge
        $display(" %4t  |  %b  |   %b   |  S%0d  |   %0d   | %s | %s",
                 $time, reset, TAORB,
                 DUT.current_state, DUT.timer,
                 light_to_str(LA), light_to_str(LB));
    end

    // ========================================================================
    // Test Stimulus
    // ========================================================================
    // This is the actual test scenario. We drive inputs and wait for
    // the FSM to respond. The sequence tests:
    //   1. Reset behavior
    //   2. S0 → S1 transition (TAORB goes low)
    //   3. S1 yellow hold for 5 cycles
    //   4. S2 → S3 transition (TAORB goes high)
    //   5. S3 yellow hold for 5 cycles
    //   6. Return to S0
    
    initial begin
        // ---- Initialize ----
        reset = 1;
        TAORB = 1;       // Start with traffic on Street A
        
        // ---- Apply reset for 2 clock cycles ----
        // Why 2 cycles? One cycle to register the reset, one to confirm.
        @(posedge clk);  // Wait for rising edge (cycle 1)
        @(posedge clk);  // Wait for rising edge (cycle 2)
        reset = 0;       // Release reset
        
        $display("-------|-----|-------|-------|-------|----------|----------");
        $display(" >>> Reset released. FSM should be in S0 (A=GREEN, B=RED)");
        $display("-------|-----|-------|-------|-------|----------|----------");

        // ---- TEST 1: Stay in S0 while TAORB = 1 ----
        // Traffic is present on Street A, so A keeps green.
        repeat(3) @(posedge clk);  // Stay for 3 cycles
        
        // ---- TEST 2: Trigger transition S0 → S1 ----
        // Traffic moves to Street B (TAORB = 0)
        $display("-------|-----|-------|-------|-------|----------|----------");
        $display(" >>> Setting TAORB = 0 (traffic moves to Street B)");
        $display("-------|-----|-------|-------|-------|----------|----------");
        TAORB = 0;

        // ---- TEST 3: S1 holds for 5 cycles (yellow delay) ----
        // The FSM should stay in S1 for 5 clock cycles, then go to S2.
        repeat(7) @(posedge clk);  // Wait enough cycles to see the full transition
        
        // ---- TEST 4: Stay in S2 while TAORB = 0 ----
        // Street B has green, traffic is on B.
        repeat(3) @(posedge clk);  // Stay for 3 cycles

        // ---- TEST 5: Trigger transition S2 → S3 ----
        // Traffic returns to Street A (TAORB = 1)
        $display("-------|-----|-------|-------|-------|----------|----------");
        $display(" >>> Setting TAORB = 1 (traffic returns to Street A)");
        $display("-------|-----|-------|-------|-------|----------|----------");
        TAORB = 1;

        // ---- TEST 6: S3 holds for 5 cycles (yellow delay) ----
        repeat(7) @(posedge clk);  // Wait for full transition
        
        // ---- TEST 7: Verify return to S0 ----
        repeat(3) @(posedge clk);

        // ---- TEST 8: One more full cycle to confirm repeatable behavior ----
        $display("-------|-----|-------|-------|-------|----------|----------");
        $display(" >>> Full cycle test: TAORB = 0 again");
        $display("-------|-----|-------|-------|-------|----------|----------");
        TAORB = 0;
        repeat(10) @(posedge clk);
        
        TAORB = 1;
        repeat(10) @(posedge clk);

        // ---- End simulation ----
        $display("============================================================");
        $display(" Simulation Complete!");
        $display("============================================================");
        $finish;
    end

endmodule
