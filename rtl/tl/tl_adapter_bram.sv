// An adpater that converts an TL-UL interface to a BRAM interface.
module tl_adapter_bram #(
  parameter  int unsigned DataWidth        = 64,
  parameter  int unsigned BramAddrWidth    = 12,
  localparam int unsigned DataWidthInBytes = DataWidth / 8
) (
  input  logic                        clk_i,
  input  logic                        rst_ni,
  tl_channel.device                   host,

  output logic                        bram_en_o,
  output logic                        bram_we_o,
  output logic [BramAddrWidth-1:0]    bram_addr_o,
  output logic [DataWidthInBytes-1:0] bram_wmask_o,
  output logic [DataWidth-1:0]        bram_wdata_o,
  input  logic [DataWidth-1:0]        bram_rdata_i
);

  import tl_pkg::*;

  localparam NonBurstSize = $clog2(DataWidthInBytes);

  // Static checks of interface matching
  if (host.NumCachedHosts != 0) $fatal(1, "host.NumCachedHosts != 0");
  if (DataWidth != host.DataWidth ||
      NonBurstSize + BramAddrWidth > host.AddrWidth)
    $fatal(1, "AddrWidth or DataWidth mismatch");
  if (host.MaxSize > NonBurstSize) $fatal(1, "Bursts not supported");

  /////////////////////
  // Unused channels //
  /////////////////////

  // We don't use channel B.
  assign host.b_valid = 1'b0;
  assign host.b_opcode = tl_b_op_e'('x);
  assign host.b_param = 'x;
  assign host.b_size = 'x;
  assign host.b_source = 'x;
  assign host.b_address = 'x;
  assign host.b_mask = 'x;
  assign host.b_corrupt = 'x;
  assign host.b_data = 'x;

  // We don't use channel C and E
  assign host.c_ready = 1'b1;
  assign host.e_ready = 1'b1;

  /////////////////////////////////
  // Request channel handshaking //
  /////////////////////////////////

  // We can perform an op if no pending data is to be received on D channel.
  assign host.a_ready = !host.d_valid || host.d_ready;
  wire   do_op        = host.a_valid && host.a_ready;

  ////////////////////////
  // Connection to BRAM //
  ////////////////////////

  assign bram_en_o    = do_op;
  assign bram_we_o    = host.a_opcode != Get;
  assign bram_addr_o  = host.a_address[NonBurstSize +: BramAddrWidth];
  assign bram_wmask_o = host.a_mask;
  assign bram_wdata_o = host.a_data;

  /////////////////////////////
  // Response handling logic //
  /////////////////////////////

  assign host.d_param   = 0;
  assign host.d_sink    = 'x;
  assign host.d_denied  = 1'b0;
  assign host.d_corrupt = 1'b0;
  assign host.d_data    = bram_rdata_i;

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      host.d_valid  <= 1'b0;
      host.d_opcode <= tl_d_op_e'('x);
      host.d_size   <= 'x;
      host.d_source <= 'x;
    end
    else begin
      if (host.d_valid && host.d_ready) begin
        host.d_valid <= 1'b0;
      end
      if (do_op) begin
        host.d_valid  <= 1'b1;
        host.d_opcode <= host.a_opcode != Get ? AccessAck : AccessAckData;
        host.d_size   <= host.a_size;
        host.d_source <= host.a_source;
      end
    end
  end

endmodule
