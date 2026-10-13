`timescale 1ns / 1ps

module tb_mmu;

    reg clk;
    reg reset;
    reg enable;
    reg [15:0] virtual_addr;
    reg access_write;

    wire [15:0] physical_addr;
    wire translation_valid;
    wire page_fault;
    wire protection_fault;

    mmu uut (
        .clk(clk),
        .reset(reset),
        .enable(enable),
        .virtual_addr(virtual_addr),
        .access_write(access_write),
        .physical_addr(physical_addr),
        .translation_valid(translation_valid),
        .page_fault(page_fault),
        .protection_fault(protection_fault)
    );

    always #5 clk = ~clk;

    initial begin
        $dumpfile("waveforms/mmu_wave.vcd");
        $dumpvars(0, tb_mmu);

        clk = 0;
        reset = 1;
        enable = 0;
        virtual_addr = 16'h0000;
        access_write = 0;

        #20;
        reset = 0;

        // Test 1: Valid read translation
        // Page 0, Offset AA
        // Page 0 maps to Frame 0A
        // Expected physical address = 0AAA
        #10;
        enable = 1;
        virtual_addr = 16'h00AA;
        access_write = 0;

        #10;
        $display("Test 1: Valid Read");
        $display("VA = %h, PA = %h, Valid = %b, PageFault = %b, ProtectionFault = %b",
                  virtual_addr, physical_addr, translation_valid, page_fault, protection_fault);

        // Test 2: Valid write translation
        // Page 0 has write permission
        #10;
        virtual_addr = 16'h0055;
        access_write = 1;

        #10;
        $display("Test 2: Valid Write");
        $display("VA = %h, PA = %h, Valid = %b, PageFault = %b, ProtectionFault = %b",
                  virtual_addr, physical_addr, translation_valid, page_fault, protection_fault);

        // Test 3: Protection fault
        // Page 1 is valid but write permission is disabled
        #10;
        virtual_addr = 16'h0133;
        access_write = 1;

        #10;
        $display("Test 3: Protection Fault");
        $display("VA = %h, PA = %h, Valid = %b, PageFault = %b, ProtectionFault = %b",
                  virtual_addr, physical_addr, translation_valid, page_fault, protection_fault);

        // Test 4: Valid read on Page 1
        // Page 1 maps to Frame 14
        // Expected physical address = 1433
        #10;
        virtual_addr = 16'h0133;
        access_write = 0;

        #10;
        $display("Test 4: Valid Read Page 1");
        $display("VA = %h, PA = %h, Valid = %b, PageFault = %b, ProtectionFault = %b",
                  virtual_addr, physical_addr, translation_valid, page_fault, protection_fault);

        // Test 5: Page fault
        // Page 2 is invalid
        #10;
        virtual_addr = 16'h0222;
        access_write = 0;

        #10;
        $display("Test 5: Page Fault");
        $display("VA = %h, PA = %h, Valid = %b, PageFault = %b, ProtectionFault = %b",
                  virtual_addr, physical_addr, translation_valid, page_fault, protection_fault);

        // Test 6: Boundary address test
        #10;
        virtual_addr = 16'h00FF;
        access_write = 0;

        #10;
        $display("Test 6: Boundary Offset");
        $display("VA = %h, PA = %h, Valid = %b, PageFault = %b, ProtectionFault = %b",
                  virtual_addr, physical_addr, translation_valid, page_fault, protection_fault);

        #20;
        $finish;
    end

endmodule
