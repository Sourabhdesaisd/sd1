// inst_mem.v
// Simple 32-bit word-addressed instruction memory

module inst_mem (
    input  wire [9:0] pc, 
    output  [31:0] instruction
);
    reg [31:0] mem [0:1023];

    initial begin
        $readmemh("instructions.hex", mem);  // optional
    end




assign instruction = mem[pc];

endmodule












