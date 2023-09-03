module fifo_top
    #(parameter DATA_WIDTH = 8,      // Data width of the FIFO
      parameter ADDR_WIDTH = 6,      // Address width for BRAM
      parameter DEPTH = 16,          // Depth of the FIFO
      parameter NUM_READ_PORTS = 2,  // Number of read ports
      parameter NUM_WRITE_PORTS = 2, // Number of write ports
      parameter ASYNC_RESET = 1)     // Asynchronous reset (1 for enabled, 0 for disabled)
    (
      input logic clk,                                      // Clock input
      input logic rst,                                      // Reset input
      input logic [$clog2(NUM_READ_PORTS)-1:0] rd_en,       // Read enable signals
      input logic [$clog2(NUM_WRITE_PORTS)-1:0] wr_en,      // Write enable signals
      input logic [$clog2(NUM_WRITE_PORTS)-1:0] wr_full,    // Write full indicators
      input logic [DATA_WIDTH-1:0] wr_data,                 // Write data
      output logic [$clog2(NUM_READ_PORTS)-1:0] rd_empty,   // Read empty indicators
      output logic [$clog2(NUM_READ_PORTS)-1:0] rd_data     // Read data outputs
    );
  
    // Internal signals
    logic [$clog2(DEPTH)-1:0] wr_addr[NUM_WRITE_PORTS];
    logic [$clog2(DEPTH)-1:0] rd_addr[NUM_READ_PORTS];
    logic [DATA_WIDTH-1:0] fifo_data[DEPTH-1:0];
    logic [DATA_WIDTH-1:0] rd_data_out[NUM_READ_PORTS];
    logic [$clog2(NUM_READ_PORTS)-1:0] rd_empty_internal;
    logic [$clog2(NUM_WRITE_PORTS)-1:0] wr_full_internal;
    logic [$clog2(NUM_WRITE_PORTS)-1:0] wr_empty_internal;
    logic [DATA_WIDTH-1:0] wr_data_internal[NUM_WRITE_PORTS];
    logic wr_en_internal;
  
    // Asynchronous reset
    logic async_rst_reg;
  
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            async_rst_reg <= 1'b1;
        end else begin
            async_rst_reg <= ASYNC_RESET ? async_rst_reg & ~wr_full | wr_en : 1'b0;
        end
    end
  
    // BRAM instantiation
    generate
        if (DEPTH > 1) begin : bram_instantiation
            for (int i = 0; i < NUM_WRITE_PORTS; i = i + 1) begin : write_bram
                always_ff @(posedge clk or posedge async_rst_reg) begin
                    if (async_rst_reg) begin
                        wr_addr[i] <= 0;
                        wr_data_internal[i] <= 0;
                    end else if (wr_en[i] && !wr_full[i]) begin
                        wr_addr[i] <= wr_addr[i] + 1;
                        wr_data_internal[i] <= wr_data;
                    end
                end
  
                // Instantiate BRAM for write port
                parameter BRAM_STYLE = "block";
                parameter WRITE_WIDTH = DATA_WIDTH;
                parameter READ_WIDTH = DATA_WIDTH;
                parameter WRITE_DEPTH = DEPTH;
                parameter READ_DEPTH = DEPTH;
                parameter RAM_STYLE = "auto";
  
                (* ram_style = RAM_STYLE *) logic [DATA_WIDTH-1:0] bram_data [0:DEPTH-1];
  
                always_ff @(posedge clk or posedge async_rst_reg) begin
                    if (async_rst_reg) begin
                        for (int j = 0; j < DEPTH; j = j + 1) begin
                            bram_data[j] <= 0;
                        end
                    end else if (wr_en[i] && !wr_full[i]) begin
                        bram_data[wr_addr[i]] <= wr_data_internal[i];
                    end
                end
            end : write_bram
  
            for (int i = 0; i < NUM_READ_PORTS; i = i + 1) begin : read_bram
                // Read address generation using Grey code
                always_ff @(posedge clk or posedge async_rst_reg) begin
                    if (async_rst_reg) begin
                        rd_addr[i] <= 0;
                    end else if (rd_en[i] && !rd_empty_internal[i]) begin
                        rd_addr[i] <= rd_addr[i] + 1;
                    end
                end
  
                // Instantiate BRAM for read port
                parameter BRAM_STYLE = "block";
                parameter WRITE_WIDTH = DATA_WIDTH;
                parameter READ_WIDTH = DATA_WIDTH;
                parameter WRITE_DEPTH = DEPTH;
                parameter READ_DEPTH = DEPTH;
                parameter RAM_STYLE = "auto";
  
                (* ram_style = RAM_STYLE *) logic [DATA_WIDTH-1:0] bram_data [0:DEPTH-1];
  
                always_ff @(posedge clk or posedge async_rst_reg) begin
                    if (async_rst_reg) begin
                        for (int j = 0; j < DEPTH; j = j + 1) begin
                            bram_data[j] <= 0;
                        end
                    end else if (rd_en[i] && !rd_empty_internal[i]) begin
                        rd_data_out[i] <= bram_data[rd_addr[i]];
                    end
                end
            end : read_bram
        end
    endgenerate
  
    // Empty and full status signals
    always_ff @(posedge clk or posedge async_rst_reg) begin
        for (int i = 0; i < NUM_WRITE_PORTS; i = i + 1) begin
            wr_full_internal[i] <= wr_en[i] && wr_addr[i] == DEPTH - 1;
            wr_empty_internal[i] <= !wr_en[i] || wr_full_internal[i];
        end
  
        for (int i = 0; i < NUM_READ_PORTS; i = i + 1) begin
            rd_empty_internal[i] <= !rd_en[i] || (rd_en[i] && rd_addr[i] == DEPTH - 1);
        end
    end
  
    // Read and write pointer logic
    always_ff @(posedge clk or posedge async_rst_reg) begin
        if (async_rst_reg) begin
            for (int i = 0; i < NUM_WRITE_PORTS; i = i + 1) begin
                wr_addr[i] <= 0;
            end
            for (int i = 0; i < NUM_READ_PORTS; i = i + 1) begin
                rd_addr[i] <= 0;
            end
        end else begin
            for (int i = 0; i < NUM_WRITE_PORTS; i = i + 1) begin
                if (wr_en[i] && !wr_full_internal[i]) begin
                    wr_addr[i] <= wr_addr[i] + 1;
                end
            end
            for (int i = 0; i < NUM_READ_PORTS; i = i + 1) begin
                if (rd_en[i] && !rd_empty_internal[i]) begin
                    rd_addr[i] <= rd_addr[i] + 1;
                end
            end
        end
    end
  
  endmodule
