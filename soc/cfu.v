// Copyright 2021 The CFU-Playground Authors
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
`define MAX 31
`define MIN 2
`define N   16

module Cfu (
  input               cmd_valid,
  output              cmd_ready,
  input      [9:0]    cmd_payload_function_id,
  input      [31:0]   cmd_payload_inputs_0,
  input      [31:0]   cmd_payload_inputs_1,
  input      [31:0]   cmd_payload_inputs_2,
  output              rsp_valid,
  input               rsp_ready,
  output     [31:0]   rsp_payload_outputs_0,
  input               reset,
  input               clk
);

  // Trivial handshaking for a combinational CFU
  assign rsp_valid = cmd_valid;
  assign cmd_ready = rsp_ready;

  wire cfu_init     = cmd_payload_function_id == 0;
  wire cfu_kernel   = cmd_payload_function_id == 1;
  wire cfu_get_ret  = cmd_payload_function_id == 2;
  wire cfu_get_PC_value = cmd_payload_function_id == 3;

  reg [31:0] a_cdt [0:`MAX]; /* candidates        */
  reg [31:0] a_col [0:`MAX]; /* column            */
  reg [31:0] a_pos [0:`MAX]; /* positive diagonal */
  reg [31:0] a_neg [0:`MAX]; /* negative diagonal */
  
  reg [31:0] reg_h    = 0;       /* height or level  */
  reg [31:0] reg_r    = 0;       /* candidate vector */
  reg [31:0] reg_ret  = 0;       /* return value      */

  integer i;
  initial begin
    for (i = 0; i <= `MAX; i = i + 1) begin
      a_cdt[i] = 0;
      a_col[i] = 0;
      a_pos[i] = 0;
      a_neg[i] = 0;
    end
  end

  wire        w_bool      = ~(reg_r == 0 && reg_h == 1);
  wire [31:0] lsb1        = (~reg_r + 1) & reg_r;

  always @(posedge clk) begin
    if (cmd_valid) begin
      if (cfu_init) begin
        reg_ret   <= 0;
        reg_h     <= 1;
        reg_r     <= 1 << (cmd_payload_inputs_0);
        a_col[1]  <= (1 << `N) - 1;
        a_pos[1]  <= 0;
        a_neg[1]  <= 0;
      end

      else if (cfu_kernel) begin
        if (reg_r) begin
          a_cdt[reg_h+1] <= (          reg_r & ~lsb1);
          a_col[reg_h+1] <= (a_col[reg_h] & ~lsb1);
          a_pos[reg_h+1] <= ((a_pos[reg_h] |  lsb1) << 1);
          a_neg[reg_h+1] <= ((a_neg[reg_h] |  lsb1) >> 1);

          reg_r <= (a_col[reg_h] & ~lsb1) &
                  ~(((a_pos[reg_h] | lsb1) << 1) |
                    ((a_neg[reg_h] | lsb1) >> 1));
          reg_h <= reg_h + 1;
        end else begin
          if (reg_h == `N + 1) reg_ret <= reg_ret + 1;
          reg_r <= a_cdt[reg_h];
          reg_h <= reg_h - 1;
        end
      end
    end
  end
 

  //
  // select output -- note that we're not fully decoding the 3 function_id bits
  //
  assign rsp_payload_outputs_0 = (cfu_init)         ? 0                    :
                                 (cfu_kernel)       ? w_bool               :
                                 (cfu_get_ret)      ? reg_ret              :
                                 (cfu_get_PC_value) ? cmd_payload_inputs_2 : -1;
endmodule