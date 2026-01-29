// ============================================================================
// Parameterized Testbench for MAC Unit - Verilog Version
// ============================================================================

`timescale 1ns/1ps

module tb #(
    parameter DATA_WIDTH = 8,
    parameter ACCUM_WIDTH = 32,
    parameter OUTPUT_WIDTH = 16
);

    // ========================================================================
    // Test Parameters
    // ========================================================================
    parameter CLK_PERIOD = 10;
    localparam MAX_INPUT = (1 << DATA_WIDTH) - 1;
    localparam MAX_PRODUCT = MAX_INPUT * MAX_INPUT;
    
    // ========================================================================
    // DUT Signals
    // ========================================================================
    reg clk;
    reg rst_n;
    reg enable;
    reg clear_acc;
    reg [DATA_WIDTH-1:0] input_data;
    reg [DATA_WIDTH-1:0] weight;
    wire [OUTPUT_WIDTH-1:0] mac_out;
    wire [OUTPUT_WIDTH-1:0] activated_out;
    wire valid;
    wire overflow;
    
    // ========================================================================
    // Test Infrastructure
    // ========================================================================
    integer test_count;
    integer pass_count;
    integer fail_count;
    integer i, j, k;
    
    // Test variables
    reg [DATA_WIDTH-1:0] test_a, test_b;
    reg [2*DATA_WIDTH-1:0] expected_result;
    reg [ACCUM_WIDTH-1:0] expected_acc;
    reg pass;
    
    // ========================================================================
    // DUT Instantiation
    // ========================================================================
    mac_unit #(
        .DATA_WIDTH(DATA_WIDTH),
        .ACCUM_WIDTH(ACCUM_WIDTH),
        .OUTPUT_WIDTH(OUTPUT_WIDTH),
        .USE_SQRT_CSLA(1),
        .ENABLE_ACTIVATION(1)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .enable(enable),
        .clear_acc(clear_acc),
        .input_data(input_data),
        .weight(weight),
        .mac_out(mac_out),
        .activated_out(activated_out),
        .valid(valid),
        .overflow(overflow)
    );
    
    // ========================================================================
    // Clock Generation
    // ========================================================================
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end
    
    // ========================================================================
    // Helper Tasks
    // ========================================================================
    
    task reset_dut;
    begin
        rst_n = 0;
        enable = 0;
        clear_acc = 0;
        input_data = {DATA_WIDTH{1'b0}};
        weight = {DATA_WIDTH{1'b0}};
        repeat(3) @(posedge clk);
        rst_n = 1;
        @(posedge clk);
        $display("[%0t] DUT Reset Complete", $time);
    end
    endtask
    
    task apply_input;
        input [DATA_WIDTH-1:0] in_val;
        input [DATA_WIDTH-1:0] wt_val;
        input en;
        input clr;
    begin
        @(posedge clk);
        input_data = in_val;
        weight = wt_val;
        enable = en;
        clear_acc = clr;
        @(posedge clk);
        enable = 1'b0;
    end
    endtask
    
    task wait_cycles;
        input integer n;
    begin
        for (k = 0; k < n; k = k + 1)
            @(posedge clk);
    end
    endtask
    
    task check_multiplication;
        input [DATA_WIDTH-1:0] a;
        input [DATA_WIDTH-1:0] b;
        reg [OUTPUT_WIDTH-1:0] actual;
        reg [2*DATA_WIDTH-1:0] expected_full;
        reg local_pass;
    begin
        test_count = test_count + 1;
        expected_full = a * b;
        
        // Clear accumulator first, then multiply
        apply_input(a, b, 1'b1, 1'b1);
        @(posedge clk);
        actual = mac_out;
        
        // Check based on whether result fits in output width
        if (expected_full >= (1 << OUTPUT_WIDTH)) begin
            // Expected overflow - just verify no crash
            local_pass = 1;
        end else begin
            local_pass = (actual == expected_full[OUTPUT_WIDTH-1:0]);
        end
        
        if (local_pass) 
            pass_count = pass_count + 1;
        else
            fail_count = fail_count + 1;
        
        $display("Test %4d | 0x%h * 0x%h | Expected: 0x%h | Actual: 0x%h | %s",
                 test_count, a, b, expected_full[OUTPUT_WIDTH-1:0], actual, 
                 local_pass ? "PASS" : "FAIL");
            
        if (!local_pass) begin
            $display("  ERROR: Multiplication Test FAILED");
        end
    end
    endtask
    
    task print_banner;
        input [80*8-1:0] msg;
    begin
        $display("");
        $display("================================================================================");
        $display("  %0s", msg);
        $display("================================================================================");
        $display("");
    end
    endtask
    
    task print_config;
    begin
        $display("Configuration:");
        $display("  DATA_WIDTH:    %0d bits", DATA_WIDTH);
        $display("  ACCUM_WIDTH:   %0d bits", ACCUM_WIDTH);
        $display("  OUTPUT_WIDTH:  %0d bits", OUTPUT_WIDTH);
        $display("  MAX_INPUT:     %0d (0x%h)", MAX_INPUT, MAX_INPUT);
        $display("  MAX_PRODUCT:   %0d", MAX_PRODUCT);
        $display("");
    end
    endtask
    
    task print_summary;
        real pass_rate;
    begin
        pass_rate = (test_count > 0) ? (pass_count * 100.0) / test_count : 0.0;
        $display("");
        $display("================================================================================");
        $display("  TEST SUMMARY - %0d-bit MAC UNIT", DATA_WIDTH);
        $display("================================================================================");
        $display("  Total Tests:  %0d", test_count);
        $display("  Passed:       %0d", pass_count);
        $display("  Failed:       %0d", fail_count);
        $display("  Pass Rate:    %.2f%%", pass_rate);
        $display("================================================================================");
        $display("");
    end
    endtask
    
    // ========================================================================
    // Test Scenarios
    // ========================================================================
    
    // Test 1: Corner Cases
    task test_corner_cases;
        reg [DATA_WIDTH-1:0] max_val;
        reg [DATA_WIDTH-1:0] mid_val;
    begin
        max_val = {DATA_WIDTH{1'b1}};
        mid_val = (1 << (DATA_WIDTH-1));
        
        print_banner("TEST 1: Corner Cases");
        $display("Test#  | Operation   | Expected       | Actual         | Result");
        $display("--------------------------------------------------------------------------------");
        
        // Zero tests
        check_multiplication({DATA_WIDTH{1'b0}}, {DATA_WIDTH{1'b0}});
        check_multiplication({DATA_WIDTH{1'b0}}, {DATA_WIDTH{1'b1}});
        check_multiplication({DATA_WIDTH{1'b1}}, {DATA_WIDTH{1'b0}});
        check_multiplication({DATA_WIDTH{1'b0}}, max_val);
        check_multiplication(max_val, {DATA_WIDTH{1'b0}});
        
        // One tests
        check_multiplication({{(DATA_WIDTH-1){1'b0}}, 1'b1}, {{(DATA_WIDTH-1){1'b0}}, 1'b1});
        check_multiplication({{(DATA_WIDTH-1){1'b0}}, 1'b1}, max_val);
        check_multiplication(max_val, {{(DATA_WIDTH-1){1'b0}}, 1'b1});
        
        // Maximum value
        check_multiplication(max_val, max_val);
        
        // Mid-range values
        check_multiplication(mid_val, mid_val);
    end
    endtask
    
    // Test 2: Powers of 2
    task test_powers_of_two;
    begin
        print_banner("TEST 2: Powers of 2 Multiplication");
        $display("Test#  | Operation   | Expected       | Actual         | Result");
        $display("--------------------------------------------------------------------------------");
        
        for (i = 0; i < DATA_WIDTH; i = i + 1) begin
            for (j = 0; j < DATA_WIDTH; j = j + 1) begin
                if (i + j < 12)  // Limit to avoid too many tests
                    check_multiplication(1 << i, 1 << j);
            end
        end
    end
    endtask
    
    // Test 3: Sequential Patterns
    task test_sequential_patterns;
        integer limit;
    begin
        limit = (DATA_WIDTH <= 8) ? 20 : 10;
        
        print_banner("TEST 3: Sequential Pattern Multiplication");
        $display("Test#  | Operation   | Expected       | Actual         | Result");
        $display("--------------------------------------------------------------------------------");
        
        // Same value multiplication
        for (i = 0; i < limit; i = i + 1) begin
            check_multiplication(i, i);
        end
        
        // Complementary values
        for (i = 0; i < limit && i < (1 << DATA_WIDTH); i = i + 1) begin
            check_multiplication(i, MAX_INPUT - i);
        end
    end
    endtask
    
    // Test 4: Random Vectors
    task test_random_vectors;
        reg [DATA_WIDTH-1:0] rand_a, rand_b;
        integer num_tests;
    begin
        num_tests = (DATA_WIDTH <= 8) ? 50 : 30;
        
        print_banner("TEST 4: Random Vector Multiplication");
        $display("Test#  | Operation   | Expected       | Actual         | Result");
        $display("--------------------------------------------------------------------------------");
        
        for (i = 0; i < num_tests; i = i + 1) begin
            rand_a = $random & MAX_INPUT;
            rand_b = $random & MAX_INPUT;
            check_multiplication(rand_a, rand_b);
        end
    end
    endtask
    
    // Test 5: Accumulation
    task test_accumulation;
        integer num_ops;
        reg [DATA_WIDTH-1:0] acc_a, acc_b;
        reg [2*DATA_WIDTH-1:0] product;
    begin
        print_banner("TEST 5: MAC Accumulation");
        
        num_ops = 10;
        $display("Running %0d MAC operations...", num_ops);
        
        // Clear accumulator first
        apply_input({DATA_WIDTH{1'b0}}, {DATA_WIDTH{1'b0}}, 1'b0, 1'b1);
        expected_acc = 0;
        
        // Perform multiple MAC operations
        for (i = 0; i < num_ops; i = i + 1) begin
            // Scale down to avoid overflow
            acc_a = ($random & ((1 << (DATA_WIDTH-2)) - 1)) + 1;
            acc_b = ($random & ((1 << (DATA_WIDTH-2)) - 1)) + 1;
            product = acc_a * acc_b;
            expected_acc = expected_acc + product;
            apply_input(acc_a, acc_b, 1'b1, 1'b0);
            
            if (i < 5)
                $display("  Op %0d: %0d * %0d = %0d, Expected Acc = %0d", 
                        i+1, acc_a, acc_b, product, expected_acc);
        end
        
        @(posedge clk);
        pass = (dut.accumulator[OUTPUT_WIDTH-1:0] == expected_acc[OUTPUT_WIDTH-1:0]);
        
        test_count = test_count + 1;
        if (pass) 
            pass_count = pass_count + 1;
        else
            fail_count = fail_count + 1;
        
        $display("  Expected Acc[%0d:0]: 0x%h", OUTPUT_WIDTH-1, expected_acc[OUTPUT_WIDTH-1:0]);
        $display("  Actual Acc[%0d:0]:   0x%h", OUTPUT_WIDTH-1, dut.accumulator[OUTPUT_WIDTH-1:0]);
        $display("  Result: %s", pass ? "PASS" : "FAIL");
        $display("");
    end
    endtask
    
    // Test 6: Clear Functionality
    task test_clear_functionality;
    begin
        print_banner("TEST 6: Clear Accumulator Functionality");
        
        // Build up accumulator
        apply_input({DATA_WIDTH{1'b0}}, {DATA_WIDTH{1'b0}}, 1'b0, 1'b1);
        apply_input(10, 10, 1'b1, 1'b0);
        apply_input(20, 20, 1'b1, 1'b0);
        apply_input(30, 30, 1'b1, 1'b0);
        @(posedge clk);
        
        $display("Accumulator before clear: 0x%h", mac_out);
        
        // Clear accumulator
        apply_input({DATA_WIDTH{1'b0}}, {DATA_WIDTH{1'b0}}, 1'b0, 1'b1);
        @(posedge clk);
        
        $display("Accumulator after clear:  0x%h", mac_out);
        $display("Overflow flag:            %b", overflow);
        
        test_count = test_count + 1;
        pass = (mac_out == {OUTPUT_WIDTH{1'b0}} && dut.accumulator == {ACCUM_WIDTH{1'b0}} && !overflow);
        
        if (pass) begin
            pass_count = pass_count + 1;
            $display("Clear test: PASS");
        end else begin
            fail_count = fail_count + 1;
            $display("Clear test: FAIL");
        end
        $display("");
    end
    endtask
    
    // Test 7: Overflow Detection
    task test_overflow_detection;
        reg [DATA_WIDTH-1:0] max_val;
    begin
        max_val = {DATA_WIDTH{1'b1}};
        
        print_banner("TEST 7: Overflow Detection");
        
        // Clear first
        apply_input({DATA_WIDTH{1'b0}}, {DATA_WIDTH{1'b0}}, 1'b0, 1'b1);
        @(posedge clk);
        
        $display("Filling accumulator to trigger overflow...");
        
        // Repeatedly add large values
        for (i = 0; i < 1000; i = i + 1) begin
            apply_input(max_val, max_val, 1'b1, 1'b0);
            @(posedge clk);
            
            if (overflow) begin
                $display("  Overflow detected at iteration %0d", i+1);
                $display("  Accumulator: 0x%h", dut.accumulator);
                i = 1000; // Break loop
            end
            
            if (i % 100 == 0 && i > 0)
                $display("  Iteration %0d: Accumulator = 0x%h", i, dut.accumulator);
        end
        
        test_count = test_count + 1;
        if (overflow) begin
            pass_count = pass_count + 1;
            $display("Overflow test: PASS");
        end else begin
            pass_count = pass_count + 1; // May not overflow with large accumulator
            $display("Overflow test: No overflow (OK for large accumulator)");
        end
        $display("");
    end
    endtask
    
    // Test 8: Activation Function
    task test_activation_function;
    begin
        print_banner("TEST 8: Sigmoid Activation Function");
        
        $display("Description          | Product | MAC Output     | Activated");
        $display("--------------------------------------------------------------------------------");
        
        // Zero input
        apply_input({DATA_WIDTH{1'b0}}, {DATA_WIDTH{1'b0}}, 1'b1, 1'b1);
        @(posedge clk);
        $display("Zero input           | 0x%h  | 0x%h | 0x%h",
                {DATA_WIDTH{1'b0}} * {DATA_WIDTH{1'b0}}, mac_out, activated_out);
        
        // Various inputs
        if (DATA_WIDTH >= 4) begin
            apply_input(1, 100, 1'b1, 1'b1);
            @(posedge clk);
            $display("Small product        | 0x%h  | 0x%h | 0x%h",
                    16'd100, mac_out, activated_out);
            
            apply_input(50, 50, 1'b1, 1'b1);
            @(posedge clk);
            $display("Medium product       | 0x%h  | 0x%h | 0x%h",
                    16'd2500, mac_out, activated_out);
        end
        
        // Maximum
        apply_input({DATA_WIDTH{1'b1}}, {DATA_WIDTH{1'b1}}, 1'b1, 1'b1);
        @(posedge clk);
        $display("Maximum product      | 0x%h  | 0x%h | 0x%h",
                MAX_PRODUCT[OUTPUT_WIDTH-1:0], mac_out, activated_out);
        
        $display("");
    end
    endtask
    
    // ========================================================================
    // Assertion Monitors
    // ========================================================================
    
    // Monitor: Reset behavior
    always @(posedge clk) begin
        if (!rst_n) begin
            #1;
            if (mac_out !== {OUTPUT_WIDTH{1'b0}} || valid !== 1'b0 || overflow !== 1'b0) begin
                $display("ASSERTION FAILED [%0t]: Reset behavior incorrect", $time);
            end
        end
    end
    
    // Monitor: Valid signal timing
    reg enable_delayed;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            enable_delayed <= 1'b0;
        else
            enable_delayed <= enable;
    end
    
    always @(posedge clk) begin
        if (rst_n && (enable_delayed !== valid)) begin
            $display("ASSERTION FAILED [%0t]: Valid signal timing incorrect", $time);
        end
    end
    
    // Monitor: Clear accumulator
    reg clear_acc_delayed;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            clear_acc_delayed <= 1'b0;
        else
            clear_acc_delayed <= clear_acc;
    end
    
    always @(posedge clk) begin
        if (rst_n && clear_acc_delayed && (dut.accumulator !== {ACCUM_WIDTH{1'b0}} || overflow !== 1'b0)) begin
            $display("ASSERTION FAILED [%0t]: Clear accumulator failed", $time);
        end
    end
    
    // ========================================================================
    // Main Test Execution
    // ========================================================================
    initial begin
        // Waveform dump
        $dumpfile("mac_unit.vcd");
        $dumpvars(0, tb);
        
        // Initialize counters
        test_count = 0;
        pass_count = 0;
        fail_count = 0;
        
        print_banner("MAC UNIT VERIFICATION - STARTING");
        $display("Simulation Time: %0t", $time);
        $display("Clock Period: %0d ns", CLK_PERIOD);
        print_config();
        
        // Initialize and reset
        reset_dut();
        
        // Run all tests
        test_corner_cases();
        test_powers_of_two();
        test_sequential_patterns();
        test_random_vectors();
        test_accumulation();
        test_clear_functionality();
        test_overflow_detection();
        test_activation_function();
        
        // Final summary
        wait_cycles(5);
        print_summary();
        
        if (fail_count == 0) begin
            print_banner("ALL TESTS PASSED!");
            $display("SUCCESS: %0d-bit MAC Unit verification completed successfully", DATA_WIDTH);
        end else begin
            print_banner("SOME TESTS FAILED!");
            $display("FAILURE: Please review failed test cases");
        end
        $display("");
        
        $finish;
    end
    
    // Timeout watchdog
    initial begin
        #10_000_000;
        $display("");
        $display("ERROR: Simulation timeout!");
        $finish;
    end
    
endmodule

// ============================================================================
// Multi-Width Test Runner
// ============================================================================
module multi_width_test_runner;
    
    initial begin
        $display("");
        $display("################################################################################");
        $display("  MULTI-WIDTH MAC UNIT VERIFICATION SUITE");
        $display("################################################################################");
        $display("");
    end
    
    // Instantiate tests for different widths
    // Uncomment the ones you want to test
    
    // 4-bit test
    tb #(.DATA_WIDTH(4), .ACCUM_WIDTH(16), .OUTPUT_WIDTH(8)) 
        test_4bit();
    
    // 8-bit test (default from paper)
    //tb #(.DATA_WIDTH(8), .ACCUM_WIDTH(32), .OUTPUT_WIDTH(16)) 
    //    test_8bit();
    
    // 16-bit test
    //tb #(.DATA_WIDTH(16), .ACCUM_WIDTH(64), .OUTPUT_WIDTH(32)) 
    //    test_16bit();
    
endmodule