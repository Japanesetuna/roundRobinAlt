`timescale 1ns/1ps

module roundRobin_tb;

    localparam DATA_W = 8;

    logic clk;
    logic rst_n;

    logic [3:0] req;
    logic [3:0] valid;
    logic [3:0] last;

    logic [DATA_W-1:0] data_a;
    logic [DATA_W-1:0] data_b;
    logic [DATA_W-1:0] data_c;
    logic [DATA_W-1:0] data_d;

    logic [3:0] grant;
    logic out_valid;
    logic out_last;
    logic [DATA_W-1:0] out_data;

    roundRobin #(
        .DATA_W(DATA_W)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),

        .req(req),
        .valid(valid),
        .last(last),

        .data_a(data_a),
        .data_b(data_b),
        .data_c(data_c),
        .data_d(data_d),

        .grant(grant),
        .out_valid(out_valid),
        .out_last(out_last),
        .out_data(out_data)
    );

    always #5 clk = ~clk;

    task automatic show;
        begin
            $display("t=%0t grant=%b req=%b valid=%b last=%b out_valid=%b out_last=%b out_data=%h",
                     $time, grant, req, valid, last, out_valid, out_last, out_data);
        end
    endtask

    task automatic one_cycle;
        begin
            @(posedge clk);
            #1;
            show();
        end
    endtask

    initial begin
        clk = 0;
        rst_n = 0;

        req   = 4'b0000;
        valid = 4'b0000;
        last  = 4'b0000;

        data_a = 8'h00;
        data_b = 8'h00;
        data_c = 8'h00;
        data_d = 8'h00;

        repeat (2) @(posedge clk);
        rst_n = 1;

        // ----------------------------------------------------
        // TEST 1: A, B, C request. Serve full A first.
        // ----------------------------------------------------
        $display("\nTEST 1: serve full A stream first");

        req   = 4'b0111;   // A, B, C request
        valid = 4'b0001;

        data_a = 8'hA1;
        last   = 4'b0000;
        one_cycle();

        data_a = 8'hA2;
        last   = 4'b0000;
        one_cycle();

        data_a = 8'hA3;
        last   = 4'b0001;
        req[0] = 1'b0;     // A finishes, drop request before clock edge
        one_cycle();

        last = 4'b0000;

        // ----------------------------------------------------
        // TEST 2: Should switch to B.
        // ----------------------------------------------------
        $display("\nTEST 2: switch to B after A ends");

        valid = 4'b0010;

        data_b = 8'hB1;
        last   = 4'b0000;
        one_cycle();

        data_b = 8'hB2;
        last   = 4'b0010;
        req[1] = 1'b0;     // B finishes
        one_cycle();

        last = 4'b0000;

        // ----------------------------------------------------
        // TEST 3: Should switch to C.
        // ----------------------------------------------------
        $display("\nTEST 3: serve C next");

        valid = 4'b0100;

        data_c = 8'hC1;
        last   = 4'b0100;
        req[2] = 1'b0;     // C finishes
        one_cycle();

        valid = 4'b0000;
        last  = 4'b0000;

        // ----------------------------------------------------
        // TEST 4: Only D requests. Should skip directly to D.
        // ----------------------------------------------------
        $display("\nTEST 4: skip directly to D");

        req   = 4'b1000;
        valid = 4'b1000;
        data_d = 8'hD1;
        last   = 4'b1000;
        req[3] = 1'b0;     // D finishes, no more requests
        one_cycle();

        valid = 4'b0000;
        last  = 4'b0000;

        // ----------------------------------------------------
        // TEST 5: No request. Should idle.
        // ----------------------------------------------------
        $display("\nTEST 5: idle when no request");

        repeat (3) one_cycle();

        $display("\nAll tests finished.");
        $finish;
    end

endmodule
