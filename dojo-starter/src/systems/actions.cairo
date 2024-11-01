use dojo_starter::models::Piece;
use dojo_starter::models::Position;

// define the interface
#[starknet::interface]
trait IActions<T> {
    fn spawn(ref self: T);
    fn can_choose_piece(ref self: T, coordinates_position: Position) -> bool;
    fn move_piece(ref self: T, coordinates_position: Position);
}

// dojo decorator
#[dojo::contract]
pub mod actions {
    use super::{IActions, update_piece_position};
    use starknet::{ContractAddress, get_caller_address};
    use dojo_starter::models::{Piece, Position};

    use dojo::model::{ModelStorage, ModelValueStorage};
    use dojo::event::EventStorage;

    #[derive(Copy, Drop, Serde)]
    #[dojo::event]
    pub struct Moved {
        #[key]
        pub player: ContractAddress,
        pub position: Position,
    }

    #[abi(embed_v0)]
    impl ActionsImpl of IActions<ContractState> {
        fn spawn(ref self: ContractState) {
            // Get the default world.
            let mut world = self.world_default();

            // Get the address of the current caller, possibly the player's address.
            let player = get_caller_address();

            // Update the world state with the new data.

            // Create the pieces for the player. Upper side of the board.
            let piece01 = Piece {
                player, position: Position { raw: 0, col: 1 }, is_king: false, is_alive: true
            };
            let piece03 = Piece {
                player, position: Position { raw: 0, col: 3 }, is_king: false, is_alive: true
            };
            let piece05 = Piece {
                player, position: Position { raw: 0, col: 5 }, is_king: false, is_alive: true
            };
            let piece07 = Piece {
                player, position: Position { raw: 0, col: 7 }, is_king: false, is_alive: true
            };
            let piece10 = Piece {
                player, position: Position { raw: 1, col: 0 }, is_king: false, is_alive: true
            };
            let piece12 = Piece {
                player, position: Position { raw: 1, col: 2 }, is_king: false, is_alive: true
            };
            let piece14 = Piece {
                player, position: Position { raw: 1, col: 4 }, is_king: false, is_alive: true
            };
            let piece16 = Piece {
                player, position: Position { raw: 1, col: 6 }, is_king: false, is_alive: true
            };
            let piece21 = Piece {
                player, position: Position { raw: 2, col: 1 }, is_king: false, is_alive: true
            };
            let piece23 = Piece {
                player, position: Position { raw: 2, col: 3 }, is_king: false, is_alive: true
            };
            let piece25 = Piece {
                player, position: Position { raw: 2, col: 5 }, is_king: false, is_alive: true
            };
            let piece27 = Piece {
                player, position: Position { raw: 2, col: 7 }, is_king: false, is_alive: true
            };

            // Write the new position to the world.
            world.write_model(@piece01);
            world.write_model(@piece03);
            world.write_model(@piece05);
            world.write_model(@piece07);
            world.write_model(@piece10);
            world.write_model(@piece12);
            world.write_model(@piece14);
            world.write_model(@piece16);
            world.write_model(@piece21);
            world.write_model(@piece23);
            world.write_model(@piece25);
            world.write_model(@piece27);
        }
        //

        fn can_choose_piece(ref self: ContractState, coordinates_position: Position) -> bool {
            let mut world = self.world_default();

            // Get the address of the current caller, possibly the player's address.
            let player = get_caller_address();

            // Get the player's piece from the world by its coordinates.
            let piece: Piece = world.read_model((player, coordinates_position));
            println!("piece: {:?}", piece);

            // Check if the piece belongs to the player and is alive.
            let is_valid_piece = piece.position.raw == coordinates_position.raw
                && piece.position.col == coordinates_position.col
                && piece.is_alive == true;

            // Only check for valid moves if the piece is valid
            if is_valid_piece {
                println!("checking valid moves");
                self.check_valid_moves(piece)
            } else {
                false
            }
        }

        // Implementation of the move function for the ContractState struct.
        fn move_piece(ref self: ContractState, coordinates_position: Position) {
            // Get the address of the current caller, possibly the player's address.

            let mut world = self.world_default();

            let player = get_caller_address();

            // Retrieve the player's piece from the world by its coordinates.
            let mut piece: Piece = world.read_model((player, coordinates_position));

            // Update the piece's position based on the new coordinates.
            let updated_piece = update_piece_position(piece, coordinates_position);

            // Write the new position to the world.
            world.write_model(@updated_piece);
            // Emit an event to the world to notify about the player's move.
            world.emit_event(@Moved { player, position: coordinates_position });
        }
    }
    #[generate_trait]
    impl InternalImpl of InternalTrait {
        // Need a function since byte array can't be const.
        // We could have a self.world with an other function to init from hash, that can be
        // constant.
        fn world_default(self: @ContractState) -> dojo::world::WorldStorage {
            self.world(@"dojo_starter")
        }

        // Add world parameter to access game state
        fn check_valid_moves(self: @ContractState, piece: Piece) -> bool {
            let world = self.world_default();

            let piece_raw = piece.position.raw;
            let piece_col = piece.position.col;

            // Only handling non-king pieces for now
            if !piece.is_king {
                // Player 1 can only move down (increasing raw)
                // Make sure we're not at the bottom edge of the board
                if piece_raw >= 7 {
                    return false;
                }

                // Check forward-left diagonal (down-left)
                if piece_col > 0 {
                    let target_down_left_position = Position {
                        raw: piece_raw + 1, col: piece_col - 1
                    };

                    // Try to read a piece at the target position
                    // then the square is empty and the move is valid
                    let target_down_left_square: Piece = world
                        .read_model((piece.player, target_down_left_position));
                    println!("target_square: {:?}", target_down_left_square);
                    // If the target square is empty, return true
                    if target_down_left_square.is_alive == false {
                        let target_down_right_position = Position {
                            raw: piece_raw + 1, col: piece_col + 1
                        };
                        let target_down_right_square: Piece = world
                            .read_model((piece.player, target_down_right_position));
                        if target_down_right_square.is_alive == false {
                            return true;
                        }
                    }
                }
            }

            // If it's a king piece (not implemented yet)
            false
        }
    }
}
// Todo: Improve this function to check if the new position is valid.
fn update_piece_position(mut piece: Piece, coordinates_position: Position) -> Piece {
    piece.position.raw = coordinates_position.raw;
    piece.position.col = coordinates_position.col;
    piece.is_alive = true;
    return piece;
}
