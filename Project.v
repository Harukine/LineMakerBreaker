//line maker breaker project

module Project
		(
			CLOCK_50,
			SW,
			KEY,
			HEX0, HEX1,
			// The ports below are for the VGA output.  Do not change.
			VGA_CLK,   						//	VGA Clock
			VGA_HS,							//	VGA H_SYNC
			VGA_VS,							//	VGA V_SYNC
			VGA_BLANK,						//	VGA BLANK
			VGA_SYNC,						//	VGA SYNC
			VGA_R,   						//	VGA Red[9:0]
			VGA_G,	 						//	VGA Green[9:0]
			VGA_B   							//	VGA Blue[9:0]
		);
		
		//DeSoc Assignments
		input CLOCK_50;			//50 Mhz
		input [9:0] SW;			
		input [3:0] KEY;			
		
		output			VGA_CLK;   				//	VGA Clock
		output			VGA_HS;					//	VGA H_SYNC
		output			VGA_VS;					//	VGA V_SYNC
		output			VGA_BLANK;				//	VGA BLANK
		output			VGA_SYNC;				//	VGA SYNC
		output	[9:0]	VGA_R;   				//	VGA Red[9:0]
		output	[9:0]	VGA_G;	 				//	VGA Green[9:0]
		output	[9:0]	VGA_B;   				//	VGA Blue[9:0]
		
		//Declared variables
		wire RESET, BUTTON, Score;
		wire [8:0] x, y;
		wire [2:0] colour;
		wire writeEn;
		assign RESET = SW[0];
		assign BUTTON = KEY[3:0]; //3 = left, 2 = down, 1 = right
		assign stopped = 0;
		//Clock Speed
		speed_changer sc1(speed, CLOCK_50, RESET, CLK_Out); //changes speed based on input
		assign CLK_SPEED = (CLK_Out == 28'd0) ? 1 : 0;
		
		wire stopped;
		wire ld_state, ld_alu, alu_op;
		
		vga_adapter VGA(
			.resetn(resetn),
			.clock(CLOCK_50),
			.colour(colour),
			.x(x),
			.y(y),
			.plot(writeEn),
			/* Signals for the DAC to drive the monitor. */
			.VGA_R(VGA_R),
			.VGA_G(VGA_G),
			.VGA_B(VGA_B),
			.VGA_HS(VGA_HS),
			.VGA_VS(VGA_VS),
			.VGA_BLANK(VGA_BLANK),
			.VGA_SYNC(VGA_SYNC),
			.VGA_CLK(VGA_CLK));
		defparam VGA.RESOLUTION = "640x320";
		defparam VGA.MONOCHROME = "FALSE";
		defparam VGA.BITS_PER_COLOUR_CHANNEL = 1;
		defparam VGA.BACKGROUND_IMAGE = "black.mif";

		
		datapath d0(
					.clk(CLOCK_50),
					.clk_sped(CLK_SPEED),
					.reset(RESET),
					.ld_state(ld_state),
					);
		
		control c0(
					.clk(CLOCK_50)
					.clk_speed(CLK_SPEED)
					.reset(RESET)
					.key(BUTTON)
					);
		

endmodule


		//sequential fsm to control state of the program
module control(
	 input Clk,
	 input Clk_Speed,
	 input Reset,
	 input Button,
	 
	 output reg ld_state_out, ld_alu_out, ld_op_out
	 );
		
	 reg [5:0] current_state, next_state; 
	 reg [3:0] random_count;
	 reg [3:0] KEY_PRESSED;
	 reg STOPPED:
	
	 //Gamestates
	 localparam  S_CYCLE_INITIALIZE	= 5'd1, //Initialize Grid
                S_GAMESTART			= 5'd2, //GameStart
                S_NEW_BLOCK			= 5'd3, //Generate Block
					 S_BLOCK_MOVE			= 5'd4, //Move Block
					 S_BLOCK_COLLISION	= 5'd5, //Check Block
					 S_GRID_CHECK			= 5'd6, //Clear Line and Gameover Checks
					 S_GAMEOVER				= 5'd7; //Game Over
					 
					 
	 //Key actions
	 localparam	 NONE						= 3'd0,
					 DOWN						= 3'd1,
					 LEFT						= 3'd2,
					 RIGHT					= 3'd3;
    
	 initial begin //generates random number for blocks
					 random_count = $random;
				end
				
	 always@(posedge Clk)
	 begin: RANDOM_NUMBER_GENERATOR
			if(random_count >= 0'b101)
					random_count <= 0;
			else
					random_count <= random_count + 1'b1;
	 
	 //Key assignments
    always@(posedge Clk)
	 begin: 
			case (Button) //Only allows one button to be pressed at a time
				KEY[0]: begin //assign last button pressed
					end
				KEY[1]: begin
					KEY_PRESSED <= RIGHT;
					end
				KEY[2]: begin
					KEY_PRESSED <= DOWN;
					end
				KEY[3]: begin
					KEY_PRESSED <= LEFT;
					end
	 
    // Next state logic aka our state table
    always@(*)
    begin: state_table 
            case (current_state)
                S_CYCLE_INITIALIZE: next_state = S_GAMESTART;
					 S_GAMESTART: next_state = S_NEW_BLOCK;
					 S_NEW_BLOCK: next_state = BLOCK_MOVE;
                S_BLOCK_MOVE: next_state = S_BLOCK_COLLSION; 
					 S_BLOCK_COLLISION: next_state = STOPPED ? S_GRID_CHECK : S_BLOCK_MOVE; //moves to state 2 5 or 6
					 S_GRID_CHECK: next_state = STOPPED ? S_GAMEOVER : S_GAMESTART; //moves to state 2 after clear line
					 S_GAMEOVER: next_state = S_CYCLE_INITIALIZE; //game over state
            default:     next_state = S_CYCLE_INITIALIZE;
        endcase
    end // state_table
   

    // Output logic aka all of our datapath control signals
    always @(*)
    begin: enable_signals
        // By default make all our signals 0
        ld_state_out = 1'b0;
		  ld_alu_out = 1'b0;
		  ld_alu_op = 1'b0;
			
		if (RST == 1'b0) begin
			// The following have to be initialized here because it will be used in INIT state
			// will clear grid ram
			end
		case (current_state)
			S_CYCLE_INITIALIZE: begin
					if(Reset)
					begin //resets entire game
						ld_state_out = S_CYCLE_INITIALIZE;
						ld_alu_out = COLOR;
						ld_alu_op = CLEAR_SCREEN;
					end
            S_GAMESTART: begin
                //game state
					end
				S_NEW_BLOCK: begin
                ld_state_out = S_NEW_BLOCK;
					 ld_alu_out = GENERATE;
					 ld_alu_op = RANDOM_NUM;
					end
				S_BLOCK_MOVE: begin //check which button is pressed and do function
                ld_state_out = S_BLOCK_MOVE;
					 ld_alu_out = MOVE;
					 ld_alu_op = KEY_PRESSED;
					end
				S_BLOCK_COLLISION: begin //check if block can still move or stop
					 ld_state_out = S_BLOCK_COLLISION;
					 ld_alu_out = CHECK;
				end
				S_GRID_CHECK: begin //break line or gameover
					 ld_state_out = S_GRID_CHECK;
					 ld_alu_out = GRID_CHECK;
				end
				S_GAMEOVER: begin
					//gameover
				end
        // default:    // don't need default
        endcase
    end // enable_signals
   
    always@(posedge Clk)
    begin: state_FFs
        if(Reset)
            current_state <= S_CYCLE_INITIALIZE;
        else
            current_state <= next_state;
    end // state_FFS
	 
endmodule


//moves data with combinational logic  
module datapath(
    input clk,
    input resetn,
    input [4:0] state_in, alu_in, alu_op
    output reg [7:0] data_result
    );
   
	//GAMESTARTED
	always(*)
	begin: GAMESTART
	
	end
	
	//BLOCK GENERATOR
	always(*)
	begin : GENERATE
		case (SHAPE_OP)
			0: begin
				//First Shape
				end
	end
	
	//BLOCK MOVER
	always(*)
	begin : MOVE
		case (BUTTON_OP)
			NONE: begin
				//do nothing
				end
			DOWN: begin
				//change clk speed
				end
			LEFT: begin
				//tries to move left
				end
			RIGHT: begin
				//tries to move right
				end
	
	//BLOCK CHECKER
	always@(*)
	begin : CHECK_BLOCK
		case (CHECK_OP)
			CHECK_COLLISION: begin
						//check if next block is already filled
						end
			CHECK_ROW: begin
						//checks row for a color
						end
			CHECK_TOP: begin
						//check if there's a color at top row for gameover
						end
	end
	
	//GRID CHECKER
	always@(*)
	begin : GRID_CHECK
		case (GRID_OP)
			CHECK_ROW: begin
						//checks row for a color
						end
			CHECK_TOP: begin
						//check if there's a color at top row for gameover
						end
	end
	
	// GRID GOLOR ALU
	always@(*)
	begin : COLOR
		case (COLOR_OP)
			CLEAR_SCREEN: begin
							for (i = 0; i<127; i = i+1)
								begin
									grid_ram clear(i, clk, 0, 1, c_out);
								end
							end
			MOVE_PIXEL: begin
							//Moves the object along grid
							end
			CLEAR_LINE: begin
							//Clears a row if all are non-0 blocks
							end
			
   end

//	always@(*)
//	begin : SCORE_COUNTER
//		case (SCORE_OP)
//			RESET_SCORE:
//	
	
	 
	 //grid_ram gr1(address, clock, data, write_enable, q_out)
    
endmodule



//changes speed of clock
module speed_changer(speed_set, clk, clear_b, clk_out);
	
	input clk, clear_b;
	input speed_set;
	output [27:0] clk_out;
	reg [27:0] counter;
	
	always @ (posedge clk or negedge clear_b)
	begin	
		if (~clear_b)
			counter <= 28'd0;
		else if ((speed_set == 1'b0) && (counter == 28'd500000000))
			counter <= 28'd0;
		else if ((speed_set == 1'b1) && (counter == 28'd50000000))
			counter <= 28'd0;
		else
			counter <= counter + 1;
	end

	assign clk_out = counter;

endmodule


//score display
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
			