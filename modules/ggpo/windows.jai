//
// This file was auto-generated using the following command:
//
// jai generate.jai
//



GGPO_MAX_PLAYERS :: 4;
GGPO_MAX_PREDICTION_FRAMES :: 8;
GGPO_MAX_SPECTATORS :: 32;

GGPO_SPECTATOR_INPUT_INTERVAL :: 4;

GGPO_INVALID_HANDLE :: -1;

GGPOSession :: struct {}

GGPOPlayerHandle :: s32;

GGPOPlayerType :: enum s32 {
    GGPO_PLAYERTYPE_LOCAL     :: 0;
    GGPO_PLAYERTYPE_REMOTE    :: 1;
    GGPO_PLAYERTYPE_SPECTATOR :: 2;
}

/*
* The GGPOPlayer structure used to describe players in ggpo_add_player
*
* size: Should be set to the sizeof(GGPOPlayer)
*
* type: One of the GGPOPlayerType values describing how inputs should be handled
*       Local players must have their inputs updated every frame via
*       ggpo_add_local_inputs.  Remote players values will come over the
*       network.
*
* player_num: The player number.  Should be between 1 and the number of players
*       In the game (e.g. in a 2 player game, either 1 or 2).
*
* If type == GGPO_PLAYERTYPE_REMOTE:
*
* u.remote.ip_address:  The ip address of the ggpo session which will host this
*       player.
*
* u.remote.port: The port where udp packets should be sent to reach this player.
*       All the local inputs for this session will be sent to this player at
*       ip_address:port.
*
*/
GGPOPlayer :: struct {
    size:       s32;
    type:       GGPOPlayerType;
    player_num: s32;
    u:          union {
        local:  struct {
            __empty_struct_padding: u8; // C++ makes empty structs have length 1
        };

        remote: struct {
            ip_address: [32] u8;
            port:       u16;
        };
    };
}

GGPOLocalEndpoint :: struct {
    player_num: s32;
}

GGPOErrorCode :: enum s32 {
    GGPO_OK                              :: 0;
    GGPO_ERRORCODE_SUCCESS               :: 0;
    GGPO_ERRORCODE_GENERAL_FAILURE       :: -1;
    GGPO_ERRORCODE_INVALID_SESSION       :: 1;
    GGPO_ERRORCODE_INVALID_PLAYER_HANDLE :: 2;
    GGPO_ERRORCODE_PLAYER_OUT_OF_RANGE   :: 3;
    GGPO_ERRORCODE_PREDICTION_THRESHOLD  :: 4;
    GGPO_ERRORCODE_UNSUPPORTED           :: 5;
    GGPO_ERRORCODE_NOT_SYNCHRONIZED      :: 6;
    GGPO_ERRORCODE_IN_ROLLBACK           :: 7;
    GGPO_ERRORCODE_INPUT_DROPPED         :: 8;
    GGPO_ERRORCODE_PLAYER_DISCONNECTED   :: 9;
    GGPO_ERRORCODE_TOO_MANY_SPECTATORS   :: 10;
    GGPO_ERRORCODE_INVALID_REQUEST       :: 11;
}

/*
* The GGPOEventCode enumeration describes what type of event just happened.
*
* GGPO_EVENTCODE_CONNECTED_TO_PEER - Handshake with the game running on the
* other side of the network has been completed.
*
* GGPO_EVENTCODE_SYNCHRONIZING_WITH_PEER - Beginning the synchronization
* process with the client on the other end of the networking.  The count
* and total fields in the u.synchronizing struct of the GGPOEvent
* object indicate progress.
*
* GGPO_EVENTCODE_SYNCHRONIZED_WITH_PEER - The synchronziation with this
* peer has finished.
*
* GGPO_EVENTCODE_RUNNING - All the clients have synchronized.  You may begin
* sending inputs with ggpo_synchronize_inputs.
*
* GGPO_EVENTCODE_DISCONNECTED_FROM_PEER - The network connection on
* the other end of the network has closed.
*
* GGPO_EVENTCODE_TIMESYNC - The time synchronziation code has determined
* that this client is too far ahead of the other one and should slow
* down to ensure fairness.  The u.timesync.frames_ahead parameter in
* the GGPOEvent object indicates how many frames the client is.
*
*/
GGPOEventCode :: enum s32 {
    GGPO_EVENTCODE_CONNECTED_TO_PEER       :: 1000;
    GGPO_EVENTCODE_SYNCHRONIZING_WITH_PEER :: 1001;
    GGPO_EVENTCODE_SYNCHRONIZED_WITH_PEER  :: 1002;
    GGPO_EVENTCODE_RUNNING                 :: 1003;
    GGPO_EVENTCODE_DISCONNECTED_FROM_PEER  :: 1004;
    GGPO_EVENTCODE_TIMESYNC                :: 1005;
    GGPO_EVENTCODE_CONNECTION_INTERRUPTED  :: 1006;
    GGPO_EVENTCODE_CONNECTION_RESUMED      :: 1007;
}

/*
* The GGPOEvent structure contains an asynchronous event notification sent
* by the on_event callback.  See GGPOEventCode, above, for a detailed
* explanation of each event.
*/
GGPOEvent :: struct {
    code: GGPOEventCode;
    u:    union {
        connected:              struct {
            player: GGPOPlayerHandle;
        };

        synchronizing:          struct {
            player: GGPOPlayerHandle;
            count:  s32;
            total:  s32;
        };

        synchronized:           struct {
            player: GGPOPlayerHandle;
        };

        disconnected:           struct {
            player: GGPOPlayerHandle;
        };

        timesync:               struct {
            frames_ahead: s32;
        };

        connection_interrupted: struct {
            player:             GGPOPlayerHandle;
            disconnect_timeout: s32;
        };

        connection_resumed:     struct {
            player: GGPOPlayerHandle;
        };
    };
}

/*
* The GGPOSessionCallbacks structure contains the callback functions that
* your application must implement.  GGPO.net will periodically call these
* functions during the game.  All callback functions must be implemented.
*/
GGPOSessionCallbacks :: struct {
    /*
    * begin_game callback - This callback has been deprecated.  You must
    * implement it, but should ignore the 'game' parameter.
    */
    begin_game:      #type (game: *u8) -> bool #c_call;

    /*
    * save_game_state - The client should allocate a buffer, copy the
    * entire contents of the current game state into it, and copy the
    * length into the *len parameter.  Optionally, the client can compute
    * a checksum of the data and store it in the *checksum argument.
    */
    save_game_state: #type (buffer: **u8, len: *s32, checksum: *s32, frame: s32) -> bool #c_call;

    /*
    * load_game_state - GGPO.net will call this function at the beginning
    * of a rollback.  The buffer and len parameters contain a previously
    * saved state returned from the save_game_state function.  The client
    * should make the current game state match the state contained in the
    * buffer.
    */
    load_game_state: #type (buffer: *u8, len: s32) -> bool #c_call;

    /*
    * log_game_state - Used in diagnostic testing.  The client should use
    * the ggpo_log function to write the contents of the specified save
    * state in a human readible form.
    */
    log_game_state:  #type (filename: *u8, buffer: *u8, len: s32) -> bool #c_call;

    /*
    * free_buffer - Frees a game state allocated in save_game_state.  You
    * should deallocate the memory contained in the buffer.
    */
    free_buffer:     #type (buffer: *void) -> void #c_call;

    /*
    * advance_frame - Called during a rollback.  You should advance your game
    * state by exactly one frame.  Before each frame, call ggpo_synchronize_input
    * to retrieve the inputs you should use for that frame.  After each frame,
    * you should call ggpo_advance_frame to notify GGPO.net that you're
    * finished.
    *
    * The flags parameter is reserved.  It can safely be ignored at this time.
    */
    advance_frame:   #type (flags: s32) -> bool #c_call;

    /*
    * on_event - Notification that something has happened.  See the GGPOEventCode
    * structure above for more information.
    */
    on_event:        #type (info: *GGPOEvent) -> bool #c_call;
}

/*
* The GGPONetworkStats function contains some statistics about the current
* session.
*
* network.send_queue_len - The length of the queue containing UDP packets
* which have not yet been acknowledged by the end client.  The length of
* the send queue is a rough indication of the quality of the connection.
* The longer the send queue, the higher the round-trip time between the
* clients.  The send queue will also be longer than usual during high
* packet loss situations.
*
* network.recv_queue_len - The number of inputs currently buffered by the
* GGPO.net network layer which have yet to be validated.  The length of
* the prediction queue is roughly equal to the current frame number
* minus the frame number of the last packet in the remote queue.
*
* network.ping - The roundtrip packet transmission time as calcuated
* by GGPO.net.  This will be roughly equal to the actual round trip
* packet transmission time + 2 the interval at which you call ggpo_idle
* or ggpo_advance_frame.
*
* network.kbps_sent - The estimated bandwidth used between the two
* clients, in kilobits per second.
*
* timesync.local_frames_behind - The number of frames GGPO.net calculates
* that the local client is behind the remote client at this instant in
* time.  For example, if at this instant the current game client is running
* frame 1002 and the remote game client is running frame 1009, this value
* will mostly likely roughly equal 7.
*
* timesync.remote_frames_behind - The same as local_frames_behind, but
* calculated from the perspective of the remote player.
*
*/
GGPONetworkStats :: struct {
    network:  struct {
        send_queue_len: s32;
        recv_queue_len: s32;
        ping:           s32;
        kbps_sent:      s32;
    };

    timesync: struct {
        local_frames_behind:  s32;
        remote_frames_behind: s32;
    };
}

/*
* ggpo_start_session --
*
* Used to being a new GGPO.net session.  The ggpo object returned by ggpo_start_session
* uniquely identifies the state for this session and should be passed to all other
* functions.
*
* session - An out parameter to the new ggpo session object.
*
* cb - A GGPOSessionCallbacks structure which contains the callbacks you implement
* to help GGPO.net synchronize the two games.  You must implement all functions in
* cb, even if they do nothing but 'return true';
*
* game - The name of the game.  This is used internally for GGPO for logging purposes only.
*
* num_players - The number of players which will be in this game.  The number of players
* per session is fixed.  If you need to change the number of players or any player
* disconnects, you must start a new session.
*
* input_size - The size of the game inputs which will be passsed to ggpo_add_local_input.
*
* local_port - The port GGPO should bind to for UDP traffic.
*/
ggpo_start_session :: (session: **GGPOSession, cb: *GGPOSessionCallbacks, game: *u8, num_players: s32, input_size: s32, localport: u16) -> GGPOErrorCode #foreign ggpo;

/*
* ggpo_add_player --
*
* Must be called for each player in the session (e.g. in a 3 player session, must
* be called 3 times).
*
* player - A GGPOPlayer struct used to describe the player.
*
* handle - An out parameter to a handle used to identify this player in the future.
* (e.g. in the on_event callbacks).
*/
ggpo_add_player :: (session: *GGPOSession, player: *GGPOPlayer, handle: *GGPOPlayerHandle) -> GGPOErrorCode #foreign ggpo;

/*
* ggpo_start_synctest --
*
* Used to being a new GGPO.net sync test session.  During a sync test, every
* frame of execution is run twice: once in prediction mode and once again to
* verify the result of the prediction.  If the checksums of your save states
* do not match, the test is aborted.
*
* cb - A GGPOSessionCallbacks structure which contains the callbacks you implement
* to help GGPO.net synchronize the two games.  You must implement all functions in
* cb, even if they do nothing but 'return true';
*
* game - The name of the game.  This is used internally for GGPO for logging purposes only.
*
* num_players - The number of players which will be in this game.  The number of players
* per session is fixed.  If you need to change the number of players or any player
* disconnects, you must start a new session.
*
* input_size - The size of the game inputs which will be passsed to ggpo_add_local_input.
*
* frames - The number of frames to run before verifying the prediction.  The
* recommended value is 1.
*
*/
ggpo_start_synctest :: (session: **GGPOSession, cb: *GGPOSessionCallbacks, game: *u8, num_players: s32, input_size: s32, frames: s32) -> GGPOErrorCode #foreign ggpo;

/*
* ggpo_start_spectating --
*
* Start a spectator session.
*
* cb - A GGPOSessionCallbacks structure which contains the callbacks you implement
* to help GGPO.net synchronize the two games.  You must implement all functions in
* cb, even if they do nothing but 'return true';
*
* game - The name of the game.  This is used internally for GGPO for logging purposes only.
*
* num_players - The number of players which will be in this game.  The number of players
* per session is fixed.  If you need to change the number of players or any player
* disconnects, you must start a new session.
*
* input_size - The size of the game inputs which will be passsed to ggpo_add_local_input.
*
* local_port - The port GGPO should bind to for UDP traffic.
*
* host_ip - The IP address of the host who will serve you the inputs for the game.  Any
* player partcipating in the session can serve as a host.
*
* host_port - The port of the session on the host
*/
ggpo_start_spectating :: (session: **GGPOSession, cb: *GGPOSessionCallbacks, game: *u8, num_players: s32, input_size: s32, local_port: u16, host_ip: *u8, host_port: u16) -> GGPOErrorCode #foreign ggpo;

/*
* ggpo_close_session --
* Used to close a session.  You must call ggpo_close_session to
* free the resources allocated in ggpo_start_session.
*/
ggpo_close_session :: (unknown0: *GGPOSession) -> GGPOErrorCode #foreign ggpo;

/*
* ggpo_set_frame_delay --
*
* Change the amount of frames ggpo will delay local input.  Must be called
* before the first call to ggpo_synchronize_input.
*/
ggpo_set_frame_delay :: (unknown0: *GGPOSession, player: GGPOPlayerHandle, frame_delay: s32) -> GGPOErrorCode #foreign ggpo;

/*
* ggpo_idle --
* Should be called periodically by your application to give GGPO.net
* a chance to do some work.  Most packet transmissions and rollbacks occur
* in ggpo_idle.
*
* timeout - The amount of time GGPO.net is allowed to spend in this function,
* in milliseconds.
*/
ggpo_idle :: (unknown0: *GGPOSession, timeout: s32) -> GGPOErrorCode #foreign ggpo;

/*
* ggpo_add_local_input --
*
* Used to notify GGPO.net of inputs that should be trasmitted to remote
* players.  ggpo_add_local_input must be called once every frame for
* all player of type GGPO_PLAYERTYPE_LOCAL.
*
* player - The player handle returned for this player when you called
* ggpo_add_local_player.
*
* values - The controller inputs for this player.
*
* size - The size of the controller inputs.  This must be exactly equal to the
* size passed into ggpo_start_session.
*/
ggpo_add_local_input :: (unknown0: *GGPOSession, player: GGPOPlayerHandle, values: *void, size: s32) -> GGPOErrorCode #foreign ggpo;

/*
* ggpo_synchronize_input --
*
* You should call ggpo_synchronize_input before every frame of execution,
* including those frames which happen during rollback.
*
* values - When the function returns, the values parameter will contain
* inputs for this frame for all players.  The values array must be at
* least (size * players) large.
*
* size - The size of the values array.
*
* disconnect_flags - Indicated whether the input in slot (1 << flag) is
* valid.  If a player has disconnected, the input in the values array for
* that player will be zeroed and the i-th flag will be set.  For example,
* if only player 3 has disconnected, disconnect flags will be 8 (i.e. 1 << 3).
*/
ggpo_synchronize_input :: (unknown0: *GGPOSession, values: *void, size: s32, disconnect_flags: *s32) -> GGPOErrorCode #foreign ggpo;

/*
* ggpo_disconnect_player --
*
* Disconnects a remote player from a game.  Will return GGPO_ERRORCODE_PLAYER_DISCONNECTED
* if you try to disconnect a player who has already been disconnected.
*/
ggpo_disconnect_player :: (unknown0: *GGPOSession, player: GGPOPlayerHandle) -> GGPOErrorCode #foreign ggpo;

/*
* ggpo_advance_frame --
*
* You should call ggpo_advance_frame to notify GGPO.net that you have
* advanced your gamestate by a single frame.  You should call this everytime
* you advance the gamestate by a frame, even during rollbacks.  GGPO.net
* may call your save_state callback before this function returns.
*/
ggpo_advance_frame :: (unknown0: *GGPOSession) -> GGPOErrorCode #foreign ggpo;

/*
* ggpo_get_network_stats --
*
* Used to fetch some statistics about the quality of the network connection.
*
* player - The player handle returned from the ggpo_add_player function you used
* to add the remote player.
*
* stats - Out parameter to the network statistics.
*/
ggpo_get_network_stats :: (unknown0: *GGPOSession, player: GGPOPlayerHandle, stats: *GGPONetworkStats) -> GGPOErrorCode #foreign ggpo;

/*
* ggpo_set_disconnect_timeout --
*
* Sets the disconnect timeout.  The session will automatically disconnect
* from a remote peer if it has not received a packet in the timeout window.
* You will be notified of the disconnect via a GGPO_EVENTCODE_DISCONNECTED_FROM_PEER
* event.
*
* Setting a timeout value of 0 will disable automatic disconnects.
*
* timeout - The time in milliseconds to wait before disconnecting a peer.
*/
ggpo_set_disconnect_timeout :: (unknown0: *GGPOSession, timeout: s32) -> GGPOErrorCode #foreign ggpo;

/*
* ggpo_set_disconnect_notify_start --
*
* The time to wait before the first GGPO_EVENTCODE_NETWORK_INTERRUPTED timeout
* will be sent.
*
* timeout - The amount of time which needs to elapse without receiving a packet
*           before the GGPO_EVENTCODE_NETWORK_INTERRUPTED event is sent.
*/
ggpo_set_disconnect_notify_start :: (unknown0: *GGPOSession, timeout: s32) -> GGPOErrorCode #foreign ggpo;

/*
* ggpo_log --
*
* Used to write to the ggpo.net log.  In the current versions of the
* SDK, a log file is only generated if the "quark.log" environment
* variable is set to 1.  This will change in future versions of the
* SDK.
*/
ggpo_log_CFormat :: (unknown0: *GGPOSession, fmt: *u8, __args: ..Any) -> void #foreign ggpo "ggpo_log";
ggpo_log :: (unknown0: *GGPOSession, fmt: string, __args: ..Any) {
    push_allocator(temp);
    formatted_text_builder: String_Builder;
    print_to_builder(*formatted_text_builder, fmt, ..__args);
    append(*formatted_text_builder, "\0");
    formatted_text := builder_to_string(*formatted_text_builder);
    ggpo_log_CFormat(unknown0, "%s", formatted_text.data);
} @PrintLike

#scope_file

#import "Basic"; // For push_context

ggpo :: #library,no_dll "windows/GGPO";
