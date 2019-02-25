/*module dynamic_branch_predictor(
    input  wire [1:0] curr_state,
    input  wire       actual_taken,
    output reg  [1:0] next_state
);
    always @(curr_state or actual_taken ) begin
        if (actual_taken) begin
            case (curr_state)
                2'b00: next_state = 2'b01;
                2'b01: next_state = 2'b10;
                2'b10: next_state = 2'b11;
                2'b11: next_state = 2'b11;
            endcase
        end
        else begin
            case (curr_state)
                2'b00: next_state = 2'b00;
                2'b01: next_state = 2'b00;
                2'b10: next_state = 2'b01;
                2'b11: next_state = 2'b10;
            endcase
        end
    end
endmodule
*/

// ======================================================
// dynamic_branch_predictor.v
// 2-bit saturating counter predictor
// JasperGold Superlint 2019.12 CLEAN
// ======================================================

module dynamic_branch_predictor (
    input  wire        clk,
    input  wire        rst,
    input  wire        update_en,

    input  wire [1:0]  curr_state,
    input  wire        actual_taken,

    output reg  [1:0]  next_state
);

    reg [1:0] state_n;

    // --------------------------------------------------
    // Combinational next-state logic (INTERNAL ONLY)
    // --------------------------------------------------
    always @(curr_state or actual_taken) begin
        state_n = curr_state;

        if (actual_taken) begin
            case (curr_state)
                2'b00: state_n = 2'b01;
                2'b01: state_n = 2'b10;
                2'b10: state_n = 2'b11;
                2'b11: state_n = 2'b11;
            endcase
        end
        else begin
            case (curr_state)
                2'b00: state_n = 2'b00;
                2'b01: state_n = 2'b00;
                2'b10: state_n = 2'b01;
                2'b11: state_n = 2'b10;
            endcase
        end
    end

    // --------------------------------------------------
    // REGISTERED OUTPUT (Superlint requirement)
    // --------------------------------------------------
    always @(posedge clk or posedge rst) begin
        if (rst)
            next_state <= 2'b01;   // weakly-not-taken
        else if (update_en)
            next_state <= state_n;
    end

endmodule


