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

app: Application;

main :: ()
{
    args := get_command_line_arguments();

    player_index: = 0;
    if (array_find(args, "-p1")) { player_index = 1; }
    else if (array_find(args, "-p2")) { player_index = 2; }

    // Enable sockets
    socket_init();

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

        // UPDATE
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
                // INPUT
                up_input: = rl.IsKeyDown(.KEY_UP);
                down_input: = rl.IsKeyDown(.KEY_DOWN);

                ggpo_idle(app.ggpo, 0);

                if app.connection_state == .Connected
                {
                    if app.frames_to_skip > 0
                    {
                        app.frames_to_skip -= 1;
                    }
                    else
                    {
                        result: = GGPOErrorCode.GGPO_OK;
                        disconnect_flags: s32;
                        inputs: [2]int;

                        if app.player_states[app.local_player_id].handle != GGPO_INVALID_HANDLE
                        {
                            input: int = 0;
                            if up_input { input |= 1 << 0; }
                            if down_input { input |= 1 << 1; }

                            result = ggpo_add_local_input(app.ggpo, app.player_states[app.local_player_id].handle, *input, size_of(type_of(input)));
                        }

                        // synchronize these inputs with ggpo.  If we have enough input to proceed
                        // ggpo will modify the input list with the correct inputs to use and
                        // return 1.
                        if GGPO_SUCCEEDED(result)
                        {
                            result = ggpo_synchronize_input(app.ggpo, cast(*void) inputs.data, size_of(int) * 2, *disconnect_flags);
                            if GGPO_SUCCEEDED(result)
                            {
                                // inputs[0] and inputs[1] contain the inputs for p1 and p2.  Advance
                                // the game by 1 frame using those inputs.

                                application_advance_frame(*app, inputs, disconnect_flags);
                            }
                        }
                    }
                }
            }
        }

        // DRAW
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
        case .Menu;
        case .Game;
        {
            assert(app.ggpo != null);
            ggpo_close_session(app.ggpo);
            app.ggpo = null;
        }
        case;
    }

    app.application_state = state;

    if app.application_state == {
        case .Menu;
        {
            application_set_connection_state(app, .None);
            application_set_status(app, "");
        }
        case .Game;
        {
            cb: GGPOSessionCallbacks;
            cb.begin_game = begin_game_callback;
            cb.advance_frame = advance_frame_callback;
            cb.load_game_state = load_game_state_callback;
            cb.save_game_state = save_game_state_callback;
            cb.free_buffer = free_buffer;
            cb.on_event = on_event_callback;
            cb.log_game_state = log_game_state;

            assert(app.ggpo == null);
            //GGPOErrorCode result = ggpo_start_synctest(&m_ggpo, &cb, "GGPOng", 2, sizeof(int), 1);
            result: = ggpo_start_session(*app.ggpo, *cb, "GGPOng", 2, size_of(int), string_to_int(app.local_ip.port, 10, u16));
            assert(GGPO_SUCCEEDED(result));

            // automatically disconnect clients after 3000 ms and start our count-down timer
            // for disconnects after 1000 ms.   To completely disable disconnects, simply use
            // a value of 0 for ggpo_set_disconnect_timeout.
            ggpo_set_disconnect_timeout(app.ggpo, 3000);
            ggpo_set_disconnect_notify_start(app.ggpo, 1000);

            for i: 0..1
            {
                result: = ggpo_add_player(app.ggpo, *app.player_states[i].player, *app.player_states[i].handle);
                if (app.player_states[i].player.type == .GGPO_PLAYERTYPE_LOCAL)
                {
                    ggpo_set_frame_delay(app.ggpo, app.player_states[i].handle, 2);
                }
            }

            game_init(*app.game);

            application_set_connection_state(app, .Connecting);
        }
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

application_advance_frame :: (app: *Application, inputs: [2]int, disconnect_flags: int)
{
    game_update(*app.game, inputs);
    ggpo_advance_frame(app.ggpo);
}

// GGPO Callbacks

begin_game_callback :: (_: *u8) -> bool #c_call
{
    ctx: Context;
    push_context ctx
    {
        log("begin game");
        return true;
    }
}

/*
 * on_event_callback --
 *
 * Notification from GGPO that something has happened.  Update the status
 * text at the bottom of the screen to notify the user.
 */
on_event_callback :: (info: *GGPOEvent) -> bool #c_call
{
    ctx: Context;
    push_context ctx
    {
        event_string: string;
        if info.code ==
        {
            case .GGPO_EVENTCODE_CONNECTED_TO_PEER;       event_string = "CONNECTED_TO_PEER";
            case .GGPO_EVENTCODE_SYNCHRONIZING_WITH_PEER; event_string = "SYNCHRONIZING_WITH_PEER";
            case .GGPO_EVENTCODE_SYNCHRONIZED_WITH_PEER;  event_string = "SYNCHRONIZED_WITH_PEER";
            case .GGPO_EVENTCODE_RUNNING;                 event_string = "RUNNING";
            case .GGPO_EVENTCODE_DISCONNECTED_FROM_PEER;  event_string = "DISCONNECTED_FROM_PEER";
            case .GGPO_EVENTCODE_TIMESYNC;                event_string = "TIMESYNC";
            case .GGPO_EVENTCODE_CONNECTION_INTERRUPTED;  event_string = "CONNECTION_INTERRUPTED";
            case .GGPO_EVENTCODE_CONNECTION_RESUMED;      event_string = "CONNECTION_RESUMED";
        }
        log("ggpo event: %(%)", event_string, info.code);

        if info.code ==
        {
            case .GGPO_EVENTCODE_CONNECTED_TO_PEER;
                application_set_status(*app, "Synchronizing...");

            case .GGPO_EVENTCODE_SYNCHRONIZING_WITH_PEER;
                application_set_status(*app, tprint("Synchronizing... (%)", 100.0 * cast(float)info.u.synchronizing.count / info.u.synchronizing.total));

            case .GGPO_EVENTCODE_SYNCHRONIZED_WITH_PEER;
                application_set_status(*app, "Synchronized !");

            case .GGPO_EVENTCODE_RUNNING;
                application_set_connection_state(*app, .Connected);
                application_set_status(*app, "");

            case .GGPO_EVENTCODE_CONNECTION_INTERRUPTED;
                assert(app.connection_state == .Connected);
                application_set_connection_state(*app, .Interrupted);

            case .GGPO_EVENTCODE_CONNECTION_RESUMED;
                assert(app.connection_state == .Interrupted);
                application_set_connection_state(*app, .Connected);

            case .GGPO_EVENTCODE_DISCONNECTED_FROM_PEER;
                application_set_connection_state(*app, .Disconnected);

            case .GGPO_EVENTCODE_TIMESYNC;
                app.frames_to_skip = info.u.timesync.frames_ahead;
        }
        return true;
    }
}


/*
 * vw_advance_frame_callback --
 *
 * Notification from GGPO we should step foward exactly 1 frame
 * during a rollback.
 */
advance_frame_callback:: (frame: s32) -> bool #c_call
{
    ctx: Context;
    push_context ctx
    {
        log("frame %: advance frame\n", app.game.frame_number);

        inputs: [2]int;
        disconnect_flags: s32;

        // Make sure we fetch new inputs from GGPO and use those to update
        // the game state instead of reading from the keyboard.
        ggpo_synchronize_input(app.ggpo, xx inputs.data, size_of(int) * 2, *disconnect_flags);
        application_advance_frame(*app, inputs, disconnect_flags);
        return true;
    }
}

/*
 * vw_load_game_state_callback --
 *
 * Makes our current state match the state passed in by GGPO.
 */
load_game_state_callback :: (buffer: *u8, len: s32) -> bool #c_call
{
    memcpy(*app.game, buffer, len);
    return true;
}

/*
 * vw_save_game_state_callback --
 *
 * Save the current state to a buffer and return it to GGPO via the
 * buffer and len parameters.
 */
save_game_state_callback :: (buffer: **u8, len: *s32, checksum: *s32, frame: s32) -> bool #c_call
{
    ctx: Context;
    push_context ctx
    {
        <<len = size_of(type_of(app.game));
        <<buffer = alloc(<<len);
        if <<buffer == null
        {
            return false;
        }

        memcpy(<<buffer, *app.game, <<len);
        <<checksum = fletcher32_checksum(<<buffer, <<len);
        return true;
    }
}

/*
 * vw_log_game_state --
 *
 * Log the gamestate.  Used by the synctest debugging tool.
 */
log_game_state :: (filename: *u8, buffer: *u8, len: s32) -> bool #c_call
{
    ctx: Context;
    push_context ctx
    {
        log("log game state");

        /*FILE* fp = nullptr;
        fopen_s(&fp, filename, "w");
        if (fp) {
            GameState *gamestate = (GameState *)buffer;
            fprintf(fp, "GameState object.\n");
            fprintf(fp, "  bounds: %d,%d x %d,%d.\n", gamestate->_bounds.left, gamestate->_bounds.top,
                gamestate->_bounds.right, gamestate->_bounds.bottom);
            fprintf(fp, "  num_ships: %d.\n", gamestate->_num_ships);
            for (int i = 0; i < gamestate->_num_ships; i++) {
                Ship *ship = gamestate->_ships + i;
                fprintf(fp, "  ship %d position:  %.4f, %.4f\n", i, ship->position.x, ship->position.y);
                fprintf(fp, "  ship %d velocity:  %.4f, %.4f\n", i, ship->velocity.dx, ship->velocity.dy);
                fprintf(fp, "  ship %d radius:    %d.\n", i, ship->radius);
                fprintf(fp, "  ship %d heading:   %d.\n", i, ship->heading);
                fprintf(fp, "  ship %d health:    %d.\n", i, ship->health);
                fprintf(fp, "  ship %d speed:     %d.\n", i, ship->speed);
                fprintf(fp, "  ship %d cooldown:  %d.\n", i, ship->cooldown);
                fprintf(fp, "  ship %d score:     %d.\n", i, ship->score);
                for (int j = 0; j < MAX_BULLETS; j++) {
                    Bullet *bullet = ship->bullets + j;
                    fprintf(fp, "  ship %d bullet %d: %.2f %.2f -> %.2f %.2f.\n", i, j,
                        bullet->position.x, bullet->position.y,
                        bullet->velocity.dx, bullet->velocity.dy);
                }
            }
            fclose(fp);
        }*/
        return true;
    }
}

/*
 * vw_free_buffer --
 *
 * Free a save state buffer previously returned in vw_save_game_state_callback.
 */
free_buffer :: (buffer: *void) #c_call
{
    ctx: Context;
    push_context ctx
    {
        free(buffer);
    }
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
