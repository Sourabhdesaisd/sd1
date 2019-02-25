// ======================================================
// btb_file.v  (BTB Storage Arrays: TAG, VALID, TARGET,
//              2-bit STATE predictor, and LRU bit)
// ======================================================
module btb_file #(
    parameter SETS = 8,
    parameter WAYS = 2,
    parameter TAGW = 27
)(
    input                   clk,
    input                   rst,

    // --- READ PORT --------
    input  [2:0]            rd_set,
   // input  [0:0]            rd_way0,   
    output                  rd_valid0,
    output [TAGW-1:0]       rd_tag0,
    output [31:0]           rd_target0,
    output [1:0]            rd_state0,

   // input  [0:0]            rd_way1,
    output                  rd_valid1,
    output [TAGW-1:0]       rd_tag1,
    output [31:0]           rd_target1,
    output [1:0]            rd_state1,

    // --- WRITE PORT --------
    input                   wr_en,
    input  [2:0]            wr_set,
    input                   wr_way,     // 0 or 1
    input                   wr_valid,
    input  [TAGW-1:0]       wr_tag,
    input  [31:0]           wr_target,
    input  [1:0]            wr_state,

    // LRU
    output                  rd_lru,
    input                   wr_lru_en,
    input                   wr_lru_val
);

    // ================= Arrays =================
    reg                valid_arr  [SETS-1:0][WAYS-1:0];
    reg [TAGW-1:0]     tag_arr    [SETS-1:0][WAYS-1:0];
    reg [31:0]         target_arr [SETS-1:0][WAYS-1:0];
    reg [1:0]          state_arr  [SETS-1:0][WAYS-1:0];
    reg                lru        [SETS-1:0];

    // ============= READ ACCESS =============
    assign rd_valid0  = valid_arr[rd_set][0];
    assign rd_tag0    = tag_arr[rd_set][0];
    assign rd_target0 = target_arr[rd_set][0];
    assign rd_state0  = state_arr[rd_set][0];

    assign rd_valid1  = valid_arr[rd_set][1];
    assign rd_tag1    = tag_arr[rd_set][1];
    assign rd_target1 = target_arr[rd_set][1];
    assign rd_state1  = state_arr[rd_set][1];

    assign rd_lru     = lru[rd_set];

    // ============= WRITE ACCESS =============
    integer i,j;
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            for (i=0; i<SETS; i=i+1) begin
                lru[i] <= 1'b0;
                for (j=0; j<WAYS; j=j+1) begin
                    valid_arr[i][j]  <= 1'b0;
                    tag_arr[i][j]    <= {TAGW{1'b0}};
                    target_arr[i][j] <= 32'b0;
                    state_arr[i][j]  <= 2'b01;   // weakly not taken
                end
            end
        end
        else begin
            if (wr_en) begin
                valid_arr [wr_set][wr_way] <= wr_valid;
                tag_arr   [wr_set][wr_way] <= wr_tag;
                target_arr[wr_set][wr_way] <= wr_target;
                state_arr [wr_set][wr_way] <= wr_state;
            end

            if (wr_lru_en)
                lru[wr_set] <= wr_lru_val;
        end
    end

endmodule

/*
// ======================================================
// btb_file.v
// 2-way Set-Associative BTB storage
// - Zero-cycle combinational read
// - Registered write path
// - Superlint-clean (JasperGold 2019.12)
// ======================================================

module btb_file #(
    parameter SETS = 8,
    parameter WAYS = 2,
    parameter TAGW = 27
)(
    input              clk,
    input              rst,

    // ---------------- READ PORT ----------------
    input      [2:0]   rd_set,

    output             rd_valid0,
    output     [TAGW-1:0] rd_tag0,
    output     [31:0]  rd_target0,
    output     [1:0]   rd_state0,

    output             rd_valid1,
    output     [TAGW-1:0] rd_tag1,
    output     [31:0]  rd_target1,
    output     [1:0]   rd_state1,

    output             rd_lru,

    // ---------------- WRITE PORT ----------------
    input              wr_en,
    input      [2:0]   wr_set,
    input              wr_way,       // 0 or 1
    input              wr_valid,
    input      [TAGW-1:0] wr_tag,
    input      [31:0]  wr_target,
    input      [1:0]   wr_state,

    input              wr_lru_en,
    input              wr_lru_val
);

    // ======================================================
    // Internal registered indices (2-state safe)
    // ======================================================
    reg [2:0] r_wr_set;
    reg       r_wr_way;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            r_wr_set <= 3'b000;
            r_wr_way <= 1'b0;
        end else begin
            r_wr_set <= wr_set;
            r_wr_way <= wr_way;
        end
    end

    // ======================================================
    // Arrays (descending ranges ? lint clean)
    // ======================================================
    reg               valid_arr  [SETS-1:0][WAYS-1:0];
    reg [TAGW-1:0]    tag_arr    [SETS-1:0][WAYS-1:0];
    reg [31:0]        target_arr [SETS-1:0][WAYS-1:0];
    reg [1:0]         state_arr  [SETS-1:0][WAYS-1:0];
    reg               lru        [SETS-1:0];

    integer i, j;

    // ======================================================
    // READ ACCESS (combinational, zero-cycle)
    // ======================================================
    assign rd_valid0  = valid_arr[rd_set][0];
    assign rd_tag0    = tag_arr[rd_set][0];
    assign rd_target0 = target_arr[rd_set][0];
    assign rd_state0  = state_arr[rd_set][0];

    assign rd_valid1  = valid_arr[rd_set][1];
    assign rd_tag1    = tag_arr[rd_set][1];
    assign rd_target1 = target_arr[rd_set][1];
    assign rd_state1  = state_arr[rd_set][1];

    assign rd_lru     = lru[rd_set];

    // ======================================================
    // WRITE ACCESS (registered)
    // ======================================================
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            for (i = 0; i < SETS; i = i + 1) begin
                lru[i] <= 1'b0;
                for (j = 0; j < WAYS; j = j + 1) begin
                    valid_arr[i][j]  <= 1'b0;
                    tag_arr[i][j]    <= {TAGW{1'b0}};
                    target_arr[i][j] <= 32'b0;
                    state_arr[i][j]  <= 2'b01; // weakly not taken
                end
            end
        end else begin
            if (wr_en) begin
                valid_arr [r_wr_set][r_wr_way] <= wr_valid;
                tag_arr   [r_wr_set][r_wr_way] <= wr_tag;
                target_arr[r_wr_set][r_wr_way] <= wr_target;
                state_arr [r_wr_set][r_wr_way] <= wr_state;
            end

            if (wr_lru_en) begin
                lru[r_wr_set] <= wr_lru_val;
            end
        end
    end

endmodule
*/
/*
// ======================================================
// btb_file.v ggod
// 2-way Set-Associative BTB storage
// Zero-cycle read, registered write
// ======================================================

module btb_file #(
    parameter SETS = 8,
    parameter WAYS = 2,
    parameter TAGW = 27
)(
    input              clk,
    input              rst,

    // READ
    input      [2:0]   rd_set,

    output             rd_valid0,
    output     [TAGW-1:0] rd_tag0,
    output     [31:0]  rd_target0,
    output     [1:0]   rd_state0,

    output             rd_valid1,
    output     [TAGW-1:0] rd_tag1,
    output     [31:0]  rd_target1,
    output     [1:0]   rd_state1,

    output             rd_lru,

    // WRITE
    input              wr_en,
    input      [2:0]   wr_set,
    input              wr_way,
    input              wr_valid,
    input      [TAGW-1:0] wr_tag,
    input      [31:0]  wr_target,
    input      [1:0]   wr_state,

    input              wr_lru_en,
    input              wr_lru_val
);

    // Arrays
    reg               valid_arr  [SETS-1:0][WAYS-1:0];
    reg [TAGW-1:0]    tag_arr    [SETS-1:0][WAYS-1:0];
    reg [31:0]        target_arr [SETS-1:0][WAYS-1:0];
    reg [1:0]         state_arr  [SETS-1:0][WAYS-1:0];
    reg               lru        [SETS-1:0];

    integer i, j;

    // ---------------- READ (combinational) ----------------
    assign rd_valid0  = valid_arr[rd_set][0];
    assign rd_tag0    = tag_arr[rd_set][0];
    assign rd_target0 = target_arr[rd_set][0];
    assign rd_state0  = state_arr[rd_set][0];

    assign rd_valid1  = valid_arr[rd_set][1];
    assign rd_tag1    = tag_arr[rd_set][1];
    assign rd_target1 = target_arr[rd_set][1];
    assign rd_state1  = state_arr[rd_set][1];

    assign rd_lru     = lru[rd_set];

    // ---------------- WRITE (registered) ----------------
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            for (i = 0; i < SETS; i = i + 1) begin
                lru[i] <= 1'b0;
                for (j = 0; j < WAYS; j = j + 1) begin
                    valid_arr[i][j]  <= 1'b0;
                    tag_arr[i][j]    <= {TAGW{1'b0}};
                    target_arr[i][j] <= 32'b0;
                    state_arr[i][j]  <= 2'b01;
                end
            end
        end else begin
            if (wr_en) begin
                valid_arr [wr_set][wr_way] <= wr_valid;
                tag_arr   [wr_set][wr_way] <= wr_tag;
                target_arr[wr_set][wr_way] <= wr_target;
                state_arr [wr_set][wr_way] <= wr_state;
            end
            if (wr_lru_en) begin
                lru[wr_set] <= wr_lru_val;
            end
        end
    end

endmodule
*/
/*
// ======================================================
// btb_file.v
// 2-way Set-Associative BTB storage
// - Zero-cycle combinational read (architectural)
// - Registered write path
// - Superlint-clean except intentional waivers
// ======================================================

module btb_file #(
    parameter SETS = 8,
    parameter WAYS = 2,
    parameter TAGW = 27
)(
    input              clk,
    input              rst,

    // ---------------- READ PORT ----------------
    input      [2:0]   rd_set,

    output             rd_valid0,
    output     [TAGW-1:0] rd_tag0,
    output     [31:0]  rd_target0,
    output     [1:0]   rd_state0,

    output             rd_valid1,
    output     [TAGW-1:0] rd_tag1,
    output     [31:0]  rd_target1,
    output     [1:0]   rd_state1,

    output             rd_lru,

    // ---------------- WRITE PORT ----------------
    input              wr_en,
    input      [2:0]   wr_set,
    input              wr_way,       // 0 or 1
    input              wr_valid,
    input      [TAGW-1:0] wr_tag,
    input      [31:0]  wr_target,
    input      [1:0]   wr_state,

    input              wr_lru_en,
    input              wr_lru_val
);

    // ======================================================
    // X-safe write index (fixes IDX_NR_DTTY without latency)
    // ======================================================
    wire [2:0] wr_set_safe;
    assign wr_set_safe =
        (wr_set === 3'b000 ||
         wr_set === 3'b001 ||
         wr_set === 3'b010 ||
         wr_set === 3'b011 ||
         wr_set === 3'b100 ||
         wr_set === 3'b101 ||
         wr_set === 3'b110 ||
         wr_set === 3'b111) ? wr_set : 3'b000;

    // ======================================================
    // Arrays (descending ranges ? lint clean)
    // ======================================================
    reg               valid_arr  [SETS-1:0][WAYS-1:0];
    reg [TAGW-1:0]    tag_arr    [SETS-1:0][WAYS-1:0];
    reg [31:0]        target_arr [SETS-1:0][WAYS-1:0];
    reg [1:0]         state_arr  [SETS-1:0][WAYS-1:0];
    reg               lru        [SETS-1:0];

    integer i, j;

    // ======================================================
    // READ ACCESS (ZERO-CYCLE – DO NOT REGISTER)
    // ======================================================
    assign rd_valid0  = valid_arr[rd_set][0];
    assign rd_tag0    = tag_arr[rd_set][0];
    assign rd_target0 = target_arr[rd_set][0];
    assign rd_state0  = state_arr[rd_set][0];

    assign rd_valid1  = valid_arr[rd_set][1];
    assign rd_tag1    = tag_arr[rd_set][1];
    assign rd_target1 = target_arr[rd_set][1];
    assign rd_state1  = state_arr[rd_set][1];

    assign rd_lru     = lru[rd_set];

    // ======================================================
    // WRITE ACCESS (REGISTERED)
    // ======================================================
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            for (i = 0; i < SETS; i = i + 1) begin
                lru[i] <= 1'b0;
                for (j = 0; j < WAYS; j = j + 1) begin
                    valid_arr[i][j]  <= 1'b0;
                    tag_arr[i][j]    <= {TAGW{1'b0}};
                    target_arr[i][j] <= 32'b0;
                    state_arr[i][j]  <= 2'b01; // weakly not taken
                end
            end
        end else begin
            if (wr_en) begin
                valid_arr [wr_set_safe][wr_way] <= wr_valid;
                tag_arr   [wr_set_safe][wr_way] <= wr_tag;
                target_arr[wr_set_safe][wr_way] <= wr_target;
                state_arr [wr_set_safe][wr_way] <= wr_state;
            end

            if (wr_lru_en) begin
                lru[wr_set_safe] <= wr_lru_val;
            end
        end
    end

endmodule
*/
