// id_ex_reg.v
module id_ex_pipe (
    input  clk,
    input  rst,
    input  en,      // from hazard_unit.id_ex_en
    input  flush,   // from hazard_unit.id_ex_flush (mispredict or load-use bubble)

    input  [31:0] pc_id,
 //   input  [31:0] instr_id,
    input         predictedTaken_id,
 //   input  [31:0] predictedTarget_id,

 //   input  [6:0] opcode,
    input  [2:0] func3,
   // input  [6:0] func7,
    input  [4:0] rd,
    input  [4:0] rs1,
    input  [4:0] rs2,
    input  [31:0] imm_out,
    input  [31:0] rs1_data,
    input  [31:0] rs2_data,

    input  ex_alu_src,
    input  mem_write,
    input  mem_read,
    input  [2:0] mem_load_type,
    input  [1:0] mem_store_type,
    input  wb_reg_file,
    input  memtoreg,
    input  Branch_1,
    input  jal,
    input  jalr,
   // input  auipc,
  //  input  lui,
    input  [3:0] alu_ctrl,

    output reg [31:0] pc_ex,
   // output reg [31:0] instr_ex,
    output reg        predictedTaken_ex,
  //  output reg [31:0] predictedTarget_ex,

  //  output reg [6:0] opcode_ex,
    output reg [2:0] func3_ex,
  //  output reg [6:0] func7_ex,
    output reg [4:0] rd_ex,
    output reg [4:0] rs1_ex,
    output reg [4:0] rs2_ex,
    output reg [31:0] imm_ex,
    output reg [31:0] rs1_data_ex,
    output reg [31:0] rs2_data_ex,

    output reg ex_alu_src_ex,
    output reg mem_write_ex,
    output reg mem_read_ex,
    output reg [2:0] mem_load_type_ex,
    output reg [1:0] mem_store_type_ex,
    output reg wb_reg_file_ex,
    output reg memtoreg_ex,
    output reg branch_ex,
    output reg jal_ex,
    output reg jalr_ex,
   // output reg auipc_ex,
  //  output reg lui_ex,
    output reg [3:0] alu_ctrl_ex
);
    parameter NOP_INSTR = 32'h00000013;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            pc_ex               <= 32'h0;
         //   instr_ex            <= NOP_INSTR;
            predictedTaken_ex   <= 1'b0;
        //    predictedTarget_ex  <= 32'h0;
        //    opcode_ex           <= 7'd0;
            func3_ex            <= 3'd0;
         //   func7_ex            <= 7'd0;
            rd_ex               <= 5'd0;
            rs1_ex              <= 5'd0;
            rs2_ex              <= 5'd0;
            imm_ex              <= 32'h0;
            rs1_data_ex         <= 32'h0;
            rs2_data_ex         <= 32'h0;
            ex_alu_src_ex       <= 1'b0;
            mem_write_ex        <= 1'b0;
            mem_read_ex         <= 1'b0;
            mem_load_type_ex    <= 3'b111;
            mem_store_type_ex   <= 2'b11;
            wb_reg_file_ex      <= 1'b0;
            memtoreg_ex         <= 1'b0;
            branch_ex           <= 1'b0;
            jal_ex              <= 1'b0;
            jalr_ex             <= 1'b0;
           // auipc_ex            <= 1'b0;
          //  lui_ex              <= 1'b0;
            alu_ctrl_ex         <= 4'b0;
        end
        // FLUSH must have priority over stall so mispredict/bubble is inserted
        else if (flush) begin
            // Insert bubble (safe NOP) on mispredict or load-use
            pc_ex               <= 32'h0;
      //      instr_ex            <= NOP_INSTR;
            predictedTaken_ex   <= 1'b0;
        //    predictedTarget_ex  <= 32'h0;
        //    opcode_ex           <= 7'd0;
            func3_ex            <= 3'd0;
       //     func7_ex            <= 7'd0;
            rd_ex               <= 5'd0;
            rs1_ex              <= 5'd0;
            rs2_ex              <= 5'd0;
            imm_ex              <= 32'h0;
            rs1_data_ex         <= 32'h0;
            rs2_data_ex         <= 32'h0;
            ex_alu_src_ex       <= 1'b0;
            mem_write_ex        <= 1'b0;
            mem_read_ex         <= 1'b0;
            mem_load_type_ex    <= 3'b111;
            mem_store_type_ex   <= 2'b11;
            wb_reg_file_ex      <= 1'b0;
            memtoreg_ex         <= 1'b0;
            branch_ex           <= 1'b0;
            jal_ex              <= 1'b0;
            jalr_ex             <= 1'b0;
         //   auipc_ex            <= 1'b0;
         //   lui_ex              <= 1'b0;
            alu_ctrl_ex         <= 4'b0;
        end
       /* else if (!en) begin
            // Stall: hold all values explicitly (prevents accidental updates)
            pc_ex               <= pc_ex;
            instr_ex            <= instr_ex;
            predictedTaken_ex   <= predictedTaken_ex;
            predictedTarget_ex  <= predictedTarget_ex;
            opcode_ex           <= opcode_ex;
            func3_ex            <= func3_ex;
            func7_ex            <= func7_ex;
            rd_ex               <= rd_ex;
            rs1_ex              <= rs1_ex;
            rs2_ex              <= rs2_ex;
            imm_ex              <= imm_ex;
            rs1_data_ex         <= rs1_data_ex;
            rs2_data_ex         <= rs2_data_ex;
            ex_alu_src_ex       <= ex_alu_src_ex;
            mem_write_ex        <= mem_write_ex;
            mem_read_ex         <= mem_read_ex;
            mem_load_type_ex    <= mem_load_type_ex;
            mem_store_type_ex   <= mem_store_type_ex;
            wb_reg_file_ex      <= wb_reg_file_ex;
            memtoreg_ex         <= memtoreg_ex;
            branch_ex           <= branch_ex;
            jal_ex              <= jal_ex;
            jalr_ex             <= jalr_ex;
            auipc_ex            <= auipc_ex;
            lui_ex              <= lui_ex;
            alu_ctrl_ex         <= alu_ctrl_ex;
        end */
        else if (en) begin
            // Normal pipeline advance
            pc_ex               <= pc_id;
        //    instr_ex            <= instr_id;
            predictedTaken_ex   <= predictedTaken_id;
        //    predictedTarget_ex  <= predictedTarget_id;
        //    opcode_ex           <= opcode;
            func3_ex            <= func3;
          //  func7_ex            <= func7;
            rd_ex               <= rd;
            rs1_ex              <= rs1;
            rs2_ex              <= rs2;
            imm_ex              <= imm_out;
            rs1_data_ex         <= rs1_data;
            rs2_data_ex         <= rs2_data;
            ex_alu_src_ex       <= ex_alu_src;
            mem_write_ex        <= mem_write;
            mem_read_ex         <= mem_read;
            mem_load_type_ex    <= mem_load_type;
            mem_store_type_ex   <= mem_store_type;
            wb_reg_file_ex      <= wb_reg_file;
            memtoreg_ex         <= memtoreg;
            branch_ex           <= Branch_1;
            jal_ex              <= jal;
            jalr_ex             <= jalr;
            //auipc_ex            <= auipc;
           // lui_ex              <= lui;
            alu_ctrl_ex         <= alu_ctrl;
        end
    end
endmodule
