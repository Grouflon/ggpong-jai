Player :: struct
{
	position: Vector2;
}

player_draw :: (using player: *Player)
{
	DrawRectangleV(position - PLAYER_SIZE * 0.5, PLAYER_SIZE, WHITE);
}

