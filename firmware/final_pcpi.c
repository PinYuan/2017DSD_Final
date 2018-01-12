#include "firmware.h"
#define IMAGE_OFFSET 			0x00010000

#define INT_MIN                 -2147483648
#define INT_MAX                 2147483647

typedef enum Status{NOTYET, PLAYERWIN, PLAYERLOSE, TIE} Status;

void Intialize_chessboard(int chessboard[3][3], int* chess_num);
void Player_game(int chessboard[3][3]);
int Minimax(int chessboard[3][3], _Bool player, int depth, int chess_num, int alpha, int beta);
void AI_game(int chessboard[3][3], int chess_num);
void Print_chessboard(int chessboard[3][3]);
Status Check_game_status(int chessboard[3][3], int chess_num);

void final_pcpi(void)
{
	int re_play = 1;
    int player_go_first = 0;
    _Bool turn = 1;// turn 1 -> player; turn 0 -> AI

    // 1(X) represent player
    // 2(O) represent AI
    int chessboard[3][3] = {0};
    int chess_num = 0;
    Status game_status;

	while(re_play == 1){
		Intialize_chessboard(chessboard, &chess_num);

		// start the game
		print_str("Hi, welcome to Tic-Tac-Toe\n");
		print_str("Do you wanna go first? (1/0)\n");
		while(1){
            player_go_first = hard_final_pcpi(0, 0) - 48;
            if(player_go_first != 1 && player_go_first !=0)
                print_str("===Please key 1 or 0===\n");
            else
                break;
        }
		if(player_go_first) turn = 1;
		else turn = 0;

		Print_chessboard(chessboard); 
		// who turn to mark
		while(chess_num != 9){
			if(turn){
				print_str("It's player turn\n");
				Player_game(chessboard);
			}else{
				print_str("It's AI turn\n");
				AI_game(chessboard, chess_num);
			}
			
			chess_num ++;
			turn = !turn;

			Print_chessboard(chessboard); 

			game_status = Check_game_status(chessboard, chess_num);

			if(game_status != NOTYET) { 
				for(int pix=0; pix<60*80 ; pix++){
					char shade = hard_final_pcpi(game_status, pix);
					print_chr(shade);
					if((pix+1) % 80 == 0)
						print_str("\n");
				}
				break;
			}
		}

		print_str("Do you wanna play again Tic-Tac-Toe? (1/0)\n");
		re_play = hard_final_pcpi(0, 0) - 48;
	}
}


void Intialize_chessboard(int chessboard[3][3], int *chess_num){
	*chess_num = 0;
	for(int i=0; i<3; i++){
		for(int j=0; j<3; j++){
			chessboard[i][j] = INT_MIN;
		}
	}
}

void Player_game(int chessboard[3][3]){
	int player_pos = 0;
	int row = 0, col = 0;

	while(1){
		print_str("Where do you want to put your mark? (1~9)\n");
		player_pos = hard_final_pcpi(0, 0) - 48;
		row = (player_pos-1)/3;
		col = (player_pos-1)%3;

		if(row >= 0 && row <= 2 && col >=0 && col <=2){
            if(chessboard[row][col] == INT_MIN){
                chessboard[row][col] = 1;
                break;
            }else{
                print_str("=== ");
                print_dec(player_pos);
				print_str(" has been occupied===\n");
				print_str("===Please place your mark in the empty position.===\n");
            }
        }else{
            print_str("===Please key in the pos in 1~9.===\n");
        }
	}
}

int Minimax(int chessboard[3][3], _Bool player, int depth, int chess_num, int alpha, int beta){
	/*
	// software
	int start = tick();
    if(Check_game_status(chessboard, chess_num) == PLAYERWIN)
        return -10 + depth;
    else if(Check_game_status(chessboard, chess_num) == PLAYERLOSE)
        return 10 - depth;
    else if(Check_game_status(chessboard, chess_num) == TIE)
        return 0;
    int end = tick();
    print_str("software run time: ");
    print_dec(end-start);
    print_str("\n");
*/
    // harware
    //int start = tick();
    hard_final_pcpi(4, 0); // start to pass 
    hard_final_pcpi(chessboard[0][0], chessboard[0][1]);
    hard_final_pcpi(chessboard[0][2], chessboard[1][0]);
    hard_final_pcpi(chessboard[1][1], chessboard[1][2]);
    hard_final_pcpi(chessboard[2][0], chessboard[2][1]);
    hard_final_pcpi(chessboard[2][2], chess_num);
    Status status = hard_final_pcpi(5, 0); // end start to determine

    /*int end = tick();
    print_str("hardware run time: ");
    print_dec(end-start);
    print_str("\n");
    */
    if(status == PLAYERWIN)
        return -10 + depth;
    else if(status == PLAYERLOSE)
        return 10 - depth;
    else if(status == TIE)
        return 0;


    if(!player){// If this maximizer's move
        int best_score = -1000;

        // find the availble move
        for(int i=0; i<3; i++){
            for(int j=0; j<3; j++){
                if(chessboard[i][j] == INT_MIN){
                    chessboard[i][j] = 2;
                    int minimax_score = Minimax(chessboard, !player, depth+1, chess_num+1, alpha, beta);
                    chessboard[i][j] = INT_MIN;
                    
					if(minimax_score > best_score)
                        best_score = minimax_score;
                	if(best_score > alpha)
                        alpha = best_score;
                    if(beta <= alpha) return best_score;	
				}
            }
        }
        return best_score;
    }else{// If this minimizer's move
        int best_score = 1000;

        // find the availble move
        for(int i=0; i<3; i++){
            for(int j=0; j<3; j++){
                if(chessboard[i][j] == INT_MIN){
                    chessboard[i][j] = 1;
                    int minimax_score = Minimax(chessboard, !player, depth+1, chess_num+1, alpha, beta);
                    chessboard[i][j] = INT_MIN;

                    if(minimax_score < best_score)
                        best_score = minimax_score;
					if(best_score < beta)
                        beta = best_score;                 
                    if(beta <= alpha) return best_score;
                }
            }
        }
        return best_score;
    }
}

void AI_game(int chessboard[3][3], int chess_num){
    int best_score = -1000;
    int row = -1, col = -1;

    // random the first mark pos
    if(chess_num == 0){
        int pos = tick() % 9 + 1;
        row = (pos - 1) / 3;
        col = (pos - 1) % 3; 
        chessboard[row][col] = 2;
        return;
    }

    for(int i=0; i<3; i++){
        for(int j=0; j<3; j++){
            if(chessboard[i][j] == INT_MIN){
                chessboard[i][j] = 2;
                int minimax_score = Minimax(chessboard, 1, 0, chess_num+1, -1000, 1000);
                if(minimax_score > best_score){
                    best_score = minimax_score;
                    row = i;
                    col = j;
                }
                chessboard[i][j] = INT_MIN;
                /*print_dec(i);
                print_str(", ");
                print_dec(j);
                print_str(", ");
                print_dec(minimax_score);
                print_str("\n");*/
            }
        }
    }
    chessboard[row][col] = 2;
	
	/*for(int i=0; i<3; i++){
        for(int j=0; j<3; j++){
            if(chessboard[i][j] == INT_MIN){
                chessboard[i][j] = 2;
                return;
            }
        }
    }*/
}

void Print_chessboard(int chessboard[3][3]){
	for(int i=0; i<3; i++){
		for(int j=0; j<3; j++){
			if(chessboard[i][j] == 1)
				print_str("X ");
			else if(chessboard[i][j] == 2)
				print_str("O ");
			else
				print_str("- ");
		}
		print_str("\n");
	}
	print_str("-----------------\n");
}

Status Check_game_status(int chessboard[3][3], int chess_num){
	// return 0 : not yet
	// return 1 : player win
	// return 2 : player lose
	// return 3 : tie
	
	// (3*vertical, 3*horizontal, 2*cross)
	int check[8] = {0};

	for(int i=0; i<3; i++){
		// vertical
		check[0] += chessboard[i][0];
		check[1] += chessboard[i][1];
		check[2] += chessboard[i][2];
		// horizontal
		check[3] += chessboard[0][i];
		check[4] += chessboard[1][i];
		check[5] += chessboard[2][i];
	}
	// cross
	check[6] = chessboard[0][0] + chessboard[1][1] + chessboard[2][2];
	check[7] = chessboard[2][0] + chessboard[1][1] + chessboard[0][2]; 

	for(int i=0; i<8; i++){
		if(check[i] == 3){
			return PLAYERWIN;
		}else if(check[i] == 6){
			return PLAYERLOSE;
		}
	} 
	if(chess_num == 9)
		return TIE;
	else 
		return NOTYET;
}