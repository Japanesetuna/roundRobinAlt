module roundRobin #(
    parameter DATA_W = 8
)(
    input  logic              clk,
    input  logic              rst_n,

    input  logic [3:0]        req,
    input  logic [3:0]        valid,
    input  logic [3:0]        last,

    input  logic [DATA_W-1:0] data_a,
    input  logic [DATA_W-1:0] data_b,
    input  logic [DATA_W-1:0] data_c,
    input  logic [DATA_W-1:0] data_d,

    output logic [3:0]        grant,
    output logic              out_valid,
    output logic              out_last,
    output logic [DATA_W-1:0] out_data
);

    logic [3:0] grant_reg;
    logic [3:0] mask;
    logic [3:0] next_mask;
    logic [3:0] next_grant;

    assign grant = grant_reg;

    function automatic logic [3:0] pick;
        input logic [3:0] req_i;
        input logic [3:0] mask_i;

        logic [3:0] masked_req;

        begin
            masked_req = req_i & mask_i;
            pick = 4'b0000;

            if (masked_req[0])
                pick = 4'b0001;
            else if (masked_req[1])
                pick = 4'b0010;
            else if (masked_req[2])
                pick = 4'b0100;
            else if (masked_req[3])
                pick = 4'b1000;

            else if (req_i[0])
                pick = 4'b0001;
            else if (req_i[1])
                pick = 4'b0010;
            else if (req_i[2])
                pick = 4'b0100;
            else if (req_i[3])
                pick = 4'b1000;
        end
    endfunction

    always_comb begin
        next_mask = mask;

        case (grant_reg)
            4'b0001: next_mask = 4'b1110;
            4'b0010: next_mask = 4'b1100;
            4'b0100: next_mask = 4'b1000;
            4'b1000: next_mask = 4'b1111;
            default: next_mask = mask;
        endcase

        next_grant = pick(req, next_mask);
    end

    always_comb begin
        out_valid = 1'b0;
        out_last  = 1'b0;
        out_data  = '0;

        case (grant_reg)
            4'b0001: begin
                out_valid = valid[0];
                out_last  = last[0];
                out_data  = data_a;
            end

            4'b0010: begin
                out_valid = valid[1];
                out_last  = last[1];
                out_data  = data_b;
            end

            4'b0100: begin
                out_valid = valid[2];
                out_last  = last[2];
                out_data  = data_c;
            end

            4'b1000: begin
                out_valid = valid[3];
                out_last  = last[3];
                out_data  = data_d;
            end
        endcase
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            grant_reg <= 4'b0000;
            mask      <= 4'b1111;
        end
        else begin

            // Idle: choose any request
            if (grant_reg == 4'b0000) begin
                grant_reg <= pick(req, mask);
            end

            // Current stream finished
            else if (out_valid && out_last) begin
                mask      <= next_mask;
                grant_reg <= next_grant;
            end

            // If no requests exist after finishing, next_grant is 0000,
            // so arbiter naturally idles.
        end
    end

endmodule
