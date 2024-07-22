ApplicationState :: enum
{
	None :: 0;
	Menu;
	Game;
}

Application :: struct
{
	using sm: StateMachine(ApplicationState, *Application);

	states[ApplicationState.Menu].enter = (using app: *Application)
	{
		log("Enter Menu");
	};

	states[ApplicationState.Menu].exit = (using app: *Application)
	{
		log("Exit Menu");
	};

	states[ApplicationState.Game].enter = (using app: *Application)
	{
		log("Enter Game");
	};

	states[ApplicationState.Game].exit = (using app: *Application)
	{
		log("Exit Game");
	};
}

main :: ()
{
	args := get_command_line_arguments();

	player_index: = 0;
	if (array_find(args, "-p1")) { player_index = 1; }
	else if (array_find(args, "-p2")) { player_index = 2; }

	app: Application;
	app.sm.userdata = *app;
	game: Game;

	// Init
	window_title: *u8;
	if player_index ==
	{
		case 1; window_title = "GGPOng Player 1";
		case 2; window_title = "GGPOng Player 2";
		case; window_title = "GGPOng";
	}
	InitWindow(xx GAME_SIZE.x, xx GAME_SIZE.y, window_title);
    SetTargetFPS(60);
    SetConfigFlags(cast(u32)ConfigFlags.FLAG_VSYNC_HINT);
    raylib_imgui_init();

    game_init(*game);

	// change_state(*app.sm, .Menu);
	// change_state(*app.sm, .Game);

	// Loop
    while !WindowShouldClose()
    {
		reset_temporary_storage();
		raylib_imgui_new_frame(GetFrameTime());

		input: [2]int;
		game_update(*game, input);

		ImGui.ShowDemoWindow();

		{
	        BeginDrawing();
		    defer EndDrawing();
	    	
	    	ClearBackground(BLACK);
	    	
	    	game_draw(*game);
	    	raylib_imgui_render();
		}
    }

    // Shutdown
    game_shutdown(*game);
    raylib_imgui_shutdown();
    CloseWindow();
}

#load "game/game.jai";
#load "game/player.jai";
#load "game/ball.jai";

#import "Basic";
#import "Math";
#import "raylib";

#scope_file

#import "ggpo";
#import "yae";
ImGui :: #import "ImGui";
