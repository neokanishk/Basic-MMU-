`timescale 1ns / 1ps

module mmu #(
    parameter VA_WIDTH = 16,
    parameter PA_WIDTH = 16,
    parameter PAGE_OFFSET_BITS = 8,
    parameter PAGE_TABLE_ENTRIES = 256
)(
    input  wire                     clk,
    input  wire                     reset,
    input  wire                     enable,

    input  wire [VA_WIDTH-1:0]      virtual_addr,
    input  wire                     access_write,   // 0 = read, 1 = write

    output reg  [PA_WIDTH-1:0]      physical_addr,
    output reg                      translation_valid,
    output reg                      page_fault,
    output reg                      protection_fault
);

    localparam PAGE_NUMBER_BITS = VA_WIDTH - PAGE_OFFSET_BITS;
    localparam FRAME_NUMBER_BITS = PA_WIDTH - PAGE_OFFSET_BITS;

    wire [PAGE_NUMBER_BITS-1:0] page_number;
    wire [PAGE_OFFSET_BITS-1:0] page_offset;

    assign page_number = virtual_addr[VA_WIDTH-1:PAGE_OFFSET_BITS];
    assign page_offset = virtual_addr[PAGE_OFFSET_BITS-1:0];

    /*
        Page Table Entry format:

        valid_bit      : page is present or not
        read_perm      : read permission
        write_perm     : write permission
        frame_number   : physical frame number
    */

    reg valid_bit  [0:PAGE_TABLE_ENTRIES-1];
    reg read_perm  [0:PAGE_TABLE_ENTRIES-1];
    reg write_perm [0:PAGE_TABLE_ENTRIES-1];

    reg [FRAME_NUMBER_BITS-1:0] frame_number [0:PAGE_TABLE_ENTRIES-1];

    integer i;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            physical_addr      <= 0;
            translation_valid  <= 0;
            page_fault         <= 0;
            protection_fault   <= 0;

            for (i = 0; i < PAGE_TABLE_ENTRIES; i = i + 1) begin
                valid_bit[i]    <= 0;
                read_perm[i]    <= 0;
                write_perm[i]   <= 0;
                frame_number[i] <= 0;
            end

            /*
                Example page table initialization

                Page 0 -> Frame 10
                Read allowed
                Write allowed

                Page 1 -> Frame 20
                Read allowed
                Write not allowed

                Page 2 -> Invalid page
            */

            valid_bit[8'h00]    <= 1;
            read_perm[8'h00]    <= 1;
            write_perm[8'h00]   <= 1;
            frame_number[8'h00] <= 8'h0A;

            valid_bit[8'h01]    <= 1;
            read_perm[8'h01]    <= 1;
            write_perm[8'h01]   <= 0;
            frame_number[8'h01] <= 8'h14;

            valid_bit[8'h02]    <= 0;
            read_perm[8'h02]    <= 0;
            write_perm[8'h02]   <= 0;
            frame_number[8'h02] <= 8'h00;

        end else if (enable) begin

            translation_valid <= 0;
            page_fault        <= 0;
            protection_fault  <= 0;
            physical_addr     <= 0;

            if (valid_bit[page_number] == 0) begin
                page_fault <= 1;
            end else begin

                if (access_write == 0) begin
                    if (read_perm[page_number]) begin
                        physical_addr <= {frame_number[page_number], page_offset};
                        translation_valid <= 1;
                    end else begin
                        protection_fault <= 1;
                    end
                end else begin
                    if (write_perm[page_number]) begin
                        physical_addr <= {frame_number[page_number], page_offset};
                        translation_valid <= 1;
                    end else begin
                        protection_fault <= 1;
                    end
                end

            end
        end
    end

endmodule
