// ============================================================================
// ELE432 - Advanced Digital Design
// Traffic Light Controller FSM with 5-Cycle Yellow Delay
// ============================================================================
//
// ARCHITECTURE OVERVIEW (Three-Block FSM):
//
//   ┌─────────────┐     ┌─────────────┐     ┌─────────────┐
//   │  Next-State  │────▶│    State     │────▶│   Output    │
//   │    Logic     │     │  Register   │     │    Logic    │
//   │ (combo)      │◀────│ (sequential)│     │  (combo)    │
//   └─────────────┘     └─────────────┘     └─────────────┘
//        ▲                                        │
//        │          inputs (TAORB)                 │ outputs (LA, LB)
//        └────────────────────────────────────────┘
//
// This is a Moore FSM: outputs depend ONLY on the current state.
// ============================================================================

module traffic_light_fsm (
    input  logic       clk,      // System clock
    input  logic       reset,    // Synchronous reset (active-high)
    input  logic       TAORB,    // 1 = traffic on A, 0 = traffic on B
    output logic [1:0] LA,       // Light for Street A (2 bits: G=00, Y=01, R=10)
    output logic [1:0] LB        // Light for Street B (2 bits: G=00, Y=01, R=10)
);

    // ========================================================================
    // STEP 1: Define the states using an enumerated type
    // ========================================================================
    // Why use enum? It makes the code readable and lets synthesis tools
    // optimize the encoding (binary, one-hot, etc.) automatically.
    // We use 2 bits since we have 4 states (2^2 = 4).
    
    typedef enum logic [1:0] {
        S0 = 2'b00,   // Street A = Green,  Street B = Red
        S1 = 2'b01,   // Street A = Yellow, Street B = Red    (5-cycle hold)
        S2 = 2'b10,   // Street A = Red,    Street B = Green
        S3 = 2'b11    // Street A = Red,    Street B = Yellow  (5-cycle hold)
    } state_t;

    // ========================================================================
    // STEP 2: Declare state variables and the timer
    // ========================================================================
    // We need two state variables:
    //   - current_state: what state we're in RIGHT NOW (flip-flop output)
    //   - next_state:    what state we WILL be in on the next clock edge
    //
    // The timer is a counter that counts up during yellow states (S1 and S3).
    // We need to count from 0 to 5, so we need 3 bits (2^3 = 8 > 5).
    
    state_t current_state, next_state;
    logic [2:0] timer;    // 3-bit counter: counts 0,1,2,3,4,5

    // ========================================================================
    // Light encoding parameters (for readability)
    // ========================================================================
    // Instead of remembering that 2'b00 means green, we give them names.
    
    localparam logic [1:0] GREEN  = 2'b00;
    localparam logic [1:0] YELLOW = 2'b01;
    localparam logic [1:0] RED    = 2'b10;

    // ========================================================================
    // BLOCK 1: State Register (Sequential Logic)
    // ========================================================================
    // This always_ff block is the ONLY sequential (clocked) logic in the FSM.
    // On every rising clock edge:
    //   - If reset is active, go back to S0 and clear the timer.
    //   - Otherwise, move to the next_state that the combinational logic computed.
    //
    // WHY always_ff? It tells the synthesis tool: "I intend this to be flip-flops."
    // If you accidentally write combinational logic here, the tool warns you.
    
    always_ff @(posedge clk) begin
        if (reset) begin
            current_state <= S0;      // Default: Street A gets green
            timer         <= 3'b000;  // Timer starts at zero
        end
        else begin
            current_state <= next_state;

            // Timer logic: increment during yellow states, reset otherwise
            // The timer is part of the sequential block because it's a counter
            // (a register that updates every clock cycle).
            if (next_state == S1 || next_state == S3) begin
                // If we're STAYING in a yellow state, keep counting
                if (current_state == next_state)
                    timer <= timer + 1;
                else
                    // If we're ENTERING a yellow state (transition), start at 0
                    timer <= 3'b000;
            end
            else begin
                // In non-yellow states, timer is not needed — reset it
                timer <= 3'b000;
            end
        end
    end

    // ========================================================================
    // BLOCK 2: Next-State Logic (Combinational)
    // ========================================================================
    // This block decides WHERE to go next based on:
    //   - Where we are now (current_state)
    //   - What the inputs are (TAORB, timer)
    //
    // WHY always_comb? It tells the synthesis tool: "This is purely combinational.
    // There should be NO latches here." If you forget a case, the tool warns you.
    //
    // IMPORTANT: always_comb requires that next_state is assigned in ALL paths.
    // That's why we have a default assignment at the top.
    
    always_comb begin
        // Default: stay in current state (prevents accidental latches)
        next_state = current_state;

        case (current_state)
            S0: begin
                // Street A is Green, Street B is Red.
                // We stay here as long as TAORB = 1 (traffic on A).
                // When TAORB goes to 0 (no more traffic on A), move to S1.
                if (~TAORB)
                    next_state = S1;   // Start yellow transition for A
                // else: stay in S0 (handled by default)
            end

            S1: begin
                // Street A is Yellow, Street B is Red.
                // We MUST stay here for 5 clock cycles regardless of TAORB.
                // The timer counts: 0, 1, 2, 3, 4 → when it reaches 5, move on.
                if (timer == 3'd5)
                    next_state = S2;   // Yellow done, give green to B
                // else: stay in S1 (timer keeps counting in Block 1)
            end

            S2: begin
                // Street A is Red, Street B is Green.
                // We stay here while TAORB = 0 (traffic on B).
                // When TAORB = 1 (traffic returns to A), move to S3.
                if (TAORB)
                    next_state = S3;   // Start yellow transition for B
            end

            S3: begin
                // Street A is Red, Street B is Yellow.
                // Same as S1: hold for 5 cycles.
                if (timer == 3'd5)
                    next_state = S0;   // Yellow done, give green back to A
            end

            default: next_state = S0;  // Safety net: if something goes wrong, reset
        endcase
    end

    // ========================================================================
    // BLOCK 3: Output Logic (Combinational)
    // ========================================================================
    // Since this is a MOORE machine, outputs depend ONLY on the current state.
    // This makes the output logic very clean — just a lookup table.
    //
    // Why a separate block? Keeping output logic separate from next-state logic
    // makes the code easier to read, debug, and modify. It also maps directly
    // to the FSM theory you learned in class.
    
    always_comb begin
        // Default outputs (prevents latches)
        LA = RED;
        LB = RED;

        case (current_state)
            S0: begin
                LA = GREEN;   // Street A has the right of way
                LB = RED;
            end

            S1: begin
                LA = YELLOW;  // Street A transitioning
                LB = RED;
            end

            S2: begin
                LA = RED;
                LB = GREEN;   // Street B has the right of way
            end

            S3: begin
                LA = RED;
                LB = YELLOW;  // Street B transitioning
            end

            default: begin
                LA = RED;     // Fail-safe: all red
                LB = RED;
            end
        endcase
    end

endmodule
