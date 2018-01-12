module FINAL_PCPI(
	input                clk, resetn,
	input                pcpi_valid,
	input         [31:0] pcpi_insn,
	input         [31:0] pcpi_rs1,
	input         [31:0] pcpi_rs2,
	output  reg          pcpi_wr,
	output  reg   [31:0] pcpi_rd,
	output  reg          pcpi_wait,
	output  reg          pcpi_ready,
	//memory interface
	input         [31:0] mem_rdata,
	input                mem_ready,
	output   reg         mem_valid,
	output   reg         mem_write,
	output   reg  [31:0] mem_addr,
	output   reg  [31:0] mem_wdata
);
	wire pcpi_insn_valid = pcpi_valid && pcpi_insn[6:0] == 7'b0101011 && pcpi_insn[31:25] == 7'b0000001;

	// parameter state 
	parameter IDLE = 4'b0000;

	parameter READREPLY = 4'b0001;
	parameter READNEWLINE = 4'b0010;
	
	parameter READPIXEL1 = 4'b0011;
	parameter READPIXEL2 = 4'b0100;
	parameter READPIXEL3 = 4'b0101;
	parameter AVERAGECOLOR = 4'b0110;

	parameter STARTCHESSBOARD = 4'b0111;
	parameter CHESSBOARD_1 = 4'b1000;
	parameter CHESSBOARD_2 = 4'b1001;
	parameter CHESSBOARD_3 = 4'b1010;
	parameter CHESSBOARD_4 = 4'b1011;
	parameter CHESSBOARD_5 = 4'b1100;
	parameter ENDCHESSBOARD = 4'b1101;

	// parameter represent 
	parameter IMAGE_OFFSET = 32'h0001_0000;
	parameter DATA_LENGTH = 32'd14400; // 60*80*3
	parameter SEG_LENGTH = 32'd4800; // 60*80
	parameter MAX_SHADES = 32'd10;

	reg [3:0] state;
	reg [3:0] state_next;

	reg [31:0] char;
	reg [31:0] newline;

	integer image_file; 
	reg [31:0] pixel_1;
	reg [31:0] pixel_2;
	reg [31:0] pixel_3;
	reg [31:0] average_color;

	reg [7:0] shade[9:0];

	// variable for chessboard
	reg [31:0] chessboard_0[2:0];
	reg [31:0] chessboard_1[2:0];
	reg [31:0] chessboard_2[2:0];
	reg [31:0] chess_num;
	reg [31:0] check[7:0];
	integer i;
	reg [31:0] status;

	// hard_final_pcpi(rs1, rs2)
	// rs1 
	//     0 : read data from stdin
	//     1 : playerwin
	//	   2 : playerlose
	//     3 : tie
	//     4 : check game status start to receive the information
	// 	   5 : check game status start to compute 		
	// rs2 
	// 	   rs1 1~3 : pixel pos
	// 	   rs2 4-> : imformation
	
	always@(posedge clk or negedge resetn)begin
		if(!resetn)begin
			state <= IDLE;
		end else begin
			state <= state_next;
		end
	end

	always@(*)begin
		state_next = state;

		pcpi_wr = 1'b0;
		pcpi_wait = 1'b1;
		pcpi_ready = 1'b0;
		pcpi_rd = 32'd0;

		case(state)
			IDLE: begin
				if(pcpi_insn_valid)begin
					if(pcpi_rs1 == 32'd0)begin
						state_next = READREPLY;
					end else if(pcpi_rs1 == 32'd1 || pcpi_rs1 == 32'd2 || pcpi_rs1 == 32'd3)begin
						// initialize
						shade[0] = 8'd35; // #
						shade[1] = 8'd36; // $
						shade[2] = 8'd79; // O
						shade[3] = 8'd61; // =
						shade[4] = 8'd43; // +
						shade[5] = 8'd38; // &
						shade[6] = 8'd64; // @
						shade[7] = 8'd94; // ^
						shade[8] = 8'd46; // .
						shade[9] = 8'd32; // " "
						state_next = READPIXEL1;
					end else if(pcpi_rs1 == 32'd4)begin
						state_next = STARTCHESSBOARD;
					end else if(pcpi_rs1 == 32'd5)begin
						state_next = ENDCHESSBOARD;
					end
				end
			end
			READREPLY: begin
				char = $fgetc('h8000_0000);
				state_next = READNEWLINE;
			end
			READNEWLINE: begin
				newline = $fgetc('h8000_0000);
				pcpi_wr = 1'b1;
				pcpi_wait = 1'b0;
				pcpi_ready = 1'b1;
				pcpi_rd = char;
				state_next = IDLE;
			end
			READPIXEL1: begin
				mem_write = 1'b0;
				mem_valid = 1'b1;
				mem_addr = IMAGE_OFFSET + ((pcpi_rs1 - 32'd1) * DATA_LENGTH + pcpi_rs2) * 32'd4;

				state_next = READPIXEL2;
			end
			READPIXEL2: begin
				mem_write = 1'b0;
				mem_valid = 1'b1;
				mem_addr = IMAGE_OFFSET + ((pcpi_rs1 - 32'd1) * DATA_LENGTH + (pcpi_rs2 + SEG_LENGTH)) * 32'd4;
				pixel_1 = mem_rdata;

				state_next = READPIXEL3;
			end
			READPIXEL3: begin
				mem_write = 1'b0;
				mem_valid = 1'b1;
				mem_addr = IMAGE_OFFSET + ((pcpi_rs1 - 32'd1) * DATA_LENGTH + (pcpi_rs2 + SEG_LENGTH * 32'd2)) * 32'd4;
				pixel_2 = mem_rdata;

				state_next = AVERAGECOLOR;
			end
			AVERAGECOLOR: begin
				mem_write = 1'b0;
				mem_valid = 1'b1;
				pixel_3 = mem_rdata;

				average_color = (pixel_1 + pixel_2 + pixel_3) / 3;

				// Convert to a shade
	      		average_color = average_color / (32'd256 / MAX_SHADES);
	     		if(average_color >= MAX_SHADES)begin
	        		average_color = MAX_SHADES-1;
	        	end
	        	
	        	pcpi_wr = 1'b1;
				pcpi_wait = 1'b0;
				pcpi_ready = 1'b1;
				pcpi_rd = shade[average_color];
				
				state_next = IDLE;
			end
			STARTCHESSBOARD: begin
				pcpi_wr = 1'b1;
				pcpi_wait = 1'b0;
				pcpi_ready = 1'b1;
				pcpi_rd = 32'd0;
				state_next = CHESSBOARD_1;
			end
			CHESSBOARD_1: begin
				if(pcpi_insn_valid)begin
					chessboard_0[0] = pcpi_rs1;
					chessboard_0[1] = pcpi_rs2;

					pcpi_wr = 1'b1;
					pcpi_wait = 1'b0;
					pcpi_ready = 1'b1;
					pcpi_rd = 32'd0;
					state_next = CHESSBOARD_2;
				end
			end
			CHESSBOARD_2: begin
				if(pcpi_insn_valid)begin
					chessboard_0[2] = pcpi_rs1;
					chessboard_1[0] = pcpi_rs2;

					pcpi_wr = 1'b1;
					pcpi_wait = 1'b0;
					pcpi_ready = 1'b1;
					pcpi_rd = 32'd0;
					state_next = CHESSBOARD_3;
				end
			end
			CHESSBOARD_3: begin
				if(pcpi_insn_valid)begin
					chessboard_1[1] = pcpi_rs1;
					chessboard_1[2] = pcpi_rs2;

					pcpi_wr = 1'b1;
					pcpi_wait = 1'b0;
					pcpi_ready = 1'b1;
					pcpi_rd = 32'd0;
					state_next = CHESSBOARD_4;
				end
			end
			CHESSBOARD_4: begin
				if(pcpi_insn_valid)begin
					chessboard_2[0] = pcpi_rs1;
					chessboard_2[1] = pcpi_rs2;

					pcpi_wr = 1'b1;
					pcpi_wait = 1'b0;
					pcpi_ready = 1'b1;
					pcpi_rd = 32'd0;
					state_next = CHESSBOARD_5;
				end
			end
			CHESSBOARD_5: begin
				if(pcpi_insn_valid)begin
					chessboard_2[2] = pcpi_rs1;
					chess_num = pcpi_rs2;

					pcpi_wr = 1'b1;
					pcpi_wait = 1'b0;
					pcpi_ready = 1'b1;
					pcpi_rd = 32'd0;
					state_next = IDLE;
				end
			end
			ENDCHESSBOARD: begin
				for(i=32'd0; i<32'd8; i=i+1)begin
					check[i] = 32'd0;
 				end
 				status = 32'd0;

 				check[0] = chessboard_0[0] + chessboard_1[0] + chessboard_2[0];
 				check[1] = chessboard_0[1] + chessboard_1[1] + chessboard_2[1];
 				check[2] = chessboard_0[2] + chessboard_1[2] + chessboard_2[2];
 				check[3] = chessboard_0[0] + chessboard_0[1] + chessboard_0[2];
 				check[4] = chessboard_1[0] + chessboard_1[1] + chessboard_1[2];
 				check[5] = chessboard_2[0] + chessboard_2[1] + chessboard_2[2];
 				check[6] = chessboard_0[0] + chessboard_1[1] + chessboard_2[2];
 				check[7] = chessboard_0[2] + chessboard_1[1] + chessboard_2[0]; 

				for(i=32'd0; i<32'd8; i=i+32'd1)begin
					if(check[i] == 32'd3)begin
						status = 32'd1;
					end else if(check[i] == 32'd6)begin
						status = 32'd2;
					end
				end
				if(chess_num == 32'd9 && status == 32'd0)
					status = 32'd3;
				
				pcpi_wr = 1'b1;
				pcpi_wait = 1'b0;
				pcpi_ready = 1'b1;
				pcpi_rd = status;
				state_next = IDLE;
			end
		endcase
	end
endmodule
