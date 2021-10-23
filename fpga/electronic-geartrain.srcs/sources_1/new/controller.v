`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer: Seth Sims
//
// Create Date: 10/22/2021 11:01:28 AM
// Design Name:
// Module Name: controller
// Project Name:
// Target Devices:
// Tool Versions:
// Description:
//
// Dependencies:
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////

// 100 MHz clock, 100000 debounce time is 1 ms. I don't know if this is a good
// value for everything. But have to start somewhere.
module controller
#(
  parameter debounce_time = 2
)
(
  input spindle_hall,
  input[1:0] spindexer_quad,
  input[1:0] axis_quad,
  input[1:0] mode,
  input system_clk,
  output step,
  output reg step_direction
);
  wire spindexer_step;
  wire spindexer_direction;
  wire[31:0] spindexer_pos;

  // scale the clock down to 0.1 ms/10 KHz clock
  wire clk;
  clock_divider #(100000) local_clock(system_clk, clk);

  quadrature_decoder #(debounce_time) spindexer_signal(spindexer_quad, clk, spindexer_direction, spindexer_step);
  track_position spindexer_pos_tracker(spindexer_step, spindexer_direction, spindexer_pos);

  // hobbing machine mode, match the stepper speed to the hall speed
  wire db_spindle_signal;
  wire rpm_step;
  debounce #(debounce_time) spindle_signal(spindle_hall, clk, db_spindle_signal);
  rpm_match gear_hob(db_spindle_signal, spindexer_step, clk, rpm_step);

  // helical milling move the stepper with the x-axis
  wire axis_step;
  wire axis_direction;
  wire[31:0] axis_pos;
  quadrature_decoder #(debounce_time) axis_signal(axis_quad, clk, axis_direction, axis_step);
  track_position axis_pos_tracker(axis_step, axis_direction, axis_pos);

  // dividing head, move the head at max speed to specific angles
  wire divider_direction;
  wire divider_step;

  // set the step direction
  always @(*) begin
    case (mode)
      0: step_direction = 1'b0;
      1: step_direction = axis_direction;
      2: step_direction = divider_direction;
      default: step_direction = 1'bz;
    endcase
  end

  // send the step pulse to the stepper controller
  assign out_step = step_select(mode, rpm_step, axis_step, divider_step);
  function step_select;
    input mode, mode0, mode1, mode2;
    case (mode)
      0: step_select = mode0;
      1: step_select = mode1;
      2: step_select = mode2;
      default: step_select = 1'bz;
    endcase
  endfunction

  // hold the pulse for an amount of time
  trigger_pulse #(debounce_time) step_pulse(out_step, clk, step);
endmodule

module clock_divider
#(
  parameter divisor = 1
)
(
  input clock_in,
  output reg clock_out
);
reg[31:0] counter = 0;
always @(posedge clock_in)
begin
  counter = counter + 1;
  if(counter >= (divisor - 1))
    counter = 0;

  clock_out <= (counter < divisor / 2)?1'b1:1'b0;
end
endmodule

// quadrature decoder that includes input debounce.
// Parameters
// ----------
// debounce_time how many cycles of clk to wait
//
// Input Ports
// -----------
// quad_input
//   the two signal lines for the quadrature encoder.
// clk
//   the system clk.
// reset
//   reset the position.
//
// Output Ports
// ------------
// direction
//   The direction indicator
// count
//   The count signal
// position
//   The current position of the axis
module quadrature_decoder
#(
  parameter debounce_time = 100000
)
(
  input[1:0] quad_input,
  input clk,
  output direction,
  output count
);
// debouncing quadrature encoder design from: https://forum.digikey.com/t/quadrature-decoder-vhdl/12671
reg [15:0] db_count = 0;

// delay line to debounce the quadrature encoder and remember the state
reg[1:0] quadA_delayed, quadB_delayed;
reg quadA_prev, quadB_prev;

always @(posedge clk)
begin
  quadA_delayed = {quadA_delayed[0],quad_input[0]};
  quadB_delayed = {quadB_delayed[0],quad_input[1]};
  if((quadA_delayed[0]^quadA_delayed[1])|(quadB_delayed[0]^quadB_delayed[1]))
    db_count <= 0;
  else if(db_count < debounce_time)
    db_count <= db_count+1;

  if(db_count >= debounce_time)
  begin
    quadA_prev = quadA_delayed[1];
    quadB_prev = quadB_delayed[1];
  end
end

assign count = (quadA_delayed[1]^quadA_prev)|(quadB_delayed[1]^quadB_prev);
assign direction = quadA_delayed[1] ^ quadB_prev;
endmodule

// general debouncer for the hall-effect sensor
//
// Parameter
// ---------
// debounce_time
//   How long to delay for debounce
//
// Input Ports
// -----------
// in
//   The signal to be debounced
// clk
//   The system clock to follow
//
// Output Ports
// ------------
// out
//   The debounced signal
module debounce
#(
  parameter debounce_time = 100000
)
(
  input in,
  input clk,
  output out
);
  reg[15:0] db_time = 0;
  reg[1:0] button_delay;
  always @(posedge clk)
  begin
    if(button_delay[0] ^ in)
    begin
      db_time = 0;
      button_delay = {button_delay[0],in};
    end
    else if(db_time <= debounce_time)
      db_time = db_time + 1;
  end
  assign out = (db_time > debounce_time) & ~button_delay[1] & button_delay[0];
endmodule

// A frequency locked loop implementation that sends steps at a fixed
// ratio of the reference step frequency. Needs real tuning the
// parameterization is just a number.
//
// Input Port
// ----------
// reference_clock
//   The slower clock that counts mill spindle rpm.
// feedback_clock
//   The faster clock that tracks the spindexer spindle.
// clk
//   The system clock
//
// Ouput Port
// ----------
// step
//   The step signal for the stepper controller.
module rpm_match
#(
  parameter clock_divider = 120000
)
(
  input reference_clock,
  input feedback_clock,
  input clk,
  output reg step
);
  reg[1:0] feedback_clock_delay = {1'b0,1'b0};
  reg[1:0] reference_clock_delay = {1'b0,1'b0};

  // Count the number of steps from the output clock
  reg[31:0] fll_count = 0;
  reg[31:0] step_delay = 0;
  reg[31:0] slow_clk = 0; // slow clock that sends step signal

  always @(posedge clk)
  begin
    feedback_clock_delay = {feedback_clock_delay[0],feedback_clock};
    reference_clock_delay = {reference_clock_delay[0],reference_clock};
    if(feedback_clock_delay[1] & ~feedback_clock_delay[0])
      fll_count = fll_count + 1;

    if(reference_clock_delay[1] & ~reference_clock_delay[0])
    begin

      // When the reference_clock ticks figure out the error and update the
      // speed based on the error. This is basically a Proportional only PID.
      if(fll_count < clock_divider)
        // Slow the steps down proportional to the error
        step_delay = step_delay + (clock_divider - fll_count) >> 4;
      else
      begin
        // Speed the steps up proportional to the error
        step_delay = step_delay - (fll_count - clock_divider) >> 4;
        fll_count = fll_count - clock_divider;
      end
    end

    slow_clk = slow_clk + 1;
    if(slow_clk >= step_delay)
    begin
      slow_clk = 0;
      step = 1;
    end
    else
      step = 0;
  end
endmodule

// Track the position of an axis followed by a quadrature encoder
//
// Input Ports
// -----------
// step
//   The step signal from the quadrature encoder.
// direction
//   The direction signal from the quadrature encoder.
//
// Output Ports
// ------------
// pos
//   The step counter of the current position.
module track_position
(
  input step,
  input direction,
  output reg[31:0] pos
);
  always @(posedge step)
  begin
    if(direction)
    begin
      pos <= pos + 1;
    end
    else
    begin
      pos <= pos - 1;
    end
  end
endmodule

// Hold a pulse for a time so external hardware can recieve the signal
//
// Parameter
// ---------
// hold_time
//   Number of system clock cycles to hold the pulse for
//
// Input Ports
// -----------
// signal
//   The pulse trigger
// clk
//   The system clock
//
//  Output Ports
//  ------------
//  held_signal
//    The pulse signal
module trigger_pulse
#(
  parameter hold_time = 100000
)
(
  input signal,
  input clk,
  output reg held_signal
);
  reg[31:0] slow_clk = 0;
  always @(posedge clk)
  begin
    slow_clk = slow_clk + 1;
    if(held_signal & (slow_clk > hold_time))
    begin
      held_signal <= 1'b0;
      slow_clk = 0;
    end

    if(~held_signal & signal)
    begin
      held_signal <= 1'b1;
      slow_clk = 0;
    end
  end
endmodule
