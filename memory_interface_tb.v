`timescale 1ns/1ps

module memory_interface_tb;

    reg clk;
    reg reset;
    reg write_enable;
    reg read_enable;
    reg [3:0] address;
    reg [7:0] write_data;

    wire [7:0] read_data;
    wire single_error;
    wire double_error;


    // ---------------------------------------------------------
    // Instantiate Memory Interface
    // ---------------------------------------------------------

    memory_interface DUT (

        .clk(clk),
        .reset(reset),
        .write_enable(write_enable),
        .read_enable(read_enable),
        .address(address),
        .write_data(write_data),

        .read_data(read_data),
        .single_error(single_error),
        .double_error(double_error)

    );


    // ---------------------------------------------------------
    // Clock Generation
    // ---------------------------------------------------------

    always #5 clk = ~clk;


    // ---------------------------------------------------------
    // Test Sequence
    // ---------------------------------------------------------

    initial begin

        clk = 0;
        reset = 1;
        write_enable = 0;
        read_enable = 0;
        address = 0;
        write_data = 0;

        #10;

        // Release reset
        reset = 0;


        // -----------------------------------------------------
        // Test 1: Write Data
        // -----------------------------------------------------

        address = 4'd3;
        write_data = 8'b10101010;
        write_enable = 1;

        #10;

        write_enable = 0;


        // -----------------------------------------------------
        // Test 2: Read Data
        // -----------------------------------------------------

        read_enable = 1;

        #10;

        $display("Read Data = %b", read_data);
        $display("Single Error = %b", single_error);
        $display("Double Error = %b", double_error);


        // -----------------------------------------------------
        // Test 3: Inject Single-Bit Error
        // -----------------------------------------------------

        read_enable = 0;

        // Flip one stored bit
        DUT.memory[3][2] = ~DUT.memory[3][2];

        #10;

        read_enable = 1;

        #10;

        $display("--------------------------------");
        $display("Single Bit Error Test");
        $display("Read Data = %b", read_data);
        $display("Single Error = %b", single_error);
        $display("Double Error = %b", double_error);


        // -----------------------------------------------------
        // Test 4: Inject Double-Bit Error
        // -----------------------------------------------------

        read_enable = 0;

        DUT.memory[3][2] = ~DUT.memory[3][2];
        DUT.memory[3][4] = ~DUT.memory[3][4];

        #10;

        read_enable = 1;

        #10;

        $display("--------------------------------");
        $display("Double Bit Error Test");
        $display("Read Data = %b", read_data);
        $display("Single Error = %b", single_error);
        $display("Double Error = %b", double_error);


        #20;

        $finish;

    end

endmodule
