
module traffic_light_fsm (
    input  logic       clk,      // System clock
    input  logic       reset,    // Synchronous reset (active-high)
    input  logic       TAORB,    // 1 = traffic on A, 0 = traffic on B
    output logic [1:0] LA,       // Light for Street A (2 bits: G=00, Y=01, R=10)
    output logic [1:0] LB        // Light for Street B (2 bits: G=00, Y=01, R=10)
);

  
    typedef enum logic [1:0] {
        S0 = 2'b00,   // Street A = Green,  Street B = Red
        S1 = 2'b01,   // Street A = Yellow, Street B = Red    (5-cycle hold)
        S2 = 2'b10,   // Street A = Red,    Street B = Green
        S3 = 2'b11    // Street A = Red,    Street B = Yellow  (5-cycle hold)
    } state_t;

  
    state_t current_state, next_state;
    logic [2:0] timer;    // 3-bit counter: counts 0,1,2,3,4,5

  
    localparam logic [1:0] GREEN  = 2'b00;
    localparam logic [1:0] YELLOW = 2'b01;
    localparam logic [1:0] RED    = 2'b10;


	 // This always_ff block is the ONLY sequential (clocked) logic in the FSM.
    // On every rising clock edge:

    always_ff @(posedge clk) begin
        if (reset) begin
            current_state <= S0;      // Default: Street A gets green
            timer         <= 3'b000;  // Timer starts at zero
        end
        else begin
            current_state <= next_state;

            // Timer logic: increment during yellow states, reset otherwise

            if (next_state == S1 || next_state == S3) begin
                // If we're STAYING in a yellow state, keep counting
                if (current_state == next_state)
                    timer <= timer + 1;
                else
                    // If ENTERING a yellow state transition start at 0
                    timer <= 3'b000;
            end
            else begin
                // In nonyellow states, timer is not needed reset it
                timer <= 3'b000;
            end
        end
    end


    // always_comb tells the synthesis tool This is purely combinational.
    // There should be NO latches here

    
    always_comb begin
        // Default: stay in current state
        next_state = current_state;

        case (current_state)
            S0: begin
                // Street A is Green, Street B is Red.
                // We stay here as long as TAORB = 1 (traffic on A).
                // When TAORB goes to 0, move to S1.
                if (~TAORB)
                    next_state = S1;   // Start yellow transition for A
                // else: stay in S0
            end

            S1: begin
                // Street A is Yellow, Street B is Red.
                // We MUST stay here for 5 clock cycles regardless of TAORB.
                if (timer == 3'd5)
                    next_state = S2;   // Yellow done, give green to B
                // else: stay in S1 
            end

            S2: begin
                // Street A is Red, Street B is Green.
                // We stay here while TAORB = 0 (traffic on B).
                // When TAORB = 1 traffic returns to A, move to S3.
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


    // Since this is a MOORE machine, outputs depend ONLY on the current state.

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
