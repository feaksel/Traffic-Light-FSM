# Traffic Light Controller FSM

A 4-state Finite State Machine (FSM) implementation in SystemVerilog for a two-street traffic light controller with timed yellow light delays.

## Description

- **S0**: Street A Green, Street B Red
- **S1**: Street A Yellow, Street B Red (5-cycle delay)
- **S2**: Street A Red, Street B Green
- **S3**: Street A Red, Street B Yellow (5-cycle delay)

Transitions are controlled by the `TAORB` input signal and an internal timer for yellow states.

## Files

- `traffic_light_fsm.sv` — FSM design module
- `tb_traffic_light_fsm.sv` — Testbench

## Tools

- Intel Quartus Prime
- QuestaSim / ModelSim
