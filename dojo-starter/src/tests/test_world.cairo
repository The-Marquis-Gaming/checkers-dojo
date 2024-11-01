#[cfg(test)]
mod tests {
    use dojo::model::{ModelStorage, ModelValueStorage, ModelStorageTest};
    use dojo::world::WorldStorageTrait;
    use dojo_cairo_test::{spawn_test_world, NamespaceDef, TestResource, ContractDefTrait};

    use dojo_starter::systems::actions::{actions, IActionsDispatcher, IActionsDispatcherTrait};
    use dojo_starter::models::{Piece, m_Piece, Position};

    fn namespace_def() -> NamespaceDef {
        let ndef = NamespaceDef {
            namespace: "dojo_starter", resources: [
                TestResource::Model(m_Piece::TEST_CLASS_HASH.try_into().unwrap()),
                //TestResource::Model(m_Moves::TEST_CLASS_HASH.try_into().unwrap()),
                TestResource::Event(actions::e_Moved::TEST_CLASS_HASH.try_into().unwrap()),
                TestResource::Contract(
                    ContractDefTrait::new(actions::TEST_CLASS_HASH, "actions")
                        .with_writer_of([dojo::utils::bytearray_hash(@"dojo_starter")].span())
                )
            ].span()
        };

        ndef
    }

    #[test]
    fn test_world_test_set() {
        // Initialize test environment
        let caller = starknet::contract_address_const::<0x0>();
        let ndef = namespace_def();
        let mut world = spawn_test_world([ndef].span());

        // Test initial piece
        let piece_position_77 = Position { raw: 7, col: 7 };
        let piece: Piece = world.read_model((caller, piece_position_77));
        assert(piece.is_alive == false, 'initial piece wrong');

        // Test write_model_test
        let piece_vec = Position { raw: 1, col: 1 };
        let piece = Piece { player: caller, position: piece_vec, is_king: true, is_alive: true };

        world.write_model_test(@piece);

        let piece: Piece = world.read_model((caller, piece_vec));
        assert(piece.is_king == true, 'write_value_from_id failed');
        assert(piece.is_alive == true, 'write_value_from_id failed');
        // Test model deletion
        world.erase_model(@piece);
        let piece: Piece = world.read_model((caller, piece_vec));
        assert(piece.is_king == false, 'erase_model failed');
        assert(piece.is_alive == false, 'erase_model failed');
    }

    #[test]
    fn test_can_not_choose_piece() {
        //let caller = starknet::contract_address_const::<0x0>();

        let ndef = namespace_def();
        let mut world = spawn_test_world([ndef].span());

        let (contract_address, _) = world.dns(@"actions").unwrap();
        let actions_system = IActionsDispatcher { contract_address };

        actions_system.spawn();

        // test first row
        let invalid_piece_position00 = Position { raw: 0, col: 0 }; // Empty square
        let can_choose_piece = actions_system.can_choose_piece(invalid_piece_position00);
        assert(!can_choose_piece, 'should be false');

        let invalid_piece_position01 = Position { raw: 0, col: 1 };
        let can_choose_piece = actions_system.can_choose_piece(invalid_piece_position01);
        assert(!can_choose_piece, 'should be false');

        let invalid_piece_position02 = Position { raw: 0, col: 2 }; // Empty square
        let can_choose_piece = actions_system.can_choose_piece(invalid_piece_position02);
        assert(!can_choose_piece, 'should be false');

        let invalid_piece_position03 = Position { raw: 0, col: 3 };
        let can_choose_piece = actions_system.can_choose_piece(invalid_piece_position03);
        assert(!can_choose_piece, 'should be false');

        let invalid_piece_position04 = Position { raw: 0, col: 4 }; // Empty square
        let can_choose_piece = actions_system.can_choose_piece(invalid_piece_position04);
        assert(!can_choose_piece, 'should be false');

        let invalid_piece_position05 = Position { raw: 0, col: 5 };
        let can_choose_piece = actions_system.can_choose_piece(invalid_piece_position05);
        assert(!can_choose_piece, 'should be false');

        let invalid_piece_position06 = Position { raw: 0, col: 6 }; // Empty square
        let can_choose_piece = actions_system.can_choose_piece(invalid_piece_position06);
        assert(!can_choose_piece, 'should be false');

        let invalid_piece_position07 = Position { raw: 0, col: 7 };
        let can_choose_piece = actions_system.can_choose_piece(invalid_piece_position07);
        assert(!can_choose_piece, 'should be false');

        // test second row
        let invalid_piece_position10 = Position { raw: 1, col: 0 };
        let can_choose_piece = actions_system.can_choose_piece(invalid_piece_position10);
        assert(!can_choose_piece, 'should be false');

        let invalid_piece_position11 = Position { raw: 1, col: 1 }; // Empty square
        let can_choose_piece = actions_system.can_choose_piece(invalid_piece_position11);
        assert(!can_choose_piece, 'should be false');

        let invalid_piece_position12 = Position { raw: 1, col: 2 };
        let can_choose_piece = actions_system.can_choose_piece(invalid_piece_position12);
        assert(!can_choose_piece, 'should be false');

        let invalid_piece_position13 = Position { raw: 1, col: 3 }; // Empty square
        let can_choose_piece = actions_system.can_choose_piece(invalid_piece_position13);
        assert(!can_choose_piece, 'should be false');

        let invalid_piece_position14 = Position { raw: 1, col: 4 };
        let can_choose_piece = actions_system.can_choose_piece(invalid_piece_position14);
        assert(!can_choose_piece, 'should be false');

        let invalid_piece_position15 = Position { raw: 1, col: 5 }; // Empty square
        let can_choose_piece = actions_system.can_choose_piece(invalid_piece_position15);
        assert(!can_choose_piece, 'should be false');

        let invalid_piece_position16 = Position { raw: 1, col: 6 };
        let can_choose_piece = actions_system.can_choose_piece(invalid_piece_position16);
        assert(!can_choose_piece, 'should be false');

        let invalid_piece_position17 = Position { raw: 1, col: 7 }; // Empty square
        let can_choose_piece = actions_system.can_choose_piece(invalid_piece_position17);
        assert(!can_choose_piece, 'should be false');

        // test third row
        let invalid_piece_position20 = Position { raw: 2, col: 0 }; // Empty square
        let can_choose_piece = actions_system.can_choose_piece(invalid_piece_position20);
        assert(!can_choose_piece, 'should be false');

        let invalid_piece_position22 = Position { raw: 2, col: 2 }; // Empty square
        let can_choose_piece = actions_system.can_choose_piece(invalid_piece_position22);
        assert(!can_choose_piece, 'should be false');

        let invalid_piece_position24 = Position { raw: 2, col: 4 }; // Empty square
        let can_choose_piece = actions_system.can_choose_piece(invalid_piece_position24);
        assert(!can_choose_piece, 'should be false');

        let invalid_piece_position26 = Position { raw: 2, col: 6 }; // Empty square
        let can_choose_piece = actions_system.can_choose_piece(invalid_piece_position26);
        assert(!can_choose_piece, 'should be false');
    }
    #[test]
    fn test_can_choose_piece() {
        //let caller = starknet::contract_address_const::<0x0>();

        let ndef = namespace_def();
        let mut world = spawn_test_world([ndef].span());

        let (contract_address, _) = world.dns(@"actions").unwrap();
        let actions_system = IActionsDispatcher { contract_address };

        actions_system.spawn();

        // test third row
        let valid_piece_position21 = Position { raw: 2, col: 1 };
        let can_choose_piece = actions_system.can_choose_piece(valid_piece_position21);
        assert(can_choose_piece, 'should be true');

        let valid_piece_position23 = Position { raw: 2, col: 3 };
        let can_choose_piece = actions_system.can_choose_piece(valid_piece_position23);
        assert(can_choose_piece, 'should be true');

        let valid_piece_position25 = Position { raw: 2, col: 5 };
        let can_choose_piece = actions_system.can_choose_piece(valid_piece_position25);
        assert(can_choose_piece, 'should be true');

        let valid_piece_position27 = Position { raw: 2, col: 7 };
        let can_choose_piece = actions_system.can_choose_piece(valid_piece_position27);
        assert(can_choose_piece, 'should be true');
    }

    // Test can choose piece but can not move
    #[test]
    #[should_panic(expected: ('Invalid position', 'ENTRYPOINT_FAILED'))]
    fn test_move_piece31_forward_straight_fails() {
        let caller = starknet::contract_address_const::<0x0>();

        let ndef = namespace_def();
        let mut world = spawn_test_world([ndef].span());

        let (contract_address, _) = world.dns(@"actions").unwrap();
        let actions_system = IActionsDispatcher { contract_address };

        actions_system.spawn();
        let valid_piece_position = Position { raw: 2, col: 1 };

        let can_choose_piece = actions_system.can_choose_piece(valid_piece_position);
        assert(can_choose_piece, 'can_choose_piece failed');

        let current_piece = world.read_model((caller, valid_piece_position));
        let new_coordinates_position = Position { raw: 3, col: 1 };
        actions_system.move_piece(current_piece, new_coordinates_position);
    }

    #[test]
    #[should_panic(expected: ('Invalid position', 'ENTRYPOINT_FAILED'))]
    fn test_move_piece37_forward_right_fails() {
        let caller = starknet::contract_address_const::<0x0>();

        let ndef = namespace_def();
        let mut world = spawn_test_world([ndef].span());

        let (contract_address, _) = world.dns(@"actions").unwrap();
        let actions_system = IActionsDispatcher { contract_address };

        actions_system.spawn();
        let valid_piece_position = Position { raw: 2, col: 7 };

        let can_choose_piece = actions_system.can_choose_piece(valid_piece_position);
        assert(can_choose_piece, 'can_choose_piece failed');

        let current_piece = world.read_model((caller, valid_piece_position));
        let new_coordinates_position = Position { raw: 3, col: 8 };
        actions_system.move_piece(current_piece, new_coordinates_position);
    }

    #[test]
    fn test_move_piece21_down_left() {
        let caller = starknet::contract_address_const::<0x0>();

        let ndef = namespace_def();
        let mut world = spawn_test_world([ndef].span());

        let (contract_address, _) = world.dns(@"actions").unwrap();
        let actions_system = IActionsDispatcher { contract_address };

        actions_system.spawn();
        let valid_piece_position = Position { raw: 2, col: 1 };
        let initial_piece_position: Piece = world.read_model((caller, valid_piece_position));

        assert(
            initial_piece_position.position.raw == 2 && initial_piece_position.position.col == 1,
            'wrong initial piece'
        );
        assert(initial_piece_position.is_king == false, 'wrong initial piece');
        assert(initial_piece_position.is_alive == true, 'wrong initial piece');

        let can_choose_piece = actions_system.can_choose_piece(valid_piece_position);
        assert(can_choose_piece, 'can_choose_piece failed');
        let current_piece: Piece = world.read_model((caller, valid_piece_position));
        let new_coordinates_position = Position { raw: 3, col: 0 };
        actions_system.move_piece(current_piece, new_coordinates_position);

        let new_position: Piece = world.read_model((caller, new_coordinates_position));

        assert!(new_position.position.raw == 3, "piece x is wrong");
        assert!(new_position.position.col == 0, "piece y is wrong");
        assert!(new_position.is_alive == true, "piece is not alive");
        assert!(new_position.is_king == false, "piece is king");
    }
    #[test]
    fn test_move_piece21_down_right() {
        let caller = starknet::contract_address_const::<0x0>();

        let ndef = namespace_def();
        let mut world = spawn_test_world([ndef].span());

        let (contract_address, _) = world.dns(@"actions").unwrap();
        let actions_system = IActionsDispatcher { contract_address };

        actions_system.spawn();
        let valid_piece_position = Position { raw: 2, col: 1 };
        let initial_piece_position: Piece = world.read_model((caller, valid_piece_position));

        assert(
            initial_piece_position.position.raw == 2 && initial_piece_position.position.col == 1,
            'wrong initial piece'
        );
        assert(initial_piece_position.is_king == false, 'wrong initial piece');
        assert(initial_piece_position.is_alive == true, 'wrong initial piece');

        let can_choose_piece = actions_system.can_choose_piece(valid_piece_position);
        assert(can_choose_piece, 'can_choose_piece failed');
        let current_piece: Piece = world.read_model((caller, valid_piece_position));
        let new_coordinates_position = Position { raw: 3, col: 2 };
        actions_system.move_piece(current_piece, new_coordinates_position);

        let new_position: Piece = world.read_model((caller, new_coordinates_position));

        assert!(new_position.position.raw == 3, "piece x is wrong");
        assert!(new_position.position.col == 2, "piece y is wrong");
        assert!(new_position.is_alive == true, "piece is not alive");
        assert!(new_position.is_king == false, "piece is king");
    }
}
