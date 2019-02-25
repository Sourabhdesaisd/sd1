/*module btb_write #(
    parameter TAGW = 27
)(
    input  wire clk,
    input  wire rst,
    input  wire update_en,
    input  wire [31:0] update_pc,
    input  wire actual_taken,
    input  wire [31:0] update_target,

    // read info for hit detection
    input  wire rd_valid0_upd,
    input  wire [TAGW-1:0] rd_tag0_upd,
    input  wire rd_valid1_upd,
    input  wire [TAGW-1:0] rd_tag1_upd,
    input  wire rd_lru_upd,

    // write commands to btb_file
    output reg         wr_en,
    output reg  [2:0]  wr_set,
    output reg         wr_way,
    output reg         wr_valid,
    output reg  [TAGW-1:0] wr_tag,
    output reg  [31:0] wr_target,
    output reg  [1:0]  wr_state,

    // LRU
    output reg         wr_lru_en,
    output reg         wr_lru_val,

    // predictor input/output
    input  wire [1:0]  state0_in,
    input  wire [1:0]  state1_in,
    output wire [1:0]  next_state0,
    output wire [1:0]  next_state1
);

    wire [2:0] upd_set = update_pc[4:2];
    wire [TAGW-1:0] upd_tag = update_pc[31:5];

    // predictor logic
    dynamic_branch_predictor dp0(state0_in, actual_taken, next_state0);
    dynamic_branch_predictor dp1(state1_in, actual_taken, next_state1);

    wire hit0 = rd_valid0_upd && (rd_tag0_upd == upd_tag);
    wire hit1 = rd_valid1_upd && (rd_tag1_upd == upd_tag);

    always @( upd_tag or next_state0 or next_state1 or actual_taken or update_target or update_target or update_en or hit0 or hit1 or rd_valid0_upd or rd_valid1_upd or rd_lru_upd or upd_set) begin
        wr_en      = 0;
        wr_lru_en  = 0;

        if (!update_en) begin
            wr_valid = 0;
            wr_set   = 0;
            wr_way   = 0;
            wr_tag   = 0;
            wr_target= 0;
            wr_state = 0;
            wr_lru_val = 0;
        end
        else begin
            wr_set = upd_set;

            if (hit0) begin 
                wr_way   = 0;
                wr_en    = 1;
                wr_valid = 1;
                wr_tag   = upd_tag;
                wr_state = next_state0;
                wr_target= actual_taken ? update_target : update_target;
                wr_lru_en = 1;
                wr_lru_val = 1;

            end else if (hit1) begin
                wr_way   = 1;
                wr_en    = 1;
                wr_valid = 1;
                wr_tag   = upd_tag;
                wr_state = next_state1;
                wr_target= actual_taken ? update_target : update_target;
                wr_lru_en = 1;
                wr_lru_val = 0;

            end else begin
                wr_en    = 1;
                wr_valid = 1;
                wr_tag   = upd_tag;
                wr_state = actual_taken ? 2'b10 : 2'b01;
                wr_target= update_target;
                wr_lru_en = 1;

                if (!rd_valid0_upd) begin
                    wr_way = 0;
                    wr_lru_val = 1;
                end else if (!rd_valid1_upd) begin
                    wr_way = 1;
                    wr_lru_val = 0;
                end else if (rd_lru_upd == 0) begin
                    wr_way = 0;
                    wr_lru_val = 1;
                end else begin
                    wr_way = 1;
                    wr_lru_val = 0;
                end
            end
        end
    end
endmodule
*/

// ======================================================
// btb_write.v
// BTB update logic with 2-bit predictor integration
// Superlint-clean (JasperGold 2019.12)
// ======================================================

module btb_write #(
    parameter TAGW = 27
)(
    input  wire clk,
    input  wire rst,
    // ---------------- UPDATE ----------------
    input              update_en,
    input      [29:0]  update_pc,
    input              actual_taken,
    input      [31:0]  update_target,

    // ---------------- READ (for hit detect) ----------------
    input              rd_valid0_upd,
    input      [TAGW-1:0] rd_tag0_upd,
    input              rd_valid1_upd,
    input      [TAGW-1:0] rd_tag1_upd,
    input              rd_lru_upd,

    // ---------------- WRITE to BTB FILE ----------------
    output reg         wr_en,
    output reg  [2:0]  wr_set,
    output reg         wr_way,
    output reg         wr_valid,
    output reg  [TAGW-1:0] wr_tag,
    output reg  [31:0] wr_target,
    output reg  [1:0]  wr_state,

    // ---------------- LRU ----------------
    output reg         wr_lru_en,
    output reg         wr_lru_val,

   // ---------------- PREDICTOR ----------------
    input      [1:0]   state0_in,
    input      [1:0]   state1_in
  //  output     [1:0]   next_state0,
  //  output     [1:0]   next_state1
);

    // --------------------------------------------------
    // PC decode
    // --------------------------------------------------
    wire [2:0]        upd_set;
    wire [TAGW-1:0]   upd_tag;

    assign upd_set = update_pc[2:0];
    assign upd_tag = update_pc[29:3];

    // --------------------------------------------------
    // Predictor next-state wires
    // --------------------------------------------------
    wire [1:0] next_state0;
    wire [1:0] next_state1;

    //assign next_state0 = next_state0_int;
    //assign next_state1 = next_state1_int;

    // --------------------------------------------------
    // Predictor instances (pure combinational)
    // --------------------------------------------------
   dynamic_branch_predictor dp0 (
    .clk          (clk),
    .rst          (rst),
    .update_en    (update_en),
    .curr_state   (state0_in),
    .actual_taken (actual_taken),
    .next_state   (next_state0)
);

dynamic_branch_predictor dp1 (
    .clk          (clk),
    .rst          (rst),
    .update_en    (update_en),
    .curr_state   (state1_in),
    .actual_taken (actual_taken),
    .next_state   (next_state1)
);
	

    // --------------------------------------------------
    // Hit detection
    // --------------------------------------------------
    wire hit0;
    wire hit1;

    assign hit0 = rd_valid0_upd && (rd_tag0_upd ==update_pc[29:3]);
    assign hit1 = rd_valid1_upd && (rd_tag1_upd == update_pc[29:3]);

    // --------------------------------------------------
    // Write / Replace Logic (COMBINATIONAL)
    // --------------------------------------------------
    always @( update_en
           or upd_set
           or upd_tag
           or actual_taken
           or update_target
           or rd_valid0_upd
           or rd_valid1_upd
           or rd_lru_upd
           or hit0
           or hit1
           or next_state0
           or next_state1
    )
    begin
        // ---------------- DEFAULTS (NO LATCH) ----------------
        wr_en       = 1'b0;
        wr_set      = 3'd0;
        wr_way      = 1'b0;
        wr_valid    = 1'b0;
        wr_tag      = {TAGW{1'b0}};
        wr_target   = 32'd0;
        wr_state    = 2'd0;
        wr_lru_en   = 1'b0;
        wr_lru_val  = 1'b0;

        if (update_en) begin
            wr_set = upd_set;

            // ---------- HIT WAY 0 ----------
            if (hit0) begin
                wr_en       = 1'b1;
                wr_way      = 1'b0;
                wr_valid    = 1'b1;
                wr_tag      = upd_tag;
                wr_state    = next_state0;
                wr_target   = update_target;
                wr_lru_en   = 1'b1;
                wr_lru_val  = 1'b1;
            end

            // ---------- HIT WAY 1 ----------
            else if (hit1) begin
                wr_en       = 1'b1;
                wr_way      = 1'b1;
                wr_valid    = 1'b1;
                wr_tag      = upd_tag;
                wr_state    = next_state1;
                wr_target   = update_target;
                wr_lru_en   = 1'b1;
                wr_lru_val  = 1'b0;
            end

            // ---------- MISS ----------
            else begin
                wr_en       = 1'b1;
                wr_valid    = 1'b1;
                wr_tag      = upd_tag;
                wr_state    = actual_taken ? 2'b10 : 2'b01;
                wr_target   = update_target;
                wr_lru_en   = 1'b1;

                // Replacement decision
                if (!rd_valid0_upd) begin
                    wr_way     = 1'b0;
                    wr_lru_val = 1'b1;
                end
                else if (!rd_valid1_upd) begin
                    wr_way     = 1'b1;
                    wr_lru_val = 1'b0;
                end
                else if (rd_lru_upd == 1'b0) begin
                    wr_way     = 1'b0;
                    wr_lru_val = 1'b1;
                end
                else begin
                    wr_way     = 1'b1;
                    wr_lru_val = 1'b0;
                end
            end
        end
    end

endmodule




