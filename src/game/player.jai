Player :: struct
{
    position: Vector2;
}

player_update :: (using player: *Player, input: int)
{
    direction: = 0.0;
    if (input & 1) direction -= 1;
    if (input & 2) direction += 1;
    position.y += direction * PLAYER_SPEED;
    position.y = max(min(position.y, GAME_SIZE.y - PLAYER_SIZE.y * .5), PLAYER_SIZE.y * .5);
}

player_draw :: (using player: *Player)
{
    rl.DrawRectangleV(position - PLAYER_SIZE * 0.5, PLAYER_SIZE, rl.WHITE);
}

