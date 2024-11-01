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
        // Todo: fix this test, bug in read_model?
        // let piece77_vec = Vec2 { x: 7, y: 7 };
        // let mut piece00: Piece = world.read_model((caller, piece77_vec));
        // println!("piece00.vec.x: {}", piece00.vec.x);
        // println!("piece00.vec.y: {}", piece00.vec.y);
        // assert(piece00.vec.x == 0 && piece00.vec.y == 0, 'initial piece wrong');
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
    #[available_gas(30000000)]
    fn test_can_not_choose_piece() {
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

        let invalid_piece_position = Position { raw: 7, col: 7 };
        let can_choose_piece = actions_system.can_choose_piece(invalid_piece_position);
        assert(!can_choose_piece, 'should be false');
    }
    #[test]
    #[available_gas(30000000)]
    fn test_can_choose_piece() {
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
        assert(can_choose_piece, 'should be true');
    }
    #[test]
    fn test_move_down_left() {
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
        let new_coordinates_position = Position { raw: 3, col: 0 };
        actions_system.move_piece(new_coordinates_position);

        let new_position: Piece = world.read_model((caller, new_coordinates_position));

        assert!(new_position.position.raw == 3, "piece x is wrong");
        assert!(new_position.position.col == 0, "piece y is wrong");
        assert!(new_position.is_alive == true, "piece is not alive");
        assert!(new_position.is_king == false, "piece is king");
    }
    #[test]
    fn test_move_down_right() {
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
        let new_coordinates_position = Position { raw: 3, col: 2 };
        actions_system.move_piece(new_coordinates_position);

        let new_position: Piece = world.read_model((caller, new_coordinates_position));

        assert!(new_position.position.raw == 3, "piece x is wrong");
        assert!(new_position.position.col == 2, "piece y is wrong");
        assert!(new_position.is_alive == true, "piece is not alive");
        assert!(new_position.is_king == false, "piece is king");
    }
}
