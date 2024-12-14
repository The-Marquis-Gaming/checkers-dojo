#[cfg(test)]
mod tests {
    use dojo::model::{ModelStorage, ModelValueStorage, ModelStorageTest};
    use dojo::world::{WorldStorage, WorldStorageTrait};
    use dojo::world::world::Event as WorldEvent;
    use dojo::world::world::EventEmitted;
    use dojo::event::Event;
    use dojo_cairo_test::{
        spawn_test_world, NamespaceDef, TestResource, ContractDef, ContractDefTrait,
        WorldStorageTestTrait
    };

    use dojo_starter::systems::actions::{actions, IActionsDispatcher, IActionsDispatcherTrait};

    use dojo_starter::models::{
        piece::{Piece, m_Piece},
        coordinates::Coordinates,
        position::Position,
        session::{Session, m_Session},
        player::{Player, m_Player},
        counter::{Counter, m_Counter}
    };

    use dojo_starter::models::counter::CounterTrait;

    fn namespace_def() -> NamespaceDef {
        let ndef = NamespaceDef {
            namespace: "checkers_marq", resources: [
                TestResource::Model(m_Piece::TEST_CLASS_HASH),
                TestResource::Model(m_Session::TEST_CLASS_HASH),
                TestResource::Model(m_Player::TEST_CLASS_HASH),
                TestResource::Model(m_Counter::TEST_CLASS_HASH),
                TestResource::Event(actions::e_Moved::TEST_CLASS_HASH),
                TestResource::Event(actions::e_Killed::TEST_CLASS_HASH),
                TestResource::Event(actions::e_Winner::TEST_CLASS_HASH),
                TestResource::Event(actions::e_King::TEST_CLASS_HASH),
                TestResource::Contract(actions::TEST_CLASS_HASH)
            ].span()
        };

        ndef
    }

    fn contract_defs() -> Span<ContractDef> {
        [
            ContractDefTrait::new(@"checkers_marq", @"actions")
                .with_writer_of([dojo::utils::bytearray_hash(@"checkers_marq")].span())
        ].span()
    }

    fn clear_world_event_log(contract_address: starknet::ContractAddress) {
        let mut event = starknet::testing::pop_log::<WorldEvent>(contract_address);
        while event.is_some() {
            event = starknet::testing::pop_log::<WorldEvent>(contract_address);
        }
    }

    fn retrieve_emitted_events(world: WorldStorage) -> Span<EventEmitted> {
        let contract_address = world.dispatcher.contract_address;
        let mut output = array![];
        let mut event = starknet::testing::pop_log::<WorldEvent>(contract_address);
        while event.is_some() {
            if let WorldEvent::EventEmitted(event) = event.unwrap() {
                output.append(event);
            }
            event = starknet::testing::pop_log::<WorldEvent>(contract_address);
        };
        output.span()
    }

    fn ensure_moved_event(
        world: WorldStorage, emitted_events: Span<EventEmitted>, moved_event: actions::Moved
    ) {
        let selector = Event::<actions::Moved>::selector(world.namespace_hash);
        let mut found = false;
        for event in emitted_events {
            if *event.selector == selector
                && *event.keys[0] == moved_event.session_id.into()
                && *event.keys[1] == moved_event.player.into()
                && *event.values[0] == moved_event.row.into()
                && *event.values[1] == moved_event.col.into() {
                found = true;
                break;
            };
        };
        assert!(found, "Moved event not found");
    }

    fn ensure_killed_event(
        world: WorldStorage, emitted_events: Span<EventEmitted>, killed_event: actions::Killed
    ) {
        let selector = Event::<actions::Killed>::selector(world.namespace_hash);
        let mut found = false;
        for event in emitted_events {
            if *event.selector == selector
                && *event.keys[0] == killed_event.session_id.into()
                && *event.keys[1] == killed_event.player.into()
                && *event.values[0] == killed_event.row.into()
                && *event.values[1] == killed_event.col.into() {
                found = true;
                break;
            };
        };
        assert!(found, "Killed event not found");
    }

    fn ensure_winner_event(
        world: WorldStorage, emitted_events: Span<EventEmitted>, winner_event: actions::Winner
    ) {
        let selector = Event::<actions::Winner>::selector(world.namespace_hash);
        let mut found = false;
        for event in emitted_events {
            if *event.selector == selector
                && *event.keys[0] == winner_event.session_id.into()
                && *event.keys[1] == winner_event.player.into()
                && *event.values[0] == winner_event.position.into() {
                found = true;
                break;
            };
        };
        assert!(found, "Winner event not found");
    }

    fn ensure_king_event(
        world: WorldStorage, emitted_events: Span<EventEmitted>, king_event: actions::King
    ) {
        let selector = Event::<actions::King>::selector(world.namespace_hash);
        let mut found = false;
        for event in emitted_events {
            if *event.selector == selector
                && *event.keys[0] == king_event.session_id.into()
                && *event.keys[1] == king_event.player.into()
                && *event.values[0] == king_event.row.into()
                && *event.values[1] == king_event.col.into() {
                found = true;
                break;
            };
        };
        assert!(found, "King event not found");
    }


    #[test]
    fn test_world_test_set() {
        // Initialize test environment
        let caller = starknet::contract_address_const::<0x0>();
        let session_id = 0;
        let ndef = namespace_def();
        let mut world = spawn_test_world([ndef].span());
        world.sync_perms_and_inits(contract_defs());

        let row = 1;
        let col = 1;
        let piece = Piece {
            session_id: session_id,
            player: caller,
            row: row,
            col: col,
            position: Position::Down,
            is_king: true,
            is_alive: true
        };
        world.write_model_test(@piece);

        let pieces_keys: Array<(u64, Coordinates)> = array![
            (session_id, Coordinates { row: 7, col: 7 }),
            (session_id, Coordinates { row: 1, col: 1 }),
        ];
        let pieces: Array<Piece> = world.read_models(pieces_keys.span());
        assert(pieces.len() == 2, 'read_models failed');

        // Test initial piece
        assert(
            *pieces[0].position == Position::None && *pieces[0].is_alive == false,
            'initial piece wrong'
        );

        // Test write_model_test
        assert(
            *pieces[1].position == Position::Down && piece.is_king == true && piece.session_id == 0,
            'write_value_from_id failed'
        );
        assert(*pieces[1].is_alive == true, 'write_value_from_id failed');

        // Test model deletion
        world.erase_model(@piece);
        let piece: Piece = world.read_model((session_id, row, col));
        assert(piece.position == Position::None && piece.is_king == false, 'erase_model failed');
        assert(piece.is_alive == false, 'erase_model failed');
    }
    #[test]
    fn test_can_not_choose_piece() {
        let ndef = namespace_def();
        let mut world = spawn_test_world([ndef].span());
        world.sync_perms_and_inits(contract_defs());

        let (contract_address, _) = world.dns(@"actions").unwrap();
        let actions_system = IActionsDispatcher { contract_address };
        let session_id = 0;

        // test zero row
        let invalid_piece_position00 = Coordinates { row: 0, col: 0 }; // Empty square
        let can_choose_piece = actions_system
            .can_choose_piece(Position::Up, invalid_piece_position00, session_id);
        assert(!can_choose_piece, 'should be false');
        let invalid_piece_position01 = Coordinates { row: 0, col: 1 };
        let can_choose_piece = actions_system
            .can_choose_piece(Position::Up, invalid_piece_position01, session_id);
        assert(!can_choose_piece, 'should be false');

        let invalid_piece_position02 = Coordinates { row: 0, col: 2 }; // Empty square
        let can_choose_piece = actions_system
            .can_choose_piece(Position::Up, invalid_piece_position02, session_id);
        assert(!can_choose_piece, 'should be false');

        let invalid_piece_position03 = Coordinates { row: 0, col: 3 };
        let can_choose_piece = actions_system
            .can_choose_piece(Position::Up, invalid_piece_position03, session_id);
        assert(!can_choose_piece, 'should be false');

        let invalid_piece_position04 = Coordinates { row: 0, col: 4 }; // Empty square
        let can_choose_piece = actions_system
            .can_choose_piece(Position::Up, invalid_piece_position04, session_id);
        assert(!can_choose_piece, 'should be false');

        let invalid_piece_position05 = Coordinates { row: 0, col: 5 };
        let can_choose_piece = actions_system
            .can_choose_piece(Position::Up, invalid_piece_position05, session_id);
        assert(!can_choose_piece, 'should be false');

        let invalid_piece_position06 = Coordinates { row: 0, col: 6 }; // Empty square
        let can_choose_piece = actions_system
            .can_choose_piece(Position::Up, invalid_piece_position06, session_id);
        assert(!can_choose_piece, 'should be false');

        let invalid_piece_position07 = Coordinates { row: 0, col: 7 };
        let can_choose_piece = actions_system
            .can_choose_piece(Position::Up, invalid_piece_position07, session_id);
        assert(!can_choose_piece, 'should be false');

        // test first row
        let invalid_piece_position10 = Coordinates { row: 1, col: 0 };
        let can_choose_piece = actions_system
            .can_choose_piece(Position::Up, invalid_piece_position10, session_id);
        assert(!can_choose_piece, 'should be false');

        let invalid_piece_position11 = Coordinates { row: 1, col: 1 }; // Empty square
        let can_choose_piece = actions_system
            .can_choose_piece(Position::Up, invalid_piece_position11, session_id);
        assert(!can_choose_piece, 'should be false');

        let invalid_piece_position12 = Coordinates { row: 1, col: 2 };
        let can_choose_piece = actions_system
            .can_choose_piece(Position::Up, invalid_piece_position12, session_id);
        assert(!can_choose_piece, 'should be false');

        let invalid_piece_position13 = Coordinates { row: 1, col: 3 }; // Empty square
        let can_choose_piece = actions_system
            .can_choose_piece(Position::Up, invalid_piece_position13, session_id);
        assert(!can_choose_piece, 'should be false');

        let invalid_piece_position14 = Coordinates { row: 1, col: 4 };
        let can_choose_piece = actions_system
            .can_choose_piece(Position::Up, invalid_piece_position14, session_id);
        assert(!can_choose_piece, 'should be false');

        let invalid_piece_position15 = Coordinates { row: 1, col: 5 }; // Empty square
        let can_choose_piece = actions_system
            .can_choose_piece(Position::Up, invalid_piece_position15, session_id);
        assert(!can_choose_piece, 'should be false');

        let invalid_piece_position16 = Coordinates { row: 1, col: 6 };
        let can_choose_piece = actions_system
            .can_choose_piece(Position::Up, invalid_piece_position16, session_id);
        assert(!can_choose_piece, 'should be false');

        let invalid_piece_position17 = Coordinates { row: 1, col: 7 }; // Empty square
        let can_choose_piece = actions_system
            .can_choose_piece(Position::Up, invalid_piece_position17, session_id);
        assert(!can_choose_piece, 'should be false');

        // test second row
        let invalid_piece_position20 = Coordinates { row: 2, col: 0 }; // Empty square
        let can_choose_piece = actions_system
            .can_choose_piece(Position::Up, invalid_piece_position20, session_id);
        assert(!can_choose_piece, 'should be false');

        let invalid_piece_position22 = Coordinates { row: 2, col: 2 }; // Empty square
        let can_choose_piece = actions_system
            .can_choose_piece(Position::Up, invalid_piece_position22, session_id);
        assert(!can_choose_piece, 'should be false');

        let invalid_piece_position24 = Coordinates { row: 2, col: 4 }; // Empty square
        let can_choose_piece = actions_system
            .can_choose_piece(Position::Up, invalid_piece_position24, session_id);
        assert(!can_choose_piece, 'should be false');

        let invalid_piece_position26 = Coordinates { row: 2, col: 6 }; // Empty square
        let can_choose_piece = actions_system
            .can_choose_piece(Position::Up, invalid_piece_position26, session_id);
        assert(!can_choose_piece, 'should be false');

        // test fifth row
        let invalid_piece_position51 = Coordinates { row: 5, col: 1 }; // Empty square
        let can_choose_piece = actions_system
            .can_choose_piece(Position::Up, invalid_piece_position51, session_id);
        assert(!can_choose_piece, 'should be false');

        let invalid_piece_position53 = Coordinates { row: 5, col: 3 }; // Empty square
        let can_choose_piece = actions_system
            .can_choose_piece(Position::Up, invalid_piece_position53, session_id);
        assert(!can_choose_piece, 'should be false');

        let invalid_piece_position55 = Coordinates { row: 5, col: 5 }; // Empty square
        let can_choose_piece = actions_system
            .can_choose_piece(Position::Up, invalid_piece_position55, session_id);
        assert(!can_choose_piece, 'should be false');

        let invalid_piece_position57 = Coordinates { row: 5, col: 7 }; // Empty square
        let can_choose_piece = actions_system
            .can_choose_piece(Position::Up, invalid_piece_position57, session_id);
        assert(!can_choose_piece, 'should be false');

        // Mock change turn. update the session's turn
        let mut session: Session = world.read_model((session_id));
        session.turn = (session.turn + 1) % 2;
        world.write_model(@session);

        // test sixth row
        let invalid_piece_position60 = Coordinates { row: 6, col: 0 }; // Empty square
        let can_choose_piece = actions_system
            .can_choose_piece(Position::Down, invalid_piece_position60, session_id);
        assert(!can_choose_piece, 'should be false');

        let invalid_piece_position61 = Coordinates { row: 6, col: 1 };
        let can_choose_piece = actions_system
            .can_choose_piece(Position::Down, invalid_piece_position61, session_id);
        assert(!can_choose_piece, 'should be false');
        let invalid_piece_position62 = Coordinates { row: 6, col: 2 }; // Empty square
        let can_choose_piece = actions_system
            .can_choose_piece(Position::Down, invalid_piece_position62, session_id);
        assert(!can_choose_piece, 'should be false');

        let invalid_piece_position63 = Coordinates { row: 6, col: 3 };
        let can_choose_piece = actions_system
            .can_choose_piece(Position::Down, invalid_piece_position63, session_id);
        assert(!can_choose_piece, 'should be false');

        let invalid_piece_position64 = Coordinates { row: 6, col: 4 }; // Empty square
        let can_choose_piece = actions_system
            .can_choose_piece(Position::Down, invalid_piece_position64, session_id);
        assert(!can_choose_piece, 'should be false');

        let invalid_piece_position65 = Coordinates { row: 6, col: 5 };
        let can_choose_piece = actions_system
            .can_choose_piece(Position::Down, invalid_piece_position65, session_id);
        assert(!can_choose_piece, 'should be false');

        let invalid_piece_position66 = Coordinates { row: 6, col: 6 }; // Empty square
        let can_choose_piece = actions_system
            .can_choose_piece(Position::Down, invalid_piece_position66, session_id);
        assert(!can_choose_piece, 'should be false');

        let invalid_piece_position67 = Coordinates { row: 6, col: 7 };
        let can_choose_piece = actions_system
            .can_choose_piece(Position::Down, invalid_piece_position67, session_id);
        assert(!can_choose_piece, 'should be false');

        // test seventh row
        let invalid_piece_position70 = Coordinates { row: 7, col: 0 };
        let can_choose_piece = actions_system
            .can_choose_piece(Position::Down, invalid_piece_position70, session_id);
        assert(!can_choose_piece, 'should be false');

        let invalid_piece_position71 = Coordinates { row: 7, col: 1 };
        let can_choose_piece = actions_system
            .can_choose_piece(Position::Down, invalid_piece_position71, session_id);
        assert(!can_choose_piece, 'should be false');

        let invalid_piece_position72 = Coordinates { row: 7, col: 2 };
        let can_choose_piece = actions_system
            .can_choose_piece(Position::Down, invalid_piece_position72, session_id);
        assert(!can_choose_piece, 'should be false');

        let invalid_piece_position73 = Coordinates { row: 7, col: 3 };
        let can_choose_piece = actions_system
            .can_choose_piece(Position::Down, invalid_piece_position73, session_id);
        assert(!can_choose_piece, 'should be false');

        let invalid_piece_position74 = Coordinates { row: 7, col: 4 };
        let can_choose_piece = actions_system
            .can_choose_piece(Position::Down, invalid_piece_position74, session_id);
        assert(!can_choose_piece, 'should be false');

        let invalid_piece_position75 = Coordinates { row: 7, col: 5 };
        let can_choose_piece = actions_system
            .can_choose_piece(Position::Down, invalid_piece_position75, session_id);
        assert(!can_choose_piece, 'should be false');

        let invalid_piece_position76 = Coordinates { row: 7, col: 6 };
        let can_choose_piece = actions_system
            .can_choose_piece(Position::Down, invalid_piece_position76, session_id);
        assert(!can_choose_piece, 'should be false');

        let invalid_piece_position77 = Coordinates { row: 7, col: 7 };
        let can_choose_piece = actions_system
            .can_choose_piece(Position::Down, invalid_piece_position77, session_id);
        assert(!can_choose_piece, 'should be false');
    }

    #[test]
    fn test_can_choose_piece() {
        //let caller = starknet::contract_address_const::<0x0>();

        let ndef = namespace_def();
        let mut world = spawn_test_world([ndef].span());
        world.sync_perms_and_inits(contract_defs());

        let (contract_address, _) = world.dns(@"actions").unwrap();
        let actions_system = IActionsDispatcher { contract_address };
        let session_id = actions_system.create_lobby();
        actions_system.join_lobby(session_id);

        let valid_piece_position21 = Coordinates { row: 2, col: 1 };
        let can_choose_piece = actions_system
            .can_choose_piece(Position::Up, valid_piece_position21, session_id);
        assert(can_choose_piece, 'should be true');
        let valid_piece_position23 = Coordinates { row: 2, col: 3 };
        let can_choose_piece = actions_system
            .can_choose_piece(Position::Up, valid_piece_position23, session_id);
        assert(can_choose_piece, 'should be true');

        let valid_piece_position25 = Coordinates { row: 2, col: 5 };
        let can_choose_piece = actions_system
            .can_choose_piece(Position::Up, valid_piece_position25, session_id);
        assert(can_choose_piece, 'should be true');

        let valid_piece_position27 = Coordinates { row: 2, col: 7 };
        let can_choose_piece = actions_system
            .can_choose_piece(Position::Up, valid_piece_position27, session_id);
        assert(can_choose_piece, 'should be true');
        // test fifth row
        let valid_piece_position50 = Coordinates { row: 5, col: 0 };

        // Change turn
        let mut game: Session = world.read_model((session_id));
        game.turn = 1;
        world.write_model(@game);

        let can_choose_piece = actions_system
            .can_choose_piece(Position::Down, valid_piece_position50, session_id);
        assert(can_choose_piece, 'should be true');

        let valid_piece_position52 = Coordinates { row: 5, col: 2 };
        let can_choose_piece = actions_system
            .can_choose_piece(Position::Down, valid_piece_position52, session_id);
        assert(can_choose_piece, 'should be true');

        let valid_piece_position54 = Coordinates { row: 5, col: 4 };
        let can_choose_piece = actions_system
            .can_choose_piece(Position::Down, valid_piece_position54, session_id);
        assert(can_choose_piece, 'should be true');

        let valid_piece_position56 = Coordinates { row: 5, col: 6 };
        let can_choose_piece = actions_system
            .can_choose_piece(Position::Down, valid_piece_position56, session_id);
        assert(can_choose_piece, 'should be true');
    }
    // //Test can choose piece but can not move
    #[test]
    #[should_panic(expected: ('Invalid coordinates', 'ENTRYPOINT_FAILED'))]
    fn test_move_piece31_forward_straight_fails() {
        let ndef = namespace_def();
        let mut world = spawn_test_world([ndef].span());
        world.sync_perms_and_inits(contract_defs());

        let (contract_address, _) = world.dns(@"actions").unwrap();
        let actions_system = IActionsDispatcher { contract_address };
        let session_id = actions_system.create_lobby();
        actions_system.join_lobby(session_id);

        let valid_piece_position = Coordinates { row: 2, col: 1 };

        let can_choose_piece = actions_system
            .can_choose_piece(Position::Up, valid_piece_position, session_id);
        assert(can_choose_piece, 'can_choose_piece failed');

        let current_piece = world.read_model((session_id, valid_piece_position));
        let new_coordinates_position = Coordinates { row: 3, col: 1 };
        actions_system.move_piece(current_piece, new_coordinates_position);
    }

    #[test]
    #[should_panic(expected: ('Invalid coordinates', 'ENTRYPOINT_FAILED'))]
    fn test_move_piece37_forward_right_fails() {
        let ndef = namespace_def();
        let mut world = spawn_test_world([ndef].span());
        world.sync_perms_and_inits(contract_defs());

        let (contract_address, _) = world.dns(@"actions").unwrap();
        let actions_system = IActionsDispatcher { contract_address };
        let session_id = actions_system.create_lobby();
        actions_system.join_lobby(session_id);

        let valid_piece_position = Coordinates { row: 2, col: 7 };

        let can_choose_piece = actions_system
            .can_choose_piece(Position::Up, valid_piece_position, session_id);
        assert(can_choose_piece, 'can_choose_piece failed');

        let current_piece = world.read_model((session_id, valid_piece_position));
        let new_coordinates_position = Coordinates { row: 3, col: 8 };
        actions_system.move_piece(current_piece, new_coordinates_position);
    }
    #[test]
    fn test_move_piece21_down_left() {
        let ndef = namespace_def();
        let mut world = spawn_test_world([ndef].span());
        world.sync_perms_and_inits(contract_defs());

        let (contract_address, _) = world.dns(@"actions").unwrap();
        let actions_system = IActionsDispatcher { contract_address };
        let session_id = actions_system.create_lobby();
        actions_system.join_lobby(session_id);

        let valid_piece_position = Coordinates { row: 2, col: 1 };
        let initial_piece_position: Piece = world.read_model((session_id, valid_piece_position));

        assert(
            initial_piece_position.row == 2 && initial_piece_position.col == 1,
            'wrong initial piece'
        );
        assert(initial_piece_position.session_id == 0, 'wrong session');
        assert(initial_piece_position.is_king == false, 'wrong initial piece');
        assert(initial_piece_position.is_alive == true, 'wrong initial piece');

        let can_choose_piece = actions_system
            .can_choose_piece(Position::Up, valid_piece_position, session_id);
        assert(can_choose_piece, 'can_choose_piece failed');

        clear_world_event_log(world.dispatcher.contract_address);
        let new_coordinates_position = Coordinates { row: 3, col: 0 };
        actions_system.move_piece(initial_piece_position, new_coordinates_position);
        let emitted_events = retrieve_emitted_events(world);
        ensure_moved_event(
            world,
            emitted_events,
            actions::Moved {
                session_id: initial_piece_position.session_id,
                player: starknet::get_caller_address(),
                row: new_coordinates_position.row,
                col: new_coordinates_position.col,
            }
        );

        let new_position: Piece = world.read_model((session_id, new_coordinates_position));

        assert!(new_position.session_id == 0, "wrong session");
        assert!(new_position.row == 3, "piece x is wrong");
        assert!(new_position.col == 0, "piece y is wrong");
        assert!(new_position.is_alive == true, "piece is not alive");
        assert!(new_position.is_king == false, "piece is king");
    }
    #[test]
    fn test_move_piece23_down_left() {
        let ndef = namespace_def();
        let mut world = spawn_test_world([ndef].span());
        world.sync_perms_and_inits(contract_defs());

        let (contract_address, _) = world.dns(@"actions").unwrap();
        let actions_system = IActionsDispatcher { contract_address };
        let session_id = actions_system.create_lobby();
        actions_system.join_lobby(session_id);

        let valid_piece_position = Coordinates { row: 2, col: 3 };
        let initial_piece_position: Piece = world.read_model((session_id, valid_piece_position));
        assert(
            initial_piece_position.row == 2 && initial_piece_position.col == 3,
            'wrong initial piece cords'
        );
        assert(initial_piece_position.session_id == 0, 'wrong session');
        assert(initial_piece_position.is_king == false, 'wrong initial piece king');
        assert(initial_piece_position.is_alive == true, 'wrong initial piece alive');

        let can_choose_piece = actions_system
            .can_choose_piece(Position::Up, valid_piece_position, session_id);
        assert(can_choose_piece, 'can_choose_piece failed');

        clear_world_event_log(world.dispatcher.contract_address);
        let new_coordinates_position = Coordinates { row: 3, col: 2 };
        actions_system.move_piece(initial_piece_position, new_coordinates_position);
        let emitted_events = retrieve_emitted_events(world);
        ensure_moved_event(
            world,
            emitted_events,
            actions::Moved {
                session_id: initial_piece_position.session_id,
                player: starknet::get_caller_address(),
                row: new_coordinates_position.row,
                col: new_coordinates_position.col,
            }
        );

        let new_position: Piece = world.read_model((session_id, new_coordinates_position));

        assert!(new_position.session_id == 0, "wrong session");
        assert!(new_position.row == 3, "piece x is wrong");
        assert!(new_position.col == 2, "piece y is wrong");
        assert!(new_position.is_alive == true, "piece is not alive");
        assert!(new_position.is_king == false, "piece is king");
    }
    #[test]
    fn test_move_piece25_down_left() {
        let ndef = namespace_def();
        let mut world = spawn_test_world([ndef].span());
        world.sync_perms_and_inits(contract_defs());

        let (contract_address, _) = world.dns(@"actions").unwrap();
        let actions_system = IActionsDispatcher { contract_address };
        let session_id = actions_system.create_lobby();
        actions_system.join_lobby(session_id);

        let valid_piece_position = Coordinates { row: 2, col: 5 };
        let initial_piece_position: Piece = world.read_model((session_id, valid_piece_position));

        assert(
            initial_piece_position.row == 2 && initial_piece_position.col == 5,
            'wrong initial piece'
        );
        assert(initial_piece_position.session_id == 0, 'wrong session');
        assert(initial_piece_position.is_king == false, 'wrong initial piece');
        assert(initial_piece_position.is_alive == true, 'wrong initial piece');

        let can_choose_piece = actions_system
            .can_choose_piece(Position::Up, valid_piece_position, session_id);
        assert(can_choose_piece, 'can_choose_piece failed');

        clear_world_event_log(world.dispatcher.contract_address);
        let new_coordinates_position = Coordinates { row: 3, col: 4 };
        actions_system.move_piece(initial_piece_position, new_coordinates_position);
        let emitted_events = retrieve_emitted_events(world);
        ensure_moved_event(
            world,
            emitted_events,
            actions::Moved {
                session_id: initial_piece_position.session_id,
                player: starknet::get_caller_address(),
                row: new_coordinates_position.row,
                col: new_coordinates_position.col,
            }
        );

        let new_position: Piece = world.read_model((session_id, new_coordinates_position));

        assert!(new_position.session_id == 0, "wrong session");
        assert!(new_position.row == 3, "piece x is wrong");
        assert!(new_position.col == 4, "piece y is wrong");
        assert!(new_position.is_alive == true, "piece is not alive");
        assert!(new_position.is_king == false, "piece is king");
    }

    #[test]
    fn test_move_piece27_down_left() {
        let ndef = namespace_def();
        let mut world = spawn_test_world([ndef].span());
        world.sync_perms_and_inits(contract_defs());

        let (contract_address, _) = world.dns(@"actions").unwrap();
        let actions_system = IActionsDispatcher { contract_address };
        let session_id = actions_system.create_lobby();
        actions_system.join_lobby(session_id);

        let valid_piece_position = Coordinates { row: 2, col: 7 };
        let initial_piece_position: Piece = world.read_model((session_id, valid_piece_position));

        assert(
            initial_piece_position.row == 2 && initial_piece_position.col == 7,
            'wrong initial piece'
        );
        assert(initial_piece_position.session_id == 0, 'wrong session');
        assert(initial_piece_position.is_king == false, 'wrong initial piece');
        assert(initial_piece_position.is_alive == true, 'wrong initial piece');

        let can_choose_piece = actions_system
            .can_choose_piece(Position::Up, valid_piece_position, session_id);
        assert(can_choose_piece, 'can_choose_piece failed');

        clear_world_event_log(world.dispatcher.contract_address);
        let new_coordinates_position = Coordinates { row: 3, col: 6 };
        actions_system.move_piece(initial_piece_position, new_coordinates_position);
        let emitted_events = retrieve_emitted_events(world);
        ensure_moved_event(
            world,
            emitted_events,
            actions::Moved {
                session_id: initial_piece_position.session_id,
                player: starknet::get_caller_address(),
                row: new_coordinates_position.row,
                col: new_coordinates_position.col,
            }
        );

        let new_position: Piece = world.read_model((session_id, new_coordinates_position));

        assert!(new_position.session_id == 0, "wrong session");
        assert!(new_position.row == 3, "piece x is wrong");
        assert!(new_position.col == 6, "piece y is wrong");
        assert!(new_position.is_alive == true, "piece is not alive");
        assert!(new_position.is_king == false, "piece is king");
    }

    #[test]
    fn test_move_piece21_down_right() {
        let ndef = namespace_def();
        let mut world = spawn_test_world([ndef].span());
        world.sync_perms_and_inits(contract_defs());

        let (contract_address, _) = world.dns(@"actions").unwrap();
        let actions_system = IActionsDispatcher { contract_address };
        let session_id = actions_system.create_lobby();
        actions_system.join_lobby(session_id);

        let valid_piece_position = Coordinates { row: 2, col: 1 };
        let initial_piece_position: Piece = world.read_model((session_id, valid_piece_position));

        assert(
            initial_piece_position.row == 2 && initial_piece_position.col == 1,
            'wrong initial piece'
        );
        assert(initial_piece_position.session_id == 0, 'wrong session');
        assert(initial_piece_position.is_king == false, 'wrong initial piece');
        assert(initial_piece_position.is_alive == true, 'wrong initial piece');

        let can_choose_piece = actions_system
            .can_choose_piece(Position::Up, valid_piece_position, session_id);
        assert(can_choose_piece, 'can_choose_piece failed');

        clear_world_event_log(world.dispatcher.contract_address);
        let new_coordinates_position = Coordinates { row: 3, col: 2 };
        actions_system.move_piece(initial_piece_position, new_coordinates_position);
        let emitted_events = retrieve_emitted_events(world);
        ensure_moved_event(
            world,
            emitted_events,
            actions::Moved {
                session_id: initial_piece_position.session_id,
                player: starknet::get_caller_address(),
                row: new_coordinates_position.row,
                col: new_coordinates_position.col,
            }
        );

        let new_position: Piece = world.read_model((session_id, new_coordinates_position));

        assert!(new_position.session_id == 0, "wrong session");
        assert!(new_position.row == 3, "piece x is wrong");
        assert!(new_position.col == 2, "piece y is wrong");
        assert!(new_position.is_alive == true, "piece is not alive");
        assert!(new_position.is_king == false, "piece is king");
    }
    #[test]
    fn test_move_piece21_down_right_move_piece56_up_left() {
        let ndef = namespace_def();
        let mut world = spawn_test_world([ndef].span());
        world.sync_perms_and_inits(contract_defs());

        let (contract_address, _) = world.dns(@"actions").unwrap();
        let actions_system = IActionsDispatcher { contract_address };
        let session_id = actions_system.create_lobby();
        actions_system.join_lobby(session_id);

        // Test initial position 21 & 56
        let valid_piece_position21 = Coordinates { row: 2, col: 1 };
        let valid_piece_position56 = Coordinates { row: 5, col: 6 };
        let initial_pieces_keys: Array<(u64, Coordinates)> = array![
            (session_id, valid_piece_position21), (session_id, valid_piece_position56),
        ];
        let initial_pieces: Array<Piece> = world.read_models(initial_pieces_keys.span());
        assert(initial_pieces.len() == 2, 'read_models failed');

        assert(
            *initial_pieces[0].row == 2 && *initial_pieces[0].col == 1, 'wrong initial piece 21'
        );
        assert(
            *initial_pieces[1].row == 5 && *initial_pieces[1].col == 6, 'wrong initial piece 56'
        );
        for piece in initial_pieces
            .clone() {
                assert(piece.session_id == 0, 'wrong session');
                assert(piece.is_king == false, 'wrong initial piece');
                assert(piece.is_alive == true, 'wrong initial piece');
            };

        // Test move to positions 32 & 45
        let can_choose_piece21 = actions_system
            .can_choose_piece(Position::Up, valid_piece_position21, session_id);
        assert(can_choose_piece21, 'can_choose_piece 21 failed');

        clear_world_event_log(world.dispatcher.contract_address);
        let new_coordinates_position32 = Coordinates { row: 3, col: 2 };
        actions_system.move_piece(*initial_pieces[0], new_coordinates_position32);
        let emitted_events = retrieve_emitted_events(world);
        ensure_moved_event(
            world,
            emitted_events,
            actions::Moved {
                session_id: *initial_pieces[0].session_id,
                player: starknet::get_caller_address(),
                row: new_coordinates_position32.row,
                col: new_coordinates_position32.col,
            }
        );

        let can_choose_piece56 = actions_system
            .can_choose_piece(Position::Down, valid_piece_position56, session_id);
        assert(can_choose_piece56, 'can_choose_piece 56 failed');

        clear_world_event_log(world.dispatcher.contract_address);
        let new_coordinates_position45 = Coordinates { row: 4, col: 5 };
        actions_system.move_piece(*initial_pieces[1], new_coordinates_position45);
        let emitted_events = retrieve_emitted_events(world);
        ensure_moved_event(
            world,
            emitted_events,
            actions::Moved {
                session_id: *initial_pieces[1].session_id,
                player: starknet::get_caller_address(),
                row: new_coordinates_position45.row,
                col: new_coordinates_position45.col,
            }
        );

        let new_coordinates_keys: Array<(u64, Coordinates)> = array![
            (session_id, new_coordinates_position32), (session_id, new_coordinates_position45),
        ];
        let new_positions: Array<Piece> = world.read_models(new_coordinates_keys.span());
        assert(new_positions.len() == 2, 'read_models failed');

        assert!(*new_positions[0].row == 3, "piece x is wrong");
        assert!(*new_positions[0].col == 2, "piece y is wrong");
        assert!(*new_positions[1].row == 4, "piece x is wrong");
        assert!(*new_positions[1].col == 5, "piece y is wrong");
        for new_position in new_positions {
            assert!(new_position.session_id == 0, "wrong session");
            assert!(new_position.is_alive == true, "piece is not alive");
            assert!(new_position.is_king == false, "piece is king");
        };
    }
    #[test]
    fn test_piece21_eat_piece54() {
        let ndef = namespace_def();
        let mut world = spawn_test_world([ndef].span());
        world.sync_perms_and_inits(contract_defs());

        let (contract_address, _) = world.dns(@"actions").unwrap();
        let actions_system = IActionsDispatcher { contract_address };
        let session_id = actions_system.create_lobby();
        // Cheat call the second player
        let player2 = starknet::contract_address_const::<0x1>();
        starknet::testing::set_contract_address(player2);
        actions_system.join_lobby(session_id);

        let session: Session = world.read_model((session_id));
        assert(session.player_2 == player2, 'wrong player');
        // Reset player to default operation
        starknet::testing::set_contract_address(starknet::contract_address_const::<0x0>());

        // Test initial position 21 & 54
        let valid_piece_position21 = Coordinates { row: 2, col: 1 };
        let valid_piece_position54 = Coordinates { row: 5, col: 4 };
        let initial_pieces_keys: Array<(u64, Coordinates)> = array![
            (session_id, valid_piece_position21), (session_id, valid_piece_position54),
        ];
        let initial_pieces: Array<Piece> = world.read_models(initial_pieces_keys.span());
        assert(initial_pieces.len() == 2, 'read_models failed');

        assert(
            *initial_pieces[0].row == 2 && *initial_pieces[0].col == 1, 'wrong initial piece 21'
        );
        assert(
            *initial_pieces[1].row == 5 && *initial_pieces[1].col == 4, 'wrong initial piece 54'
        );
        for piece in initial_pieces
            .clone() {
                assert(piece.session_id == 0, 'wrong session');
                assert(piece.is_king == false, 'wrong initial piece');
                assert(piece.is_alive == true, 'wrong initial piece');
            };

        // Test move to position 32 & 43
        let can_choose_piece = actions_system
            .can_choose_piece(Position::Up, valid_piece_position21, session_id);
        assert(can_choose_piece, 'can_choose_piece 21 failed');

        clear_world_event_log(world.dispatcher.contract_address);
        let new_coordinates_position32 = Coordinates { row: 3, col: 2 };
        actions_system.move_piece(*initial_pieces[0], new_coordinates_position32);
        let emitted_events = retrieve_emitted_events(world);
        ensure_moved_event(
            world,
            emitted_events,
            actions::Moved {
                session_id: *initial_pieces[0].session_id,
                player: starknet::get_caller_address(),
                row: new_coordinates_position32.row,
                col: new_coordinates_position32.col,
            }
        );

        let can_choose_piece = actions_system
            .can_choose_piece(Position::Down, valid_piece_position54, session_id);
        assert(can_choose_piece, 'can_choose_piece 54 failed');

        clear_world_event_log(world.dispatcher.contract_address);
        let new_coordinates_position43 = Coordinates { row: 4, col: 3 };
        actions_system.move_piece(*initial_pieces[1], new_coordinates_position43);
        let emitted_events = retrieve_emitted_events(world);
        ensure_moved_event(
            world,
            emitted_events,
            actions::Moved {
                session_id: *initial_pieces[0].session_id,
                player: player2,
                row: new_coordinates_position43.row,
                col: new_coordinates_position43.col,
            }
        );

        let new_coordinates_keys: Array<(u64, Coordinates)> = array![
            (session_id, new_coordinates_position32), (session_id, new_coordinates_position43),
        ];
        let new_positions: Array<Piece> = world.read_models(new_coordinates_keys.span());
        assert(new_positions.len() == 2, 'read_models failed');

        assert!(*new_positions[0].row == 3, "piece x is wrong");
        assert!(*new_positions[0].col == 2, "piece y is wrong");
        assert!(*new_positions[1].row == 4, "piece x is wrong");
        assert!(*new_positions[1].col == 3, "piece y is wrong");
        for new_position in new_positions
            .clone() {
                assert!(new_position.session_id == 0, "wrong session");
                assert!(new_position.is_alive == true, "piece is not alive");
                assert!(new_position.is_king == false, "piece is king");
            };

        // Test position 32 moves to eat 43 then jump to 54
        let eat_position = Coordinates { row: 4, col: 3 };
        let jump_position = Coordinates { row: 5, col: 4 };

        clear_world_event_log(world.dispatcher.contract_address);
        actions_system.move_piece(*new_positions[0], eat_position);
        let emitted_events = retrieve_emitted_events(world);
        ensure_moved_event(
            world,
            emitted_events,
            actions::Moved {
                session_id: *new_positions[0].session_id,
                player: starknet::get_caller_address(),
                row: jump_position.row,
                col: jump_position.col,
            }
        );
        ensure_killed_event(
            world,
            emitted_events,
            actions::Killed {
                session_id: *new_positions[0].session_id,
                player: starknet::get_caller_address(),
                row: 4,
                col: 3,
            }
        );

        let updated_pieces_keys: Array<(u64, Coordinates)> = array![
            (session_id, jump_position), (session_id, eat_position),
        ];
        let updated_pieces: Array<Piece> = world.read_models(updated_pieces_keys.span());
        assert(updated_pieces.len() == 2, 'read_models failed');

        assert!(*updated_pieces[0].row == 5, "piece x is wrong");
        assert!(*updated_pieces[0].col == 4, "piece y is wrong");
        assert!(*updated_pieces[1].row == 4, "piece x is wrong");
        assert!(*updated_pieces[1].col == 3, "piece y is wrong");

        assert!(*updated_pieces[0].is_alive == true, "piece is not alive");
        assert!(*updated_pieces[0].position == Position::Up, "piece is not right team");
        assert!(*updated_pieces[0].is_king == false, "piece is king");

        assert!(*updated_pieces[1].is_alive == false, "piece is alive");
        assert!(*updated_pieces[1].is_king == false, "piece is king");

        // Check the remaining pieces got reduced
        let player_model: Player = world.read_model(player2);
        assert!(player_model.remaining_pieces == 11, "wrong remaining pieces");
    }
    #[test]
    fn test_move_king_piece() {
        let ndef = namespace_def();
        let mut world = spawn_test_world([ndef].span());
        world.sync_perms_and_inits(contract_defs());

        let (contract_address, _) = world.dns(@"actions").unwrap();
        let actions_system = IActionsDispatcher { contract_address };
        let session_id = actions_system.create_lobby();
        // Cheat call the second player
        let player2 = starknet::contract_address_const::<0x1>();
        starknet::testing::set_contract_address(player2);
        actions_system.join_lobby(session_id);

        let session: Session = world.read_model((session_id));
        assert(session.player_2 == player2, 'wrong player');
        // Reset player to default operation
        starknet::testing::set_contract_address(starknet::contract_address_const::<0x0>());

        // All coordinates needed for test
        let pos_25 = Coordinates { row: 2, col: 5 };
        let pos_30 = Coordinates { row: 3, col: 0 };
        let pos_34 = Coordinates { row: 3, col: 4 };
        let pos_41 = Coordinates { row: 4, col: 1 };
        let pos_43 = Coordinates { row: 4, col: 3 };
        let pos_52 = Coordinates { row: 5, col: 2 };
        let pos_61 = Coordinates { row: 6, col: 1 };
        let pos_70 = Coordinates { row: 7, col: 0 };

        // Arrange board for test
        let pieces_keys: Array<(u64, Coordinates)> = array![
            (session_id, pos_25),
            (session_id, pos_52),
            (session_id, pos_61),
            (session_id, pos_70),
        ];
        let pieces: Array<Piece> = world.read_models(pieces_keys.span());
        assert(*pieces[0].row == 2 && *pieces[0].col == 5, 'wrong initial piece 25');
        assert(*pieces[1].row == 5 && *pieces[1].col == 2, 'wrong initial piece 52');
        assert(*pieces[2].row == 6 && *pieces[2].col == 1, 'wrong initial piece 61');
        assert(*pieces[3].row == 7 && *pieces[3].col == 0, 'wrong initial piece 70');
        for piece in pieces.clone() {
            assert(piece.session_id == 0, 'wrong session');
            assert(piece.is_king == false, 'wrong initial piece');
            assert(piece.is_alive == true, 'wrong initial piece');
        };

        let can_choose_piece = actions_system.can_choose_piece(Position::Up, pos_25, session_id);
        assert(can_choose_piece, 'can_choose_piece failed');
        
        // Test move pieces 25->34, 52->30, 61->41, 70->61
        actions_system.move_piece(*pieces[0], pos_34);
        actions_system.move_piece(*pieces[1], pos_30);
        actions_system.move_piece(*pieces[2], pos_41);
        actions_system.move_piece(*pieces[3], pos_61);

        // Get updated pieces
        let pieces_keys: Array<(u64, Coordinates)> = array![
            (session_id, pos_34),
            (session_id, pos_30),
            (session_id, pos_41),
            (session_id, pos_61),
        ];
        let pieces: Array<Piece> = world.read_models(pieces_keys.span());
        assert(*pieces[0].row == 3 && *pieces[0].col == 4, 'wrong updated piece 34');
        assert(*pieces[1].row == 3 && *pieces[1].col == 0, 'wrong updated piece 30');
        assert(*pieces[2].row == 4 && *pieces[2].col == 1, 'wrong updated piece 41');
        assert(*pieces[3].row == 6 && *pieces[3].col == 1, 'wrong updated piece 61');
        assert!(*pieces[0].position == Position::Up, "piece 34 is not right team");
        assert!(*pieces[1].position == Position::Down, "piece 30 is not right team");
        assert!(*pieces[2].position == Position::Down, "piece 41 is not right team");
        assert!(*pieces[3].position == Position::Down, "piece 61 is not right team");
        for piece in pieces.clone() {
            assert(piece.session_id == 0, 'wrong session');
            assert(piece.is_king == false, 'wrong initial piece');
            assert(piece.is_alive == true, 'wrong initial piece');
        };

        // Test move 34 -> 43 -> 52 eat 61 becomes king (70) & move to 34
        actions_system.move_piece(*pieces[0], pos_43);
        let current_piece: Piece = world.read_model((session_id, pos_43));
        assert!(current_piece.session_id == 0, "wrong session");
        assert!(current_piece.row == 4, "piece 43 x is wrong");
        assert!(current_piece.col == 3, "piece 43 y is wrong");
        assert!(current_piece.is_alive == true, "piece 43 is not alive");
        assert!(current_piece.is_king == false, "piece 43 is king");
        assert!(current_piece.position == Position::Up, "piece 43 is not right team");

        actions_system.move_piece(current_piece, pos_52);
        let current_piece: Piece = world.read_model((session_id, pos_52));
        assert!(current_piece.session_id == 0, "wrong session");
        assert!(current_piece.row == 5, "piece 52 x is wrong");
        assert!(current_piece.col == 2, "piece 52 y is wrong");
        assert!(current_piece.is_alive == true, "piece 52 is not alive");
        assert!(current_piece.is_king == false, "piece 52 is king");
        assert!(current_piece.position == Position::Up, "piece 52 is not right team");
        clear_world_event_log(world.dispatcher.contract_address);

        // Eats 61, jumps to 70
        actions_system.move_piece(current_piece, pos_61);
        let current_piece: Piece = world.read_model((session_id, pos_70));
        let emitted_events = retrieve_emitted_events(world);
        ensure_king_event(
            world,
            emitted_events,
            actions::King {
                session_id: current_piece.session_id,
                player: starknet::get_caller_address(),
                row: current_piece.row,
                col: current_piece.col,
            }
        );
        assert!(current_piece.session_id == 0, "wrong session");
        assert!(current_piece.row == 7, "piece 70 x is wrong");
        assert!(current_piece.col == 0, "piece 70 y is wrong");
        assert!(current_piece.is_alive == true, "piece 70 is not alive");
        assert!(current_piece.is_king == true, "piece 70 is king");
        assert!(current_piece.position == Position::Up, "piece 70 is not right team");
        
        actions_system.move_piece(current_piece, pos_34);
        let current_piece: Piece = world.read_model((session_id, pos_34));
        assert!(current_piece.session_id == 0, "wrong session");
        assert!(current_piece.row == 3, "piece 34 x is wrong");
        assert!(current_piece.col == 4, "piece 34 y is wrong");
        assert!(current_piece.is_alive == true, "piece 34 is not alive");
        assert!(current_piece.is_king == true, "piece 34 is king");
        assert!(current_piece.position == Position::Up, "piece 34 is not right team");
    }

    #[test]
    fn test_piece41_double_jump_straight_piece05() {
        let ndef = namespace_def();
        let mut world = spawn_test_world([ndef].span());
        world.sync_perms_and_inits(contract_defs());

        let player1 = starknet::contract_address_const::<0x0>();
        let player2 = starknet::contract_address_const::<0x1>();

        let (contract_address, _) = world.dns(@"actions").unwrap();
        let actions_system = IActionsDispatcher { contract_address };
        let session_id = actions_system.create_lobby();
        
        // Cheat call the second player
        starknet::testing::set_contract_address(player2);
        actions_system.join_lobby(session_id);

        let session: Session = world.read_model((session_id));
        assert(session.player_2 == player2, 'wrong player');
        
        // Reset player to default operation
        starknet::testing::set_contract_address(player1);

        // Arrange piece 05 -> 34, make space for double jump
        let pos_05 = Coordinates {row: 0, col: 5};
        let pos_14 = Coordinates {row: 1, col: 4};
        let pos_23 = Coordinates {row: 2, col: 3};
        let pos_32 = Coordinates {row: 3, col: 2};
        let pos_34 = Coordinates {row: 3, col: 4};
        let pos_41 = Coordinates {row: 4, col: 1};
        let pos_47 = Coordinates {row: 4, col: 1};
        let pos_50 = Coordinates {row: 5, col: 0};
        let pos_56 = Coordinates {row: 5, col: 0};
        
        let pieces_keys: Array<(u64, Coordinates)> = array![
            (session_id, pos_50),
            (session_id, pos_23),
            (session_id, pos_56),
            (session_id, pos_05),
        ];
        let pieces: Array<Piece> = world.read_models(pieces_keys.span());

        actions_system.move_piece(*pieces[0], pos_41);
        actions_system.move_piece(*pieces[1], pos_32);
        actions_system.move_piece(*pieces[2], pos_47);
        actions_system.move_piece(*pieces[3], pos_34);

        // Test all is arranged for souble straight jump
        let pieces_keys: Array<(u64, Coordinates)> = array![
            (session_id, pos_41), (session_id, pos_32),
        ];
        let pieces: Array<Piece> = world.read_models(pieces_keys.span());
        assert!(*pieces[0].is_alive == true, "piece 41 is not alive");
        assert!(*pieces[1].is_alive == true, "piece 32 is not alive");

        // Test 41 eats 32 and 14, jump 41(start) -> 32(eat) ->23 (land)-> 14(eat)-> 05(land)
        actions_system.move_piece(*pieces[0], pos_32);
        let pieces_keys: Array<(u64, Coordinates)> = array![
            (session_id, pos_23), (session_id, pos_32),
        ];
        let pieces: Array<Piece> = world.read_models(pieces_keys.span());
        let session: Session = world.read_model((session_id));
        assert!(*pieces[0].is_alive == true, "piece 23 is not alive");
        assert!(*pieces[1].is_alive == false, "piece 32 is alive");
        assert!(session.turn == 0, "turned changed");
        
        actions_system.move_piece(*pieces[0], pos_14);
        let pieces_keys: Array<(u64, Coordinates)> = array![
            (session_id, pos_23), (session_id, pos_14), (session_id, pos_05)
        ];
        let pieces: Array<Piece> = world.read_models(pieces_keys.span());
        let session: Session = world.read_model((session_id));
        assert!(*pieces[0].is_alive == false, "piece 23 is alive");
        assert!(*pieces[1].is_alive == false, "piece 14 is alive");
        assert!(*pieces[2].is_alive == true, "piece 05 is not alive");
        assert!(*pieces[2].position == Position::Down, "piece 05 wrong team");
        assert!(session.turn == 1, "turned not changed");
    }

    #[test]
    fn test_piece23_double_jump_zigzag_piece72() {
        let ndef = namespace_def();
        let mut world = spawn_test_world([ndef].span());
        world.sync_perms_and_inits(contract_defs());

        let player1 = starknet::contract_address_const::<0x0>();
        let player2 = starknet::contract_address_const::<0x1>();

        let (contract_address, _) = world.dns(@"actions").unwrap();
        let actions_system = IActionsDispatcher { contract_address };
        let session_id = actions_system.create_lobby();

        // Cheat call the second player
        starknet::testing::set_contract_address(player2);
        actions_system.join_lobby(session_id);

        let session: Session = world.read_model((session_id));
        assert(session.player_2 == player2, 'wrong player');
        
        // Reset player to default operation
        starknet::testing::set_contract_address(player1);

        // Arrange pieces for double zigzag
        let pos_23 = Coordinates {row: 2, col: 3};
        let pos_32 = Coordinates {row: 3, col: 2};
        let pos_41 = Coordinates {row: 4, col: 1};
        let pos_43 = Coordinates {row: 4, col: 3};
        let pos_50 = Coordinates {row: 5, col: 0};
        let pos_61 = Coordinates {row: 6, col: 1};
        let pos_72 = Coordinates {row: 7, col: 2};

        let pieces_keys: Array<(u64, Coordinates)> = array![
            (session_id, pos_72),
            (session_id, pos_23),
            (session_id, pos_50),
        ];
        let pieces: Array<Piece> = world.read_models(pieces_keys.span());

        actions_system.move_piece(*pieces[0], pos_43);
        actions_system.move_piece(*pieces[1], pos_32);
        actions_system.move_piece(*pieces[2], pos_41);

        // Test all is arranged for double zigzag jump
        let pieces_keys: Array<(u64, Coordinates)> = array![
            (session_id, pos_32), (session_id, pos_41), (session_id, pos_72), 
        ];
        let pieces: Array<Piece> = world.read_models(pieces_keys.span());
        assert!(*pieces[0].is_alive == true, "piece 32 is not alive");
        assert!(*pieces[1].is_alive == true, "piece 41 is not alive");
        assert!(*pieces[2].is_alive == false, "piece 72 is alive");

        // Test 32 eats 41 and 61, jump 32->50->72
        actions_system.move_piece(*pieces[0], pos_41);
        let pieces_keys: Array<(u64, Coordinates)> = array![
            (session_id, pos_50), (session_id, pos_41),
        ];
        let pieces: Array<Piece> = world.read_models(pieces_keys.span());
        let session: Session = world.read_model((session_id));
        assert!(*pieces[0].is_alive == true, "piece 50 is not alive");
        assert!(*pieces[1].is_alive == false, "piece 41 is alive");
        assert!(*pieces[0].position == Position::Up, "piece 50 wrong team");
        assert!(session.turn == 1, "turn changed");
        
        actions_system.move_piece(*pieces[0], pos_61);
        let pieces_keys: Array<(u64, Coordinates)> = array![
            (session_id, pos_50), (session_id, pos_61), (session_id, pos_72)
        ];
        let pieces: Array<Piece> = world.read_models(pieces_keys.span());
        let session: Session = world.read_model((session_id));
        assert!(*pieces[0].is_alive == false, "piece 50 is alive");
        assert!(*pieces[1].is_alive == false, "piece 61 is alive");
        assert!(*pieces[2].is_alive == true, "piece 72 is not alive");
        assert!(*pieces[2].position == Position::Up, "piece 05 wrong team");
        assert!(session.turn == 0, "turned not changed");
    }

    #[test]
    fn test_king05_triple_jump_zigzag_piece23() {
        let ndef = namespace_def();
        let mut world = spawn_test_world([ndef].span());
        world.sync_perms_and_inits(contract_defs());

        let player1 = starknet::contract_address_const::<0x0>();
        let player2 = starknet::contract_address_const::<0x1>();

        let (contract_address, _) = world.dns(@"actions").unwrap();
        let actions_system = IActionsDispatcher { contract_address };
        let session_id = actions_system.create_lobby();
        
        // Cheat call the second player
        starknet::testing::set_contract_address(player2);
        actions_system.join_lobby(session_id);

        let session: Session = world.read_model((session_id));
        assert(session.player_2 == player2, 'wrong player');
        
        // Reset player to default operation
        starknet::testing::set_contract_address(player1);

        // All needed coordinates for test
        let pos_05 = Coordinates {row: 0, col: 5};
        let pos_14 = Coordinates {row: 1, col: 4};
        let pos_16 = Coordinates {row: 1, col: 6};
        let pos_23 = Coordinates {row: 2, col: 3};
        let pos_25 = Coordinates {row: 2, col: 5};
        let pos_27 = Coordinates {row: 2, col: 7};
        let pos_30 = Coordinates {row: 3, col: 0};
        let pos_32 = Coordinates {row: 3, col: 2};
        let pos_34 = Coordinates {row: 3, col: 4};
        let pos_36 = Coordinates {row: 3, col: 6};
        let pos_41 = Coordinates {row: 4, col: 1};
        let pos_43 = Coordinates {row: 4, col: 3};
        let pos_45 = Coordinates {row: 4, col: 5};
        let pos_47 = Coordinates {row: 4, col: 7};
        let pos_50 = Coordinates {row: 5, col: 0};
        let pos_54 = Coordinates {row: 5, col: 4};
        let pos_56 = Coordinates {row: 5, col: 6};
        let pos_61 = Coordinates {row: 6, col: 1};
        let pos_70 = Coordinates {row: 7, col: 0};

        // Arrange pieces for scenario
        let pieces_keys: Array<(u64, Coordinates)> = array![
            (session_id, pos_56),
            (session_id, pos_05),
            (session_id, pos_54),
            (session_id, pos_25),
            (session_id, pos_50),
            (session_id, pos_27),
            (session_id, pos_61),
            (session_id, pos_23),
            (session_id, pos_70),
            (session_id, pos_14),
        ];
        let pieces: Array<Piece> = world.read_models(pieces_keys.span());

        actions_system.move_piece(*pieces[0], pos_47);
        actions_system.move_piece(*pieces[1], pos_30);
        actions_system.move_piece(*pieces[2], pos_43);
        actions_system.move_piece(*pieces[3], pos_34);
        actions_system.move_piece(*pieces[4], pos_05);
        actions_system.move_piece(*pieces[5], pos_36);
        actions_system.move_piece(*pieces[6], pos_50);
        actions_system.move_piece(*pieces[7], pos_32);
        actions_system.move_piece(*pieces[8], pos_61);
        actions_system.move_piece(*pieces[9], pos_41);

        // Test all is arranged for triple zigzag king jump
        let session: Session = world.read_model((session_id));
        let king: Piece = world.read_model((session_id, pos_05));
        assert!(king.is_alive == true, "king 05 is not alive");
        assert!(king.is_king == true, "king 05 is not king");
        assert!(king.position == Position::Down, "king 05 wrong team");
        assert!(session.turn == 0, "turn is wrong");
        
        // Test 05 eats 16 lands 27
        actions_system.move_piece(king, pos_16);
        let pieces_keys: Array<(u64, Coordinates)> = array![
            (session_id, pos_05),
            (session_id, pos_16),
            (session_id, pos_27),
        ];
        let pieces: Array<Piece> = world.read_models(pieces_keys.span());
        let session: Session = world.read_model((session_id));
        assert!(*pieces[0].is_alive == false, "piece 05 is alive");
        assert!(*pieces[1].is_alive == false, "piece 16 is alive");
        assert!(*pieces[2].is_alive == true, "king 27 is not alive");
        assert!(*pieces[2].is_king == true, "king 27 is not king");
        assert!(*pieces[2].position == Position::Down, "king 27 wrong team");
        assert!(session.turn == 0, "turn changed");

        // Test 27 eats 36 lands 45
        actions_system.move_piece(*pieces[2], pos_36);
        let pieces_keys: Array<(u64, Coordinates)> = array![
            (session_id, pos_27),
            (session_id, pos_36),
            (session_id, pos_45),
        ];
        let pieces: Array<Piece> = world.read_models(pieces_keys.span());
        let session: Session = world.read_model((session_id));
        assert!(*pieces[0].is_alive == false, "piece 27 is alive");
        assert!(*pieces[1].is_alive == false, "piece 36 is alive");
        assert!(*pieces[2].is_alive == true, "king 45 is not alive");
        assert!(*pieces[2].is_king == true, "king 45 is not king");
        assert!(*pieces[2].position == Position::Down, "king 45 wrong team");
        assert!(session.turn == 0, "turn changed");

        // Test 45 eats 34 lands 23
        actions_system.move_piece(*pieces[2], pos_34);
        let pieces_keys: Array<(u64, Coordinates)> = array![
            (session_id, pos_45),
            (session_id, pos_34),
            (session_id, pos_23),
        ];
        let pieces: Array<Piece> = world.read_models(pieces_keys.span());
        let session: Session = world.read_model((session_id));
        assert!(*pieces[0].is_alive == false, "piece 45 is alive");
        assert!(*pieces[1].is_alive == false, "piece 34 is alive");
        assert!(*pieces[2].is_alive == true, "king 23 is not alive");
        assert!(*pieces[2].is_king == true, "king 23 is not king");
        assert!(*pieces[2].position == Position::Down, "king 23 wrong team");
        assert!(session.turn == 1, "turn not changed");
    }

    #[test]
    fn test_king72_quad_jump_zigzag_piece72() {
        let ndef = namespace_def();
        let mut world = spawn_test_world([ndef].span());
        world.sync_perms_and_inits(contract_defs());

        let player1 = starknet::contract_address_const::<0x0>();
        let player2 = starknet::contract_address_const::<0x1>();

        let (contract_address, _) = world.dns(@"actions").unwrap();
        let actions_system = IActionsDispatcher { contract_address };
        let session_id = actions_system.create_lobby();
        
        // Cheat call the second player
        starknet::testing::set_contract_address(player2);
        actions_system.join_lobby(session_id);

        let session: Session = world.read_model((session_id));
        assert(session.player_2 == player2, 'wrong player');
        
        // Reset player to default operation
        starknet::testing::set_contract_address(player1);

        // All needed coordinates for test
        let pos_05 = Coordinates {row: 0, col: 5};
        let pos_16 = Coordinates {row: 1, col: 6};
        let pos_27 = Coordinates {row: 2, col: 7};
        let pos_30 = Coordinates {row: 3, col: 0};
        let pos_32 = Coordinates {row: 3, col: 2};
        let pos_41 = Coordinates {row: 4, col: 1};
        let pos_43 = Coordinates {row: 4, col: 3};
        let pos_45 = Coordinates {row: 4, col: 5};
        let pos_50 = Coordinates {row: 5, col: 0};
        let pos_52 = Coordinates {row: 5, col: 2};
        let pos_54 = Coordinates {row: 5, col: 4};
        let pos_61 = Coordinates {row: 6, col: 1};
        let pos_63 = Coordinates {row: 6, col: 3};
        let pos_72 = Coordinates {row: 7, col: 2};

        // Arrange pieces for scenario
        let pieces_keys: Array<(u64, Coordinates)> = array![
            (session_id, pos_72),
            (session_id, pos_27),
            (session_id, pos_50),
            (session_id, pos_16),
            (session_id, pos_52),
            (session_id, pos_05),
            (session_id, pos_54),
        ];
        let pieces: Array<Piece> = world.read_models(pieces_keys.span());

        actions_system.move_piece(*pieces[0], pos_30);
        actions_system.move_piece(*pieces[1], pos_72);
        actions_system.move_piece(*pieces[2], pos_41);
        actions_system.move_piece(*pieces[3], pos_27);
        actions_system.move_piece(*pieces[4], pos_43);
        actions_system.move_piece(*pieces[5], pos_16);
        actions_system.move_piece(*pieces[6], pos_45);

        // Test all is arranged for quad zigzag king jump
        let session: Session = world.read_model((session_id));
        let king: Piece = world.read_model((session_id, pos_72));
        assert!(king.is_alive == true, "king 72 is not alive");
        assert!(king.is_king == true, "king 72 is not king");
        assert!(king.position == Position::Up, "king 72 wrong team");
        assert!(session.turn == 1, "turn is wrong");
        
        // Test 72 eats 63 lands 54
        actions_system.move_piece(king, pos_63);
        let pieces_keys: Array<(u64, Coordinates)> = array![
            (session_id, pos_72),
            (session_id, pos_63),
            (session_id, pos_54),
        ];
        let pieces: Array<Piece> = world.read_models(pieces_keys.span());
        let session: Session = world.read_model((session_id));
        assert!(*pieces[0].is_alive == false, "piece 72 is alive");
        assert!(*pieces[1].is_alive == false, "piece 63 is alive");
        assert!(*pieces[2].is_alive == true, "king 54 is not alive");
        assert!(*pieces[2].is_king == true, "king 54 is not king");
        assert!(*pieces[2].position == Position::Up, "king 54 wrong team");
        assert!(session.turn == 1, "turn changed");

        // Test 54 eats 43 lands 32
        actions_system.move_piece(*pieces[2], pos_43);
        let pieces_keys: Array<(u64, Coordinates)> = array![
            (session_id, pos_54),
            (session_id, pos_43),
            (session_id, pos_32),
        ];
        let pieces: Array<Piece> = world.read_models(pieces_keys.span());
        let session: Session = world.read_model((session_id));
        assert!(*pieces[0].is_alive == false, "piece 54 is alive");
        assert!(*pieces[1].is_alive == false, "piece 43 is alive");
        assert!(*pieces[2].is_alive == true, "king 32 is not alive");
        assert!(*pieces[2].is_king == true, "king 32 is not king");
        assert!(*pieces[2].position == Position::Up, "king 32 wrong team");
        assert!(session.turn == 1, "turn changed");

        // Test 32 eats 41 lands 50
        actions_system.move_piece(*pieces[2], pos_41);
        let pieces_keys: Array<(u64, Coordinates)> = array![
            (session_id, pos_32),
            (session_id, pos_41),
            (session_id, pos_50),
        ];
        let pieces: Array<Piece> = world.read_models(pieces_keys.span());
        let session: Session = world.read_model((session_id));
        assert!(*pieces[0].is_alive == false, "piece 32 is alive");
        assert!(*pieces[1].is_alive == false, "piece 41 is alive");
        assert!(*pieces[2].is_alive == true, "king 50 is not alive");
        assert!(*pieces[2].is_king == true, "king 250 is not king");
        assert!(*pieces[2].position == Position::Up, "king 50 wrong team");
        assert!(session.turn == 1, "turn changed");

        // Test 50 eats 61 lands 72
        actions_system.move_piece(*pieces[2], pos_61);
        let pieces_keys: Array<(u64, Coordinates)> = array![
            (session_id, pos_50),
            (session_id, pos_61),
            (session_id, pos_72),
        ];
        let pieces: Array<Piece> = world.read_models(pieces_keys.span());
        let session: Session = world.read_model((session_id));
        assert!(*pieces[0].is_alive == false, "piece 50 is alive");
        assert!(*pieces[1].is_alive == false, "piece 61 is alive");
        assert!(*pieces[2].is_alive == true, "king 72 is not alive");
        assert!(*pieces[2].is_king == true, "king 72 is not king");
        assert!(*pieces[2].position == Position::Up, "king 72 wrong team");
        assert!(session.turn == 0, "turn not changed");
    }

    #[test]
    fn test_session_creation() {
        let ndef = namespace_def();
        let mut world = spawn_test_world([ndef].span());
        world.sync_perms_and_inits(contract_defs());

        let player1 = starknet::contract_address_const::<0x0>();
        let (contract_address, _) = world.dns(@"actions").unwrap();
        let actions_system = IActionsDispatcher { contract_address };
        let session_id = actions_system.create_lobby();
        let session: Session = world.read_model((session_id));
        assert!(session.state == 0, "wrong session state");
        // Cheat call the second player
        let player2 = starknet::contract_address_const::<0x1>();
        starknet::testing::set_contract_address(player2);
        actions_system.join_lobby(session_id);
        // Re read the model once the second player joins
        let session: Session = world.read_model((session_id));

        assert!(session.player_1 == player1, "wrong player");
        assert!(session.player_2 == player2, "wrong player");
        assert!(session.turn == 0, "wrong turn");
        assert!(session.state == 1, "wrong session state");
    }

    #[test]
    fn test_turn_switch() {
        let ndef = namespace_def();
        let mut world = spawn_test_world([ndef].span());
        world.sync_perms_and_inits(contract_defs());

        let player1 = starknet::contract_address_const::<0x0>();
        let (contract_address, _) = world.dns(@"actions").unwrap();
        let actions_system = IActionsDispatcher { contract_address };
        let session_id = actions_system.create_lobby();
        // Cheat call the second player
        let player2 = starknet::contract_address_const::<0x1>();
        starknet::testing::set_contract_address(player2);
        actions_system.join_lobby(session_id);
        // Read session model
        let session: Session = world.read_model((session_id));

        assert!(session.player_1 == player1, "wrong player");
        assert!(session.player_2 == player2, "wrong player");
        assert!(session.turn == 0, "wrong turn");
        assert!(session.state == 1, "wrong session state");

        // Test initial position 21 & 56
        let valid_piece_position21 = Coordinates { row: 2, col: 1 };
        let valid_piece_position56 = Coordinates { row: 5, col: 6 };
        let initial_pieces_keys: Array<(u64, Coordinates)> = array![
            (session_id, valid_piece_position21), (session_id, valid_piece_position56),
        ];
        let initial_pieces: Array<Piece> = world.read_models(initial_pieces_keys.span());
        assert(initial_pieces.len() == 2, 'read_models failed');

        assert(
            *initial_pieces[0].row == 2 && *initial_pieces[0].col == 1, 'wrong initial piece 21'
        );
        assert(
            *initial_pieces[1].row == 5 && *initial_pieces[1].col == 6, 'wrong initial piece 56'
        );
        for piece in initial_pieces
            .clone() {
                assert(piece.session_id == 0, 'wrong session');
                assert(piece.is_king == false, 'piece is king');
                assert(piece.is_alive == true, 'piece is not alive');
            };

        // Test move to positions 32 & 45
        let can_choose_piece21 = actions_system
            .can_choose_piece(Position::Up, valid_piece_position21, session_id);
        assert(can_choose_piece21, 'can_choose_piece 21 failed');
        let new_coordinates_position32 = Coordinates { row: 3, col: 2 };
        actions_system.move_piece(*initial_pieces[0], new_coordinates_position32);

        // Check if turn changed for player 2
        let session: Session = world.read_model((session_id));
        assert!(session.turn == 1, "wrong turn");

        let can_choose_piece56 = actions_system
            .can_choose_piece(Position::Down, valid_piece_position56, session_id);
        assert(can_choose_piece56, 'can_choose_piece 56 failed');
        let new_coordinates_position45 = Coordinates { row: 4, col: 5 };
        actions_system.move_piece(*initial_pieces[1], new_coordinates_position45);

        // Check if turn changed back to player 1
        let session: Session = world.read_model((session_id));
        assert!(session.turn == 0, "wrong turn");

        let new_coordinates_keys: Array<(u64, Coordinates)> = array![
            (session_id, new_coordinates_position32), (session_id, new_coordinates_position45),
        ];
        let new_positions: Array<Piece> = world.read_models(new_coordinates_keys.span());
        assert(new_positions.len() == 2, 'read_models failed');

        assert!(*new_positions[0].row == 3, "piece x is wrong");
        assert!(*new_positions[0].col == 2, "piece y is wrong");
        assert!(*new_positions[1].row == 4, "piece x is wrong");
        assert!(*new_positions[1].col == 5, "piece y is wrong");
        for new_position in new_positions {
            assert!(new_position.session_id == 0, "wrong session");
            assert!(new_position.is_alive == true, "piece is not alive");
            assert!(new_position.is_king == false, "piece is king");
        };
    }

    #[test]
    fn test_counter_get_value() {
        let ndef = namespace_def();
        let mut world = spawn_test_world([ndef].span());
        world.sync_perms_and_inits(contract_defs());

        let counter_key: felt252 = 'id';
        let counter: Counter = world.read_model((counter_key));
        assert(counter.get_value() == 0, 'initial value is not zero');
    }

    #[test]
    fn test_counter_increment() {
        let ndef = namespace_def();
        let mut world = spawn_test_world([ndef].span());
        world.sync_perms_and_inits(contract_defs());

        let counter_key: felt252 = 'id';
        let mut counter: Counter = world.read_model((counter_key));
        counter.increment();
        world.write_model(@counter);

        let updated_counter: Counter = world.read_model((counter_key));
        assert(updated_counter.get_value() == 1, 'increment failed');
    }

    #[test]
    fn test_counter_decrement() {
        let ndef = namespace_def();
        let mut world = spawn_test_world([ndef].span());
        world.sync_perms_and_inits(contract_defs());

        let counter_key: felt252 = 'id';
        let mut counter: Counter = world.read_model((counter_key));
        counter.increment();
        counter.increment();
        world.write_model(@counter);

        let mut updated_counter: Counter = world.read_model((counter_key));
        updated_counter.decrement();
        world.write_model(@updated_counter);

        let final_counter: Counter = world.read_model((counter_key));
        assert(final_counter.get_value() == 1, 'decrement failed');
    }

    #[test]
    fn test_counter_reset() {
        let ndef = namespace_def();
        let mut world = spawn_test_world([ndef].span());
        world.sync_perms_and_inits(contract_defs());

        let counter_key: felt252 = 'id';
        let mut counter: Counter = world.read_model((counter_key));
        counter.increment();
        counter.increment();
        world.write_model(@counter);

        let mut updated_counter: Counter = world.read_model((counter_key));
        updated_counter.reset();
        world.write_model(@updated_counter);

        let final_counter: Counter = world.read_model((counter_key));
        assert(final_counter.get_value() == 0, 'reset failed');
    }

    #[test]
    fn test_session_id() {
        let ndef = namespace_def();
        let mut world = spawn_test_world([ndef].span());
        world.sync_perms_and_inits(contract_defs());

        let (contract_address, _) = world.dns(@"actions").unwrap();
        let actions_system = IActionsDispatcher { contract_address };

        // Create multiple lobbies
        let session_id1 = actions_system.create_lobby();
        let retrieved_session_id1 = actions_system.get_session_id();

        let session_id2 = actions_system.create_lobby();
        let retrieved_session_id2 = actions_system.get_session_id();

        let session_id3 = actions_system.create_lobby();
        let retrieved_session_id3 = actions_system.get_session_id();

        // Verify each session_id
        let session1: Session = world.read_model((session_id1));
        assert(session1.session_id == session_id1, 'wrong session_id for lobby 1');

        let session2: Session = world.read_model((session_id2));
        assert(session2.session_id == session_id2, 'wrong session_id for lobby 2');

        let session3: Session = world.read_model((session_id3));
        assert(session3.session_id == session_id3, 'wrong session_id for lobby 3');

        assert(retrieved_session_id1 == session_id1, 'get_session_id failed lobby 1');

        assert(retrieved_session_id2 == session_id2, 'get_session_id failed lobby 2');

        assert(retrieved_session_id3 == session_id3, 'get_session_id failed lobby 3');
    }
}
