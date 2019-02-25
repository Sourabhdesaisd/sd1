/*module btb_read #(
    parameter TAGW = 27
)(
    input  wire [31:0] pc,

    // data from file
    input  wire rd_valid0,
    input  wire [TAGW-1:0] rd_tag0,
    input  wire rd_valid1,
    input  wire [TAGW-1:0] rd_tag1,

    output wire [2:0]  set_index,
    output wire [TAGW-1:0] tag,
    output wire hit0,
    output wire hit1
);
    assign set_index = pc[4:2];
    assign tag       = pc[31:5];

    assign hit0 = rd_valid0 && (rd_tag0 == tag);
    assign hit1 = rd_valid1 && (rd_tag1 == tag);
endmodule
*/
// ======================================================
// btb_read.v
// Zero-cycle BTB read / hit detect (IF stage)
// Intentionally combinational
// ======================================================

module btb_read #(
    parameter TAGW = 27
)(
    input  [29:0] pc,

    // datm BTB file
    input         rd_valid0,
    input  [TAGW-1:0] rd_tag0,
    input         rd_valid1,
    input  [TAGW-1:0] rd_tag1,

    output [2:0]  set_index,
    output        hit0,
    output        hit1
);

    // -------------------------------
    // Zero-cycle decode
    // -------------------------------
    assign set_index = pc[2:0];

    assign hit0 = rd_valid0 && (rd_tag0 == pc[29:3]);
    assign hit1 = rd_valid1 && (rd_tag1 == pc[29:3]);

endmodule
