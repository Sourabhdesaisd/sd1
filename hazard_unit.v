
// OPCODES
`define OPCODE_RTYPE 7'b0110011
`define OPCODE_ITYPE 7'b0010011
`define OPCODE_ILOAD 7'b0000011
`define OPCODE_IJALR 7'b1100111
`define OPCODE_BTYPE 7'b1100011
`define OPCODE_STYPE 7'b0100011
`define OPCODE_JTYPE 7'b1101111
`define OPCODE_AUIPC 7'b0010111
`define OPCODE_UTYPE 7'b0110111


// hazard_unit.v (fixed)
module hazard_unit (
    input  [4:0] id_rs1,
    input  [4:0] id_rs2,
    input  [6:0] opcode_id,          // from ID (for rs usage detection)
    input  [4:0] ex_rd,              // rd in EX (ID/EX pipeline reg)
    input        ex_load_inst,       // mem_read_ex
    input        modify_pc_ex,       // mispredict or taken branch/jump resolved in EX

    output reg pc_en,
    output reg if_id_en,
    output reg if_id_flush,
 //   output reg im_flush,
    output reg id_ex_en,
    output reg id_ex_flush
 //   output reg load_stall
);
    // --------------------------------------------------------------
    // 1. Detect which source registers are actually used in ID
    // --------------------------------------------------------------
    wire rs1_used = (opcode_id == `OPCODE_RTYPE)  ||
                    (opcode_id == `OPCODE_ITYPE)  ||
                    (opcode_id == `OPCODE_ILOAD)  ||
                    (opcode_id == `OPCODE_STYPE)  ||
                    (opcode_id == `OPCODE_BTYPE)  ||
                    (opcode_id == `OPCODE_IJALR);

    wire rs2_used = (opcode_id == `OPCODE_RTYPE)  ||
                    (opcode_id == `OPCODE_STYPE)  ||
                    (opcode_id == `OPCODE_BTYPE);

    // --------------------------------------------------------------
    // 2. Load-use hazard detection
    // --------------------------------------------------------------
    wire load_use_hazard = ex_load_inst &&
                           (ex_rd != 5'd0) &&
                           ((rs1_used && (ex_rd == id_rs1)) ||
                            (rs2_used && (ex_rd == id_rs2)));

    // --------------------------------------------------------------
    // 3. Combinational hazard/stall/flush logic
    //    NOTE: modify_pc_ex (branch resolved in EX) must be able to
    //    flush the pipeline even when a stall is active. Therefore
    //    we give modify_pc_ex higher priority than a load-use stall.
    // --------------------------------------------------------------
    always @(modify_pc_ex or load_use_hazard ) begin
        // Default: normal forward progress, no flush
        pc_en          = 1'b1;
        if_id_en       = 1'b1;
        if_id_flush    = 1'b0;
//	im_flush       = 1'b0;
        id_ex_en       = 1'b1;
        id_ex_flush    = 1'b0;
    //    load_stall     = 1'b0;

        // Highest priority: Control hazard resolved in EX (mispredict or taken branch/jump)
        if (modify_pc_ex) begin
            pc_en       = 1'b1;   // allow PC to take corrected value (IF-stage pc_update handles override)
            if_id_en    = 1'b1;
//	im_flush       = 1'b1;
		
            if_id_flush = 1'b1;   // kill wrong-path instruction in IF/ID
            id_ex_flush = 1'b1;   // kill wrong-path instruction in ID/EX
        end
        // Second priority: Load-use stall (1 cycle)
        else if (load_use_hazard) begin
            pc_en       = 1'b0;   // stall PC
            if_id_en    = 1'b0;   // stall IF/ID
            id_ex_flush = 1'b1;   // insert bubble into EX stage
        //    load_stall  = 1'b1;
        end
    end
endmodule
