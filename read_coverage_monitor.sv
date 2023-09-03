// Coverage monitor for FIFO read operations
module read_coverage_monitor;
    parameter DEPTH = 16; // Adjust this based on FIFO depth
    
    // Input signals
    input logic clk;
    input logic [$clog2(NUM_READ_PORTS)-1:0] rd_en;
    input logic [DEPTH-1:0] rd_addr;
    input logic [DATA_WIDTH-1:0] rd_data_out;
    
    // Coverage points
    covergroup read_coverage @(posedge clk);
        option.per_instance = 1;
      
        // Check if all read enable signals have been exercised
        rd_enable: coverpoint rd_en {
            bins en[] = {[$:0:(2**NUM_READ_PORTS)-1]};
        }
      
        // Check if all read addresses have been covered
        rd_address: coverpoint rd_addr {
            bins addr[] = {[$:0:DEPTH-1]};
        }
      
        // Check if all read data values have been covered
        rd_data_value: coverpoint rd_data_out {
            bins data[] = {[$:0:(2**DATA_WIDTH)-1]};
        }
    endgroup
    
    // Instantiate the coverage group
    read_coverage read_cov_inst = new;
    
    // Monitor process
    always_ff @(posedge clk) begin
        read_cov_inst.sample();
    end
endmodule
  
