module memory_interface (
    input        clk,
    input        reset,
    input        write_enable,
    input        read_enable,
    input  [3:0]  address,
    input  [7:0]  write_data,

    output reg [7:0] read_data,
    output reg       single_error,
    output reg       double_error
);

    // 16 memory locations
    // Each location stores 13-bit SECDED encoded data
    reg [12:0] memory [0:15];

    integer i;

    // ---------------------------------------------------------
    // Hamming SECDED Encoder
    // Data bits = 8
    // Hamming parity bits = 4
    // Overall parity = 1
    // Total = 13 bits
    // ---------------------------------------------------------

    function [12:0] encode_data;
        input [7:0] data;
        reg [12:0] code;
        reg p1, p2, p4, p8;
        reg overall_parity;
        begin

            // Place data bits
            code = 13'b0;

            code[2]  = data[0];
            code[4]  = data[1];
            code[5]  = data[2];
            code[6]  = data[3];
            code[8]  = data[4];
            code[9]  = data[5];
            code[10] = data[6];
            code[11] = data[7];

            // Calculate Hamming parity bits
            p1 = code[2] ^ code[4] ^ code[6] ^
                 code[8] ^ code[10];

            p2 = code[2] ^ code[5] ^ code[6] ^
                 code[9] ^ code[10];

            p4 = code[4] ^ code[5] ^ code[6] ^
                 code[11];

            p8 = code[8] ^ code[9] ^ code[10] ^
                 code[11];

            code[0] = p1;
            code[1] = p2;
            code[3] = p4;
            code[7] = p8;

            // Overall parity for SECDED
            overall_parity = ^code[11:0];

            code[12] = overall_parity;

            encode_data = code;
        end
    endfunction


    // ---------------------------------------------------------
    // Write Operation
    // ---------------------------------------------------------

    always @(posedge clk) begin

        if (reset) begin

            read_data     <= 8'b0;
            single_error  <= 1'b0;
            double_error  <= 1'b0;

            for (i = 0; i < 16; i = i + 1)
                memory[i] <= 13'b0;

        end

        else begin

            // Write data into memory
            if (write_enable) begin
                memory[address] <= encode_data(write_data);
            end

        end

    end


    // ---------------------------------------------------------
    // Read + Error Detection and Correction
    // ---------------------------------------------------------

    reg [12:0] received_code;
    reg [3:0] syndrome;
    reg overall_check;

    always @(posedge clk) begin

        if (!reset && read_enable) begin

            received_code = memory[address];

            // Calculate syndrome
            syndrome[0] =
                received_code[0] ^
                received_code[2] ^
                received_code[4] ^
                received_code[6] ^
                received_code[8] ^
                received_code[10];

            syndrome[1] =
                received_code[1] ^
                received_code[2] ^
                received_code[5] ^
                received_code[6] ^
                received_code[9] ^
                received_code[10];

            syndrome[2] =
                received_code[3] ^
                received_code[4] ^
                received_code[5] ^
                received_code[6] ^
                received_code[11];

            syndrome[3] =
                received_code[7] ^
                received_code[8] ^
                received_code[9] ^
                received_code[10] ^
                received_code[11];

            // Overall parity check
            overall_check = ^received_code;

            single_error <= 1'b0;
            double_error <= 1'b0;

            // -------------------------------------------------
            // SECDED Decision
            // -------------------------------------------------

            if (overall_check == 1'b0 && syndrome == 4'b0000) begin

                // No error

                single_error <= 1'b0;
                double_error <= 1'b0;

            end

            else if (overall_check == 1'b1 && syndrome != 4'b0000) begin

                // Single-bit error
                // Correct the faulty bit

                received_code[syndrome - 1'b1] =
                    ~received_code[syndrome - 1'b1];

                single_error <= 1'b1;

            end

            else if (overall_check == 1'b1 && syndrome == 4'b0000) begin

                // Error in overall parity bit

                single_error <= 1'b1;

            end

            else begin

                // Double-bit error detected

                double_error <= 1'b1;

            end


            // Extract original 8-bit data
            read_data[0] <= received_code[2];
            read_data[1] <= received_code[4];
            read_data[2] <= received_code[5];
            read_data[3] <= received_code[6];
            read_data[4] <= received_code[8];
            read_data[5] <= received_code[9];
            read_data[6] <= received_code[10];
            read_data[7] <= received_code[11];

        end

    end

endmodule
