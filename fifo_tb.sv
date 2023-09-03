module tb_parameterized_fifo;
    // Parameters
    parameter DATA_WIDTH = 8;
    parameter DEPTH = 16;
    parameter NUM_READ_PORTS = 2;
    parameter NUM_WRITE_PORTS = 2;
    parameter ASYNC_RESET = 1;
  
    // Clock generation
    logic clk = 0;
    always begin
        #5 clk = ~clk;
    end
  
    // Reset generation
    logic rst = 0;
    initial begin
        rst = 1;
        #10 rst = 0;
    end
  
    // DUT instantiation
    parameterized_fifo #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH($clog2(DEPTH)),
        .DEPTH(DEPTH),
        .NUM_READ_PORTS(NUM_READ_PORTS),
        .NUM_WRITE_PORTS(NUM_WRITE_PORTS),
        .ASYNC_RESET(ASYNC_RESET)
    ) dut (
        .clk(clk),
        .rst(rst),
        .wr_en(wr_en),          // Connect write enable signals
        .rd_en(rd_en),          // Connect read enable signals
        .wr_full(wr_full),      // Connect write full indicators
        .wr_data(wr_data),      // Connect write data
        .rd_empty(rd_empty),    // Connect read empty indicators
        .rd_data(rd_data)       // Connect read data outputs
    );
  
    // Instantiate coverage monitors
    write_coverage_monitor write_cov (
        .clk(clk),
        .wr_en(wr_en),
        .wr_addr(dut.wr_addr),
        .wr_data(wr_data)
    );
  
    read_coverage_monitor read_cov (
        .clk(clk),
        .rd_en(rd_en),
        .rd_addr(dut.rd_addr),
        .rd_data_out(rd_data)
    );
  
    // Instantiate checkers
    fifo_data_order_checker data_order_check (
        .clk(clk),
        .rd_en(rd_en),
        .wr_en(wr_en),
        .rd_addr(dut.rd_addr)
    );
  
    // Random stimulus generation with constraints
    initial begin
        // Initialize variables and signals
        wr_en = 0;
        rd_en = 0;
        wr_full = 0;
        wr_data = 0;
        rd_empty = 1;
        rd_data = 0;
    
        // Functional coverage
        covergroup functional_coverage @(posedge clk);
            option.per_instance = 1;
    
            // Functional coverage points
            bins read_write_seq = (rd_en && wr_en) -> (rd_data == wr_data);
            bins almost_full = (wr_full && !rd_en);
            bins almost_empty = (rd_empty && !wr_en);
            bins read_data_pattern[] = {[DATA_WIDTH-1:0] data} with (rd_en && (data == rd_data));
            bins write_data_pattern[] = {[DATA_WIDTH-1:0] data} with (wr_en && (data == wr_data));
            bins num_read_ports_active = [$:0:NUM_READ_PORTS];
            bins num_write_ports_active = [$:0:NUM_WRITE_PORTS];
            bins read_write_port_combinations = {wr_en, rd_en};
    
        endgroup
    
        // Start constrained random stimulus generation loop
        repeat (100) begin
            // Constrained randomization for write data
            if (wr_en) begin
                wr_data = $urandom_range(0, 255); // Constrain data values between 0 and 255
            end
    
            // Constrained randomization for addresses
            wr_addr = $urandom_range(0, DEPTH - 1); // Constrain write address within FIFO depth
            rd_addr = $urandom_range(0, DEPTH - 1); // Constrain read address within FIFO depth
    
            // Constrained randomization for port activity (adjust probabilities based on design behavior)
            if ($urandom < 0.8) begin // 80% chance of write port activation
                wr_en = 1;
            end else begin
                wr_en = 0;
            end
    
            if ($urandom < 0.6) begin // 60% chance of read port activation
                rd_en = 1;
            end else begin
                rd_en = 0;
            end
    
            // Monitor coverage and checkers
            write_cov.sample();
            read_cov.sample();
            data_order_check.check();
            functional_coverage.sample(); // Sample functional coverage
    
            // Assertions for desired FIFO behavior
            assert (rd_empty || rd_en) else $display("Assertion failed: FIFO not empty when read is enabled!");
            assert (!wr_full || wr_en) else $display("Assertion failed: FIFO full when write is enabled!");
    
            // Simulate for a few clock cycles
            #10;
        end
    
        // End simulation when all tests are complete
        $display("Simulation completed successfully!");
        $finish;
    end
  
    // Terminate simulation after a specified time
    initial begin
        #10000; // Terminate simulation after 10000 time units
        $display("Simulation timed out.");
        $finish;
    end
  
endmodule
  