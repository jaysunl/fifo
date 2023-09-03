// Checker for FIFO data order
module fifo_data_order_checker;
    parameter DEPTH = 16; // Adjust this based on your FIFO depth
    
    // Input signals
    input logic clk;
    input logic [$clog2(NUM_READ_PORTS)-1:0] rd_en;
    input logic [$clog2(NUM_WRITE_PORTS)-1:0] wr_en;
    input logic [DEPTH-1:0] rd_addr;
    
    // Checker process
    always_ff @(posedge clk) begin
        if (rd_en != wr_en) begin
            // If read and write enable signals are not the same, it's an error
            $display("ERROR: Read and write enables do not match!");
            $finish;
        end
      
        // Check if read address matches write address (data order check)
        if (rd_en && wr_en && rd_addr != wr_addr) begin
            $display("ERROR: Data order mismatch detected!");
            $finish;
        end
    end
endmodule
  