ApplicationState :: enum
{
    None :: 0;
    Menu;
    Game;
}

ConnectionState :: enum
{
    None :: 0;
    Connecting;
    Connected;
    Interrupted;
    Disconnected;
};

PlayerState :: struct
{
    player: GGPOPlayer;
    handle: GGPOPlayerHandle;
};

IP :: struct
{
    address: string;
    port: string;
}

Application :: struct
{
    application_state: ApplicationState;
    connection_state: ConnectionState;

    game: Game;

    local_ip: IP;
    distant_ip: IP;

    //GGPO
    local_player_id: int = -1;
    player_states: [GGPO_MAX_SPECTATORS + GGPO_MAX_PLAYERS]PlayerState;
    ggpo: *GGPOSession;
    frames_to_skip: int;

    up_down: bool;
    down_down: bool;

    status: string;
}

main :: ()
{
    args := get_command_line_arguments();

    player_index: = 0;
    if (array_find(args, "-p1")) { player_index = 1; }
    else if (array_find(args, "-p2")) { player_index = 2; }

    // Enable sockets
    socket_init();

    app: Application;
    app.local_ip.address = copy_string("127.0.0.1");
    app.local_ip.port = copy_string("7500");
    app.distant_ip.address = copy_string("127.0.0.1");
    app.distant_ip.port = copy_string("7500");

    // Init
    window_title: *u8;
    if player_index ==
    {
        case 1; window_title = "GGPOng Player 1";
        case 2; window_title = "GGPOng Player 2";
        case; window_title = "GGPOng";
    }
    rl.InitWindow(xx GAME_SIZE.x, xx GAME_SIZE.y, window_title);
    rl.SetTargetFPS(60);
    rl.SetConfigFlags(cast(u32)rl.ConfigFlags.FLAG_VSYNC_HINT);
    rl.SetExitKey(0);
    raylib_imgui_init();

    game_init(*app.game);
    application_change_state(*app, .Menu);

    // Loop
    while !rl.WindowShouldClose()
    {
        dt: = rl.GetFrameTime();
        reset_temporary_storage();
        raylib_imgui_new_frame(dt);

        app.up_down = app.application_state == .Game && rl.IsKeyDown(.KEY_UP);
        app.down_down = app.application_state == .Game && rl.IsKeyDown(.KEY_DOWN);

        if app.application_state ==
        {
            case .Menu;
            {
                ImGui.SetNextWindowPos(Vector2.{50, 100});

                if (ImGui.Begin("Menu", null, .ImGuiWindowFlags_AlwaysAutoResize | .ImGuiWindowFlags_NoSavedSettings | .ImGuiWindowFlags_NoTitleBar | .ImGuiWindowFlags_NoMove))
                {
                    imgui_ipaddress("local IP", "local Port", *app.local_ip, false);
                    imgui_ipaddress("distant IP", "distant Port", *app.distant_ip, true);
                    ImGui.Separator();
                    if (ImGui.Button("Host Online Game"))
                    {
                        app.player_states[0].player.size = size_of(GGPOPlayer);
                        app.player_states[0].player.type = .GGPO_PLAYERTYPE_LOCAL;
                        app.player_states[0].player.player_num = 1;
                        app.local_player_id = 0;
                        app.player_states[1].player.size = size_of(GGPOPlayer);
                        app.player_states[1].player.type = .GGPO_PLAYERTYPE_REMOTE;
                        app.player_states[1].player.player_num = 2;
                        set_ggpoplayer_remote(*app.player_states[1].player, app.distant_ip);
                        application_change_state(*app, .Game);
                    }
                    ImGui.SameLine();
                    if (ImGui.Button("Join Online Game"))
                    {
                        app.player_states[1].player.type = .GGPO_PLAYERTYPE_LOCAL;
                        app.player_states[1].player.player_num = 2;
                        app.local_player_id = 1;
                        app.player_states[0].player.type = .GGPO_PLAYERTYPE_REMOTE;
                        app.player_states[0].player.player_num = 1;
                        set_ggpoplayer_remote(*app.player_states[0].player, app.distant_ip);
                        application_change_state(*app, .Game);
                    }
                }
                ImGui.End();
            }

            case .Game;
            {
                
            }
        }

        input: [2]int;
        game_update(*app.game, input);

        {
            rl.BeginDrawing();
            defer rl.EndDrawing();
            
            rl.ClearBackground(rl.BLACK);
            
            game_draw(*app.game);

            text_color: = rl.Color.{255, 255, 255, 127};

            fps_text: = tprint("frame %\n% fps", app.game.frame_number, formatFloat(1.0 / dt, trailing_width=1, zero_removal=FormatFloat.Zero_Removal.NO));
            rl.DrawText(temp_c_string(fps_text), xx (GAME_SIZE.x - 80.0), xx 20.0, 10, text_color);
            rl.DrawText(temp_c_string(app.status), xx 20.0, xx (GAME_SIZE.y - 40.0), 10, text_color);

            raylib_imgui_render();
        }
    }

    // Shutdown
    application_change_state(*app, .Menu);
    game_shutdown(*app.game);
    raylib_imgui_shutdown();
    rl.CloseWindow();
}

#load "tools.jai";
#load "game/game.jai";
#load "game/player.jai";
#load "game/ball.jai";

#import "Basic";
#import "Math";
rl :: #import "raylib";

#scope_file

// APPLICATION
application_change_state :: (app: *Application, state: ApplicationState)
{
    if app.application_state == state { return; }

    if app.application_state == {
        case;
    }

    app.application_state = state;

    if app.application_state == {
        case;
    }
}

application_set_connection_state :: (app: *Application, state: ConnectionState)
{
    if (state == app.connection_state) { return; }

    // EXIT STATE
    if app.connection_state ==
    {
        case .Disconnected;
        case .Connecting;
        case .Connected;
        case;
    }

    app.connection_state = state;

    // ENTER STATE
    if app.connection_state ==
    {
        case .None;
        case .Disconnected;
            application_set_status(app, "Disconnected from peer.");
        case .Connecting;
            application_set_status(app, "Waiting for peers...");
        case .Connected;
        case .Interrupted;
            application_set_status(app, "Connection with peer interrupted...");
        case;
    }
}

application_set_status :: (app: *Application, status: string)
{
    free(app.status);
    app.status = copy_string(status);
}

// TOOLS
set_ggpoplayer_remote :: (player: *GGPOPlayer, ip: IP)
{
    empty_ip: [32]u8;
    player.u.remote.ip_address = empty_ip;
    memcpy(xx player.u.remote.ip_address.data, ip.address.data, min(ip.address.count, 31));
    player.u.remote.port = string_to_int(ip.port, 10, u16);
}

imgui_ipaddress :: (ip_name: *u8, port_name: *u8, ip: *IP, is_editable: bool)
{
    ImGui.PushItemWidth(150.0);
    if (is_editable)
    {
        InputText(ip_name, *ip.address);
    }
    else
    {
        ImGui.Text(ip.address);
    }
    ImGui.PopItemWidth();
    ImGui.SameLine();
    ImGui.PushItemWidth(100.0);

    InputText(port_name, *ip.port, .CharsDecimal);
    
    ImGui.PopItemWidth();
}

#import "ggpo";
#import "yae";
ImGui :: #import "ImGui";
#import "Socket";
