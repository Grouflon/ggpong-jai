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
    frame_number += 1;

    if (state == .Engage && (input[0] != 0 || input[1] != 0))
    {
        game_set_state(game, .Playing);
    }

    for i : 0..1
    {
        player_update(*players[i], input[i]);
    }

    if (state == .Playing)
    {
        ball_update(*game.ball, game);

        if (ball.position.x < -BALL_SIZE.x)
        {
            score[1] += 1;
            game_set_state(game, .Scored);
            just_scored_player = 1;
        }
        else if (ball.position.x > GAME_SIZE.x + BALL_SIZE.x)
        {
            just_scored_player = 0;
            score[0] += 1;
            game_set_state(game, .Scored);
        }
    }

    if (state != .GameOver && (score[0] >= SCORE_LIMIT || score[1] >= SCORE_LIMIT))
    {
        game_set_state(game, .GameOver);
    }

    if (state_timer > 0)
    {
        state_timer -= 1;
    }

    if (state == .Scored && state_timer == 0)
    {
        game_set_state(game, .Engage);
    }

    if (state == .GameOver && state_timer == 0)
    {
        game_reset(game);
    }
}

game_draw :: (using game: *Game)
{
    for i: 0..1
    {
        player_draw(*players[i]);
    }
    ball_draw(*ball);
}

game_reset :: (using game: *Game)
{
    seed = cast(u64) (frame_number);
    random_seed(seed);

    just_scored_player = -1;
    frame_number = 0;
    score[0] = 0;
    score[1] = 0;
    state_timer = 0;

    game_set_state(game, .Engage);
}

#scope_file

game_set_state :: (using game: *Game, new_state: GameState)
{
    if (state == new_state)
        return;

    // Exit state
    if state == 
    {
    case .None;
    case .Engage;
    case .Playing;
    case .Scored;
    case .GameOver;
    case;
    }

    //printf("%s -> %s\n", gsToString(state), gsToString(_state));
    state = new_state;

    // Enter state
    if state ==
    {
    case .None;
    case .Engage;
    {
        ball.position = GAME_SIZE * .5;

        rng1: = random_get_zero_to_one();
        rng2: = random_get_zero_to_one();
        sign: = ifx (rng1 > 0.5) 1.0 else -1.0;
        angle: = rng2 * BALL_MAX_ANGLE * 2.0 - BALL_MAX_ANGLE;
        initialVelocity: = rotate(Vector2.{1.0, 0.0}, angle * D2R);
        initialVelocity.x *= sign;
        initialVelocity *= BALL_SPEED;

        ball.velocity = initialVelocity;
    }
    case .Playing;
    {

    }
    case .Scored;
    {
        state_timer = 150;
    }
    case .GameOver;
    {
        state_timer = 250;
    }
    case;
    }
}

#import "Random";