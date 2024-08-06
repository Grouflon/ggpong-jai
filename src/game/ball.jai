Ball :: struct
{
    position: Vector2;
    velocity: Vector2;
}

ball_update :: (using ball: *Ball, gs: *Game)
{
    // vertical fist
    position.y += velocity.y;
    // up border
    {
        d: = BALL_SIZE.y * .5 - position.y;
        if (d >= 0)
        {
            velocity.y *= -1;
            position.y += d;
        }
    }
    // down border
    {
        d: = (GAME_SIZE.y - BALL_SIZE.y * .5) - position.y;
        if (d <= 0)
        {
            velocity.y *= -1;
            position.y += d;
        }
    }
    // players
    for i: 0..1
    {
        if (check_player_collision(ball, *gs.players[i]))
        {
            d: = ((PLAYER_SIZE + BALL_SIZE) * .5).y - abs(position.y - gs.players[i].position.y);
            if (velocity.y > 0) { position.y -= d; }
            else { position.y += d; }
            velocity.y *= -1;
        }
    }

    // then horizontal
    position.x += velocity.x;
    /*// left border
    {
        d: = BALL_SIZE.x * .5 - position.x;
        if (d >= 0)
        {
            velocity.x *= -1;
            position.x += d;
        }
    }
    // right border
    {
        d: = (GAME_SIZE.x - BALL_SIZE.x * .5) - position.x;
        if (d <= 0)
        {
            velocity.x *= -1;
            position.x += d;
        }
    }*/
    // players
    for i: 0..1
    {
        if (check_player_collision(ball, *gs.players[i]))
        {
            dx: = ((PLAYER_SIZE + BALL_SIZE) * .5).x - abs(position.x - gs.players[i].position.x);
            if (velocity.x > 0) { position.x -= dx; }
            else { position.x += dx; }
            velocity.x *= -1;

            playerDirection: = Vector2.{sign(position.x - gs.players[i].position.x), 0};
            dy: = (position.y - gs.players[i].position.y) / (PLAYER_SIZE.y * .5) * sign(playerDirection.x);

            // Full control
            //velocity = v_rotate(playerDirection, dy * BALL_MAX_ANGLE * D2R) * v_len(velocity); 

            // Partial control
            angle: = -signed_angle_between(velocity, playerDirection) * R2D;
            angle += dy * PLAYER_MAX_ACTION_ANGLE;
            angle = max(min(angle, BALL_MAX_ANGLE), -BALL_MAX_ANGLE);

            velocity = rotate(playerDirection, angle * D2R) * length(velocity);

        }
    }
}

ball_draw :: (using ball: *Ball)
{
    rl.DrawRectangleV(position - BALL_SIZE * 0.5, BALL_SIZE, rl.WHITE);
}

#scope_file

check_player_collision :: (ball: *Ball, player: *Player) -> bool
{
    l: = ball.position.x - BALL_SIZE.x * .5;
    r: = ball.position.x + BALL_SIZE.x * .5;
    t: = ball.position.y - BALL_SIZE.y * .5;
    b: = ball.position.y + BALL_SIZE.y * .5;

    pl: = player.position.x - PLAYER_SIZE.x * .5;
    pr: = player.position.x + PLAYER_SIZE.x * .5;
    pt: = player.position.y - PLAYER_SIZE.y * .5;
    pb: = player.position.y + PLAYER_SIZE.y * .5;

    return l < pr && r > pl && t < pb && b > pt;
}