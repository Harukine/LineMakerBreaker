//line maker breaker project

module Project(
			input SW,
			input KEY,
			output HEX0, HEX1
			);


module main(
			input clock,
			input reset,
			input key_data,
			output x_sync,
			output y_sync,
			output score
			);
			
				rate_divider r1(SW[1:0], CLOCK_50, SW[2], rate_d);
				assign enabled = (rate_d == 28'd0) ? 1 : 0;
	
				
endmodule






module control(
    input clk,
    input resetn,
    input button,
    output reg [1:0]  select_a, select_b,
    output reg op
    );

    reg [5:0] current_state, next_state; 
    
    localparam  S_CYCLE_0       = 5'd1,
                S_CYCLE_1       = 5'd2,
                S_CYCLE_2       = 5'd3,
					 S_CYCLE_3       = 5'd4,
					 S_CYCLE_4       = 5'd5,
					 S_CYCLE_5 		  = 5'd6;
    
    // Next state logic aka our state table
    always@(*)
    begin: state_table 
            case (current_state)
                S_CYCLE_0: next_state = S_CYCLE_1;
					 S_CYCLE_1: next_state = S_CYCLE_2;
					 S_CYCLE_2: next_state = S_CYCLE_3;
                S_CYCLE_3: next_state = S_CYCLE_4; 
					 S_CYCLE_4: next_state = S_CYCLE_5; 
					 S_CYCLE_5: next_state = S_CYCLE_0; 
            default:     next_state = S_CYCLE_0;
        endcase
    end // state_table
   

    // Output logic aka all of our datapath control signals
    always @(*)
    begin: enable_signals
        // By default make all our signals 0
        button = 1'b0;
        select_a = 2'b0;
        select_b = 2'b0;
        op       = 1'b0;

        case (current_state)
            S_CYCLE_0: begin
                //do something
					end
            S_CYCLE_1: begin
                //do next
					end
				S_CYCLE_2: begin
                //do next
					end
				S_CYCLE_3: begin
                //do next
					end
				S_CYCLE_4: begin
				 //do next
				end
				S_CYCLE_5: begin
				 //do next
				end
        // default:    // don't need default since we already made sure all of our outputs were assigned a value at the start of the always block
        endcase
    end // enable_signals
   
    
endmodule






module datapath(
    input clk,
    input resetn,
    input [7:0] data_in,
    input [1:0] select_a, select_b,
    output reg [7:0] data_result
    );
    
   
    // The ALU 
    always @(*)
    begin : ALU
        // alu
        case (op)
            0: begin
                   //left
               end
            1: begin
                   //right
               end
				2: begin
						//down
					end
            //default: alu_out = 8'b0;
        endcase
    end
    
endmodule


module rate_divider(pulse, clk, clear_b, clk_out);
	
	input clk, clear_b;
	input pulse;
	output [27:0] clk_out;
	reg [27:0] counter;
	
	always @ (posedge clk or negedge clear_b)
	begin	
		if (~clear_b)
			counter <= 28'd0;
		else if ((pulse == 1'b0) && (counter == 28'd100000000))
			counter <= 28'd0;
		else if ((pulse == 1'b1) && (counter == 28'd300000000))
			counter <= 28'd0;
		else
			counter <= counter + 1;
	end

	assign clk_out = counter;

endmodule




module hex_decoder(hex_digit, segments);
    input [3:0] hex_digit;
    output reg [6:0] segments;
   
    always @(*)
        case (hex_digit)
            4'h0: segments = 7'b100_0000;
            4'h1: segments = 7'b111_1001;
            4'h2: segments = 7'b010_0100;
            4'h3: segments = 7'b011_0000;
            4'h4: segments = 7'b001_1001;
            4'h5: segments = 7'b001_0010;
            4'h6: segments = 7'b000_0010;
            4'h7: segments = 7'b111_1000;
            4'h8: segments = 7'b000_0000;
            4'h9: segments = 7'b001_1000;
            4'hA: segments = 7'b000_1000;
            4'hB: segments = 7'b000_0011;
            4'hC: segments = 7'b100_0110;
            4'hD: segments = 7'b010_0001;
            4'hE: segments = 7'b000_0110;
            4'hF: segments = 7'b000_1110;   
            default: segments = 7'h7f;
        endcase
endmodule
			