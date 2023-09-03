// Coverage monitor for FIFO write operations
module write_coverage_monitor;
    parameter DEPTH = 16;       // Adjust based on FIFO depth

    // Input signals
    input logic clk;
    input logic [DEPTH-1:0] wr_addr;
    input logic [DATA_WIDTH-1:0] wr_data;
    input logic [$clog2(NUM_WRITE_PORTS)] wr_en;

    // Coverage points
    covergroup write_coverage @(posedge clk);
        option.per_instance = 1;

        // Check if all the write addresses have been covered
        wr_address: coverpoint wr_addr {
            bins addr[] = {[$:0:DEPTH-1]};
        }

        // Check if all write data values have been covered
        wr_data_value: coverpoint wr_data {
            bins data[] = {[$:0:(2**DATA_WIDTH)-1]};
        }

        // Check if all write ports have been exercised
        wr_port: coverpoint wr_en {
            bins port[] = {[$:0:(2**NUM_WRITE_PORTS)-1]};
        }
    endgroup 

    // Instantiate the coverage group
    write_coverage write_cov_inst = new;
  
    // Monitor process
    always_ff @(posedge clk) begin
        write_cov_inst.sample();
    end
endmodule