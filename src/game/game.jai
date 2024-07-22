GAME_SIZE :: Vector2.{640.0, 480.0};
PLAYER_SIZE :: Vector2.{15.0, 100.0};
BALL_SIZE :: Vector2.{10.0, 10.0};
PLAYER_BORDER_OFFSET :: 50.0;
PLAYER_SPEED :: 6.0;
BALL_SPEED :: 8.0;
BALL_MAX_ANGLE :: 65.0;
PLAYER_MAX_ACTION_ANGLE :: 40.0;
SCORE_LIMIT :: 9;

GameState :: enum
{
	None;
	Engage;
	Playing;
	Scored;
	GameOver;
}

Game :: struct
{
	players: [2]Player;
	ball: Ball;

	frame_number: int;
	state: GameState;
	score: [2]int;
	just_scored_player: int;
	state_timer: int;
	seed: u64;
}

game_init :: (using game: *Game)
{
	players[0].position = .{PLAYER_BORDER_OFFSET, GAME_SIZE.y * 0.5};
	players[1].position = .{GAME_SIZE.x - PLAYER_BORDER_OFFSET, GAME_SIZE.y * 0.5};

	game_reset(game);
}

game_shutdown :: (using game: *Game)
{

}

game_update :: (using game: *Game, input: [2]int)
{

}

game_draw :: (using game: *Game)
{
	for i: 0..1
	{
		player_draw(*players[i]);
	}
	// ball_draw(*ball);
}

game_reset :: (using game: *Game)
{
	seed = cast(u64) (GetTime() * 10000.0);
	random_seed(seed);

	just_scored_player = -1;
	frame_number = 0;
	score[0] = 0;
	score[1] = 0;
	state_timer = 0;

	game_set_state(game, .Engage);
}

#scope_file

game_set_state :: (game: *Game, state: GameState)
{

}

#import "Random";