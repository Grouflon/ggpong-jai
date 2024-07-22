ApplicationState :: enum
{
	None :: 0;
	Menu;
	Game;
}

Application :: struct
{
	using sm: StateMachine(ApplicationState, *Application);

	states[ApplicationState.Menu].enter = (using application: *Application)
	{
		log("Enter Menu");
	};

	states[ApplicationState.Menu].exit = (using application: *Application)
	{
		log("Exit Menu");
	};

	states[ApplicationState.Game].enter = (using application: *Application)
	{
		log("Enter Game");
	};

	states[ApplicationState.Game].exit = (using application: *Application)
	{
		log("Exit Game");
	};
}

main :: ()
{
	application: Application;
	application.sm.userdata = *application;

	InitWindow(800, 600, "raylib example");
    SetTargetFPS(60);

	change_state(*application.sm, .Menu);
	change_state(*application.sm, .Game);

    while !WindowShouldClose()
    {
        BeginDrawing();

        ClearBackground(RAYWHITE);
	    DrawText("Congrats! You created your first window!", 190, 200, 20, LIGHTGRAY);

	    EndDrawing();
    }

    CloseWindow();
}

#scope_file

#import "Basic";
#import "raylib";
#import "ggpo";
#import "yae";