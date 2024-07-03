module muntjac_metadata_table # ()(
  // input logic clk_i,
  // input logic rst_ni,

	// Input state and event for table read
  input logic valid_i,
  input logic [7:0] state_i,
  input logic [3:0] event_i,

	// Output state from table read
  output logic [7:0] state_o
);

  bit [7:0] state_table [0:3][0:3] = 
      '{
          '{8'd0, 8'd1, 8'd2, 8'd3},
          '{8'd0, 8'd1, 8'd2, 8'd3},
          '{8'd1, 8'd1, 8'd2, 8'd3},
          '{8'd0, 8'd2, 8'd2, 8'd3}
      };
    
  assign state_o = (valid_i ? state_table[event_i][state_i] : state_i);

endmodule