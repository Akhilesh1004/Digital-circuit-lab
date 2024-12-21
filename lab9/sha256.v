module sha256(
    input clk,
    input reset,
    input [71:0] input_number, // 9 ASCII digits, 72 bits total
    output done,           // Indicates when hashing is complete
    output [255:0] hash,    // Final 256-bit hash output
    output [71:0] answer_number
);

    // SHA-256 constants
    reg [31:0] k [0:63];
    initial begin
        k[ 0] = 32'h428a2f98; k[ 1] = 32'h71374491; k[ 2] = 32'hb5c0fbcf; k[ 3] = 32'he9b5dba5;
        k[ 4] = 32'h3956c25b; k[ 5] = 32'h59f111f1; k[ 6] = 32'h923f82a4; k[ 7] = 32'hab1c5ed5;
        k[ 8] = 32'hd807aa98; k[ 9] = 32'h12835b01; k[10] = 32'h243185be; k[11] = 32'h550c7dc3;
        k[12] = 32'h72be5d74; k[13] = 32'h80deb1fe; k[14] = 32'h9bdc06a7; k[15] = 32'hc19bf174;
        k[16] = 32'he49b69c1; k[17] = 32'hefbe4786; k[18] = 32'h0fc19dc6; k[19] = 32'h240ca1cc;
        k[20] = 32'h2de92c6f; k[21] = 32'h4a7484aa; k[22] = 32'h5cb0a9dc; k[23] = 32'h76f988da;
        k[24] = 32'h983e5152; k[25] = 32'ha831c66d; k[26] = 32'hb00327c8; k[27] = 32'hbf597fc7;
        k[28] = 32'hc6e00bf3; k[29] = 32'hd5a79147; k[30] = 32'h06ca6351; k[31] = 32'h14292967;
        k[32] = 32'h27b70a85; k[33] = 32'h2e1b2138; k[34] = 32'h4d2c6dfc; k[35] = 32'h53380d13;
        k[36] = 32'h650a7354; k[37] = 32'h766a0abb; k[38] = 32'h81c2c92e; k[39] = 32'h92722c85;
        k[40] = 32'ha2bfe8a1; k[41] = 32'ha81a664b; k[42] = 32'hc24b8b70; k[43] = 32'hc76c51a3;
        k[44] = 32'hd192e819; k[45] = 32'hd6990624; k[46] = 32'hf40e3585; k[47] = 32'h106aa070;
        k[48] = 32'h19a4c116; k[49] = 32'h1e376c08; k[50] = 32'h2748774c; k[51] = 32'h34b0bcb5;
        k[52] = 32'h391c0cb3; k[53] = 32'h4ed8aa4a; k[54] = 32'h5b9cca4f; k[55] = 32'h682e6ff3;
        k[56] = 32'h748f82ee; k[57] = 32'h78a5636f; k[58] = 32'h84c87814; k[59] = 32'h8cc70208;
        k[60] = 32'h90befffa; k[61] = 32'ha4506ceb; k[62] = 32'hbef9a3f7; k[63] = 32'hc67178f2;
    end

    // Internal variables and registers
    reg [511:0] message;       // Padded input message block
    reg [31:0] h [0:7];        // Hash state variables
    reg [31:0] W [0:63];       // Message schedule
    reg [31:0] a, b, c, d, e, f, g, h_temp, sum0,Ch,sum1,Maj, p,q,r,x;
    reg [31:0] temp1, temp2;
    reg [6:0] round;           // Round counter (0 to 63)
    reg hashing;               // Indicates hashing in progress
    reg [71:0] prev_input, answer;     // Tracks previous input
    reg [255:0] hash_reg;
    reg done_reg;
    reg [2:0] pipe;
    assign done = done_reg;
    assign hash = hash_reg;
    assign answer_number = answer;
    
    

    // Reset and initial state
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            done_reg <= 0;
            hash_reg <= 0;
            round <= 0;
            hashing <= 0;
            prev_input <= 0;
            pipe <= 0;
            h[0] <= 32'h6a09e667; h[1] <= 32'hbb67ae85;
            h[2] <= 32'h3c6ef372; h[3] <= 32'ha54ff53a;
            h[4] <= 32'h510e527f; h[5] <= 32'h9b05688c;
            h[6] <= 32'h1f83d9ab; h[7] <= 32'h5be0cd19;
            a <= 32'h6a09e667; b <= 32'hbb67ae85;
            c <= 32'h3c6ef372; d <= 32'ha54ff53a;
            e <= 32'h510e527f; f <= 32'h9b05688c;
            g <= 32'h1f83d9ab; h_temp <= 32'h5be0cd19;
        end else begin
            if (input_number != prev_input) begin
                // Prepare new message block with padding
                prev_input <= input_number;
                message <= {input_number, 1'b1, {(375){1'b0}}, 64'd72};
                hashing <= 1;
                round <= 0;
                done_reg <= 0;

                // Initialize hash values
                h[0] <= 32'h6a09e667; h[1] <= 32'hbb67ae85;
                h[2] <= 32'h3c6ef372; h[3] <= 32'ha54ff53a;
                h[4] <= 32'h510e527f; h[5] <= 32'h9b05688c;
                h[6] <= 32'h1f83d9ab; h[7] <= 32'h5be0cd19;

                // Initialize working variables
                a <= 32'h6a09e667; b <= 32'hbb67ae85;
                c <= 32'h3c6ef372; d <= 32'ha54ff53a;
                e <= 32'h510e527f; f <= 32'h9b05688c;
                g <= 32'h1f83d9ab; h_temp <= 32'h5be0cd19;
            end

            if (hashing) begin
                if(round < 64) begin
                    case(pipe)
                        2'd0:begin
                            if(round<16)
                                W[round] <= message[511-32*round -: 32];
                            else if(round < 64) begin
                                p <= {W[round-2][16:0],W[round-2][31:17]}^{W[round-2][18:0],W[round-2][31:19]}^(W[round-2]>>10);
                                q <= W[round-7];
                                r <= {W[round-15][6:0],W[round-15][31:7]}^{W[round-15][17:0],W[round-15][31:18]}^(W[round-15]>>3);
                                x <= W[round-16];
                            end
                            pipe <= 2'd1;
                        end 
                        2'd1: begin
                            if(round>=16) W[round] <= p + q + r +x;
                            sum1 <= {e[5:0],e[31:6]}^{e[10:0],e[31:11]}^{e[24:0],e[31:25]};
                            sum0 <= {a[1:0],a[31:2]}^{a[12:0],a[31:13]}^{a[21:0],a[31:22]};
                            Ch <= (e&f)^((~e)&g);
                            Maj <= (a&b)^(b&c)^(c&a);
                            pipe <= 2;
                        end 
                        2'd2: begin
                            temp1 <= h_temp + sum1 + Ch +k[round] + W[round];
                            temp2 <= sum0 + Maj;
                            pipe <= 3;
                        end
                        2'd3: begin
                            h_temp <= g;
                            g <= f;
                            f <= e;
                            e <= d + temp1;
                            d <= c;
                            c <= b;
                            b <= a;
                            a <= temp1 + temp2;
                            pipe <= 0;
                            round <= round + 1;
                        end
                     endcase
                end else if(round == 64) begin
                    // Final hash computation
                    h[0] <= h[0] + a;
                    h[1] <= h[1] + b;
                    h[2] <= h[2] + c;
                    h[3] <= h[3] + d;
                    h[4] <= h[4] + e;
                    h[5] <= h[5] + f;
                    h[6] <= h[6] + g;
                    h[7] <= h[7] + h_temp;
                    round <= round + 1;
                end else if(round == 65) begin
                    answer <= input_number;
                    hash_reg <= {h[0], h[1], h[2], h[3], h[4], h[5], h[6], h[7]};
                    hashing <= 0;
                    done_reg <= 1;
                end
                //round <= round + 1;
            end
        end
    end

endmodule


