use dojo_starter::models::{Piece, PieceTrait};
use dojo_starter::models::{Coordinates, CoordinatesTrait};
use dojo_starter::models::Position;
use starknet::ContractAddress;

// define the interface
#[starknet::interface]
trait IActions<T> {
    fn create_lobby(ref self: T) -> u64;
    fn join_lobby(ref self: T, session_id: u64);
    fn can_choose_piece(
        ref self: T, position: Position, coordinates_position: Coordinates, session_id: u64,
    ) -> bool;
    fn move_piece(ref self: T, current_piece: Piece, new_coordinates_position: Coordinates);

    //getter function
    fn get_session_id(self: @T) -> u64;
}

// dojo decorator
#[dojo::contract]
pub mod actions {
    use super::IActions;
    use starknet::{ContractAddress, get_caller_address};
    use dojo_starter::models::{Piece, PieceTrait};
    use dojo_starter::models::{Coordinates, CoordinatesTrait};
    use dojo_starter::models::Position;
    use dojo_starter::models::{Session, SessionTrait};
    use dojo_starter::models::{Player, PlayerTrait};
    use dojo_starter::models::{Counter, CounterTrait};

    use dojo::model::{modelStorage, modelValueStorage};
    use dojo::event::EventStorage;

    #[derive(Copy, Drop, Serde)]
    #[dojo::event]
    pub struct Moved {
        #[key]
        pub session_id: u64,
        #[key]
        pub player: ContractAddress,
        pub row: u8,
        pub col: u8,
    }

    #[derive(Copy, Drop, Serde)]
    #[dojo::event]
    pub struct Killed {
        #[key]
        pub session_id: u64,
        #[key]
        pub player: ContractAddress,
        pub row: u8,
        pub col: u8,
    }

    #[derive(Copy, Drop, Serde)]
    #[dojo::event]
    pub struct Winner {
        #[key]
        pub session_id: u64,
        #[key]
        pub player: ContractAddress,
        pub position: Position,
    }

    #[derive(Copy, Drop, Serde)]
    #[dojo::event]
    pub struct King {
        #[key]
        pub session_id: u64,
        #[key]
        pub player: ContractAddress,
        pub row: u8,
        pub col: u8,
    }

    #[abi(embed_v0)]
    impl ActionsImpl of IActions<ContractState> {
        fn create_lobby(ref self: ContractState) -> u64 {
            let mut world = self.world_default();
            let player = get_caller_address();
            // Get or create counter
            let mut session_counter: Counter = world.read_model(('id',));
            let session_id = session_counter.get_value();
            session_counter.increment();
            // Write the counter back to the world
            world.write_model(@session_counter);

            let session = Session::new(
                session_id,
                player,
                starknet::contract_address_const::<0x0>(),
                0,
                starknet::contract_address_const::<0x0>(),
                0,
            );
            world.write_model(@session);

            // Initialize the pieces for the session
            self.initialize_pieces_session_id(session_id);
            // Spawn the pieces for the player
            self.spawn(player, Position::Up, session_id);

            session_id
        }

        fn join_lobby(ref self: ContractState, session_id: u64) {
            let mut world = self.world_default();
            let player = get_caller_address();
            let mut session: Session = world.read_model((session_id));
            session.player_2 = player;
            session.state = 1;
            world.write_model(@session);
            // Spawn the pieces for the player
            self.spawn(player, Position::Down, session_id);
        }

        fn can_choose_piece(
            ref self: ContractState,
            position: Position,
            coordinates_position: Coordinates,
            session_id: u64,
        ) -> bool {
            let mut world = self.world_default();

            // Get the address of the current caller, possibly the player's address.
            let session: Session = world.read_model((session_id));
            let turn = session.turn;

            // Check if it is the player's turn
            if position == Position::Up && turn == 1 {
                panic!("Not your turn");
            } else if position == Position::Down && turn == 0 {
                panic!("Not your turn");
            }

            // Check is current coordinates is valid
            let is_valid_position = self.check_is_valid_position(coordinates_position);
            if !is_valid_position {
                return false;
            }

            // Get the player's piece from the world by its coordinates.
            let piece: Piece = world.read_model((session_id, coordinates_position));

            // Check if the piece belongs to the position and is alive.
            // TODO: Fow now we only support one player. later we will add support for multiple
            // players.
            let is_valid_piece = piece.position == position && piece.is_alive == true;

            // Only check for valid moves if the piece is valid
            if is_valid_piece {
                self.check_has_valid_moves(piece)
            } else {
                false
            }
        }

        // Implementation of the move function for the ContractState struct.
        fn move_piece(
            ref self: ContractState, current_piece: Piece, new_coordinates_position: Coordinates,
        ) {
            // Get the address of the current caller, possibly the player's address.
            let mut world = self.world_default();
            // let player_address = get_caller_address();

            // Check is new coordinates is valid
            let is_valid_position = self.check_is_valid_position(new_coordinates_position);
            assert(is_valid_position, 'Invalid coordinates');

            let row = new_coordinates_position.row;
            let col = new_coordinates_position.col;
            let session_id = current_piece.session_id;

            // Get the piece from the world by its coordinates.
            let square: Piece = world.read_model((session_id, row, col));

            // Update the piece's coordinates based on the new coordinates.
            self.update_piece_position(current_piece, square);

            // Get updated position & target square
            let updated_pieces_keys: Array<(u64, u8, u8)> = array![
                (session_id, current_piece.row, current_piece.col),
                (session_id, square.row, square.col),
            ];
            let updated_pieces: Array<Piece> = world.read_models(updated_pieces_keys.span());

            // Conditions to check for new jump:
            // - Move caused a piece to be eaten (jump done)
            // - Move did not cause a promotion to king
            let is_piece_eaten = *updated_pieces[1].is_alive == false;
            let can_jump_again = if (is_piece_eaten) {
                // Get jump landing position
                let land_position = self.calculate_jump_position(current_piece, square);
                let land_piece: Piece = world.read_model((session_id, land_position));

                // Check for jumps if status didn't change
                if current_piece.is_king == land_piece.is_king {
                    self.is_consecutive_jump_possible(land_piece)
                } else {
                    false
                }
            } else {
                false
            };

            // Update the session's turn if no further action is possible
            if (!can_jump_again) {
                let mut session: Session = world.read_model((session_id));
                session.turn = (session.turn + 1) % 2;
                world.write_model(@session);
            }
        }

        //Getter function
        fn get_session_id(self: @ContractState) -> u64 {
            let world = self.world_default();
            let session_counter: Counter = world.read_model(('id',));

            session_counter.get_value() - 1
        }
    }

    #[generate_trait]
    impl InternalImpl of InternalTrait {
        // Need a function since byte array can't be const.
        // We could have a self.world with an other function to init from hash, that can be
        // constant.
        fn world_default(self: @ContractState) -> dojo::world::WorldStorage {
            self.world(@"checkers_marq")
        }
        fn spawn(
            ref self: ContractState, player: ContractAddress, position: Position, session_id: u64,
        ) {
            let mut world = self.world_default();
            if position == Position::Up {
                self.initialize_player_pieces(player, 0, 2, Position::Up, session_id);
            } else if position == Position::Down {
                self.initialize_player_pieces(player, 5, 7, Position::Down, session_id);
            }
            // Assign remaining pieces to player
            let player_model = Player::new(player, 12);
            world.write_model(@player_model);
        }

        fn check_diagonal_path(
            self: @ContractState,
            start_row: u8,
            start_col: u8,
            row_step: u8,
            col_step: u8,
            session_id: u64,
        ) -> bool {
            let mut row = start_row;
            let mut col = start_col;
            let world = self.world_default();
            let mut good_move = false;

            loop {
                row += row_step;
                col += col_step;

                let valid = self.check_is_valid_position(Coordinates::new(row, col));

                if valid {
                    let target_square: Piece = world.read_model((session_id, row, col));

                    if target_square.is_alive {
                        break;
                    }
                    good_move = true;
                };
                break;
            };
            good_move
        }

        fn initialize_player_pieces(
            ref self: ContractState,
            player: ContractAddress,
            start_row: u8,
            end_row: u8,
            position: Position,
            session_id: u64,
        ) {
            let mut world = self.world_default();
            let mut row = start_row;
            let mut pieces: Array<@Piece> = array![];
            while row <= end_row {
                let start_col = (row + 1) % 2; // Alternates between 0 and 1
                let mut col = start_col;
                while col < 8 {
                    let piece = Piece::new(session_id, player, row, col, position, false, true);
                    pieces.append(@piece);
                    col += 2;
                };
                row += 1;
            };
            world.write_models(pieces.span());
        }

        fn initialize_pieces_session_id(ref self: ContractState, session_id: u64) {
            let mut world = self.world_default();
            let mut row = 0;
            let mut pieces: Array<@Piece> = array![];
            while row < 8 {
                let start_col = (row + 1) % 2; // Alternates between 0 and 1
                let mut col = start_col;
                let player = starknet::contract_address_const::<0x0>();
                while col < 8 {
                    let piece = Piece::new(
                        session_id, player, row, col, Position::None, false, false,
                    );
                    pieces.append(@piece);
                    col += 2;
                };
                row += 1;
            };
            world.write_models(pieces.span());
        }

        fn change_is_alive(
            self: @ContractState, mut current_piece: Piece, new_coordinates_position: Coordinates,
        ) {
            let mut world = self.world_default();
            let session_id = current_piece.session_id;
            let mut square: Piece = world.read_model((session_id, new_coordinates_position));
            let was_king = current_piece.is_king;

            // Check if the piece can be promoted to a king
            if current_piece.position == Position::Up && new_coordinates_position.row == 7 {
                current_piece.is_king = true;
            } else if current_piece.position == Position::Down
                && new_coordinates_position.row == 0 {
                current_piece.is_king = true;
            }

            // Update the piece attributes based on the new coordinates.
            square.is_alive = true;
            square.player = current_piece.player;
            square.position = current_piece.position;
            square.is_king = current_piece.is_king;

            // Update the current piece attributes.
            current_piece.is_alive = false;
            current_piece.player = starknet::contract_address_const::<0x0>();
            current_piece.position = Position::None;
            current_piece.is_king = false;

            // Write the new coordinates to the world.
            let pieces: Array<@Piece> = array![@square, @current_piece];
            world.write_models(pieces.span());

            // Emit an event about the move
            let row = new_coordinates_position.row;
            let col = new_coordinates_position.col;
            world.emit_event(@Moved { session_id, player: square.player, row, col });

            if square.is_king && !was_king {
                world.emit_event(@King { session_id, player: square.player, row, col });
            }
        }

        fn check_has_valid_moves(self: @ContractState, piece: Piece) -> bool {
            let world = self.world_default();
            let piece_row = piece.row;
            let piece_col = piece.col;
            let session_id = piece.session_id;
            // Only handling non-king pieces for now
            if piece.is_king == true {
                // For kings, check all four directions using only unsigned integers
                // Moving up (subtract) is only possible if we're not at row 0
                let can_move_up = piece_row > 0;
                let can_move_left = piece_col > 0;

                let mut has_valid_move = false;

                // Down-right (both increment)
                if piece_row != 7 {
                    has_valid_move = has_valid_move
                        || self.check_diagonal_path(piece_row, piece_col, 1, 1, session_id);
                }

                // Down-left (row increment, col decrement but only if col > 0)
                if can_move_left {
                    has_valid_move = has_valid_move
                        || self.check_diagonal_path(piece_row, piece_col, 1, 0, session_id);
                }

                // Up-right (row decrement but only if row > 0, col increment)
                if can_move_up {
                    has_valid_move = has_valid_move
                        || self.check_diagonal_path(piece_row - 1, piece_col, 0, 1, session_id);
                }

                // Up-left (both decrement but only if both > 0)
                if can_move_up && can_move_left {
                    has_valid_move = has_valid_move
                        || self.check_diagonal_path(piece_row - 1, piece_col - 1, 0, 0, session_id);
                }

                return has_valid_move;
            }

            match piece.position {
                Position::Up => {
                    // Check forward moves (down direction)
                    if piece_row + 1 >= 8 {
                        return false;
                    }

                    // Check down-left diagonal
                    if piece_col > 0 {
                        let target_down_left = Coordinates::new(piece_row + 1, piece_col - 1);
                        let target_square: Piece = world.read_model((session_id, target_down_left));
                        return !target_square.is_alive;
                    }

                    // Check down-right diagonal
                    if piece_col + 1 < 8 {
                        let target_down_right = Coordinates::new(piece_row + 1, piece_col + 1);
                        let target_square: Piece = world
                            .read_model((session_id, target_down_right));
                        return !target_square.is_alive;
                    }
                    false
                },
                Position::Down => {
                    // Check forward moves (up direction)
                    if piece_row == 0 {
                        return false;
                    }

                    // Check up-left diagonal
                    if piece_col > 0 {
                        let target_up_left = Coordinates::new(piece_row - 1, piece_col - 1);
                        let target_square: Piece = world.read_model((session_id, target_up_left));
                        return !target_square.is_alive;
                    }

                    // Check up-right diagonal
                    if piece_col + 1 < 8 {
                        let target_up_right = Coordinates::new(piece_row - 1, piece_col + 1);
                        let target_square: Piece = world.read_model((session_id, target_up_right));
                        return !target_square.is_alive;
                    }
                    false
                },
                _ => false,
            }
        }

        fn is_jump_possible(self: @ContractState, piece: Piece, square: Piece) -> bool {
            let world = self.world_default();
            let session_id = piece.session_id;
            // Cannot jump over square if piece in square is not alive
            if !square.is_alive {
                return false;
            }

            let land_pos = self.calculate_jump_position(piece, square);
            let land_piece: Piece = world.read_model((session_id, land_pos));

            !land_piece.is_alive
        }

        fn is_consecutive_jump_possible(self: @ContractState, piece: Piece) -> bool {
            let world = self.world_default();
            let session_id = piece.session_id;

            // Contruct possible jump keys for bulk read
            let mut possible_jumps_up_keys: Array<(u64, Coordinates)> = array![];
            let mut possible_jumps_down_keys: Array<(u64, Coordinates)> = array![];

            // Ensure we don't check outbound squares
            if piece.row > 0 && piece.col < 7 {
                possible_jumps_up_keys
                    .append((session_id, Coordinates::new(piece.row - 1, piece.col + 1))); // UR
            }
            if piece.row > 0 && piece.col > 0 {
                possible_jumps_up_keys
                    .append((session_id, Coordinates::new(piece.row - 1, piece.col - 1))); // UL
            }
            if piece.row < 7 && piece.col < 7 {
                possible_jumps_down_keys
                    .append((session_id, Coordinates::new(piece.row + 1, piece.col + 1))); // DR
            }
            if piece.row < 7 && piece.col > 0 {
                possible_jumps_down_keys
                    .append((session_id, Coordinates::new(piece.row + 1, piece.col - 1))); // DL
            }

            let possible_jumps_up: Array<Piece> = world.read_models(possible_jumps_up_keys.span());
            let possible_jumps_down: Array<Piece> = world
                .read_models(possible_jumps_down_keys.span());

            // Check for valid jumps for corresponding direction
            // King can jump in both directions
            let mut can_jump_again = false;
            if (piece.position == Position::Down || piece.is_king) {
                for jump_up in possible_jumps_up {
                    // Check for possible jump. Pieces must be in diferent teams
                    if (self.is_jump_possible(piece, jump_up)
                        && piece.position != jump_up.position) {
                        can_jump_again = true;
                    }
                };
            }

            if (piece.position == Position::Up || piece.is_king) {
                for jump_down in possible_jumps_down {
                    // Check for possible jump. Pieces must be in diferent teams
                    if (self.is_jump_possible(piece, jump_down)
                        && piece.position != jump_down.position) {
                        can_jump_again = true;
                    }
                };
            }

            can_jump_again
        }

        /// Calculate jump position for given start position and eaten piece position.
        /// Takes into account all types of pieces (man/king) and all positions.
        fn calculate_jump_position(
            self: @ContractState, original: Piece, eaten: Piece,
        ) -> Coordinates {
            // Use signed integers to handle negative values when calculating landing position
            let signed_original_row: i8 = original.row.try_into().unwrap();
            let signed_original_col: i8 = original.col.try_into().unwrap();
            let signed_eaten_row: i8 = eaten.row.try_into().unwrap();
            let signed_eaten_col: i8 = eaten.col.try_into().unwrap();

            let land_row: i8 = signed_original_row + 2 * (signed_eaten_row - signed_original_row);
            let land_col: i8 = signed_original_col + 2 * (signed_eaten_col - signed_original_col);

            assert!(land_row >= 0, "row less than 0");
            assert!(land_col >= 0, "col less than 0");
            Coordinates::new(land_row.try_into().unwrap(), land_col.try_into().unwrap())
        }

        fn update_alive_position(ref self: ContractState, mut piece: Piece, mut square: Piece) {
            let can_jump = self.is_jump_possible(piece, square);
            if can_jump {
                // Kill the piece
                let mut world = self.world_default();
                let killed_player = square.player;
                let session_id = piece.session_id;
                square.is_alive = false;
                square.player = starknet::contract_address_const::<0x0>();
                square.position = Position::None;

                world.write_model(@square);

                let player = piece.player;
                world.emit_event(@Killed { session_id, player, row: square.row, col: square.col });

                // Update the enemy player remaining pieces
                let mut killed_player_world: Player = world.read_model((killed_player));
                killed_player_world.remaining_pieces -= 1;
                world.write_model(@killed_player_world);

                // Check if the player won the game
                if killed_player_world.remaining_pieces == 0 {
                    let mut session: Session = world.read_model((session_id));
                    session.winner = piece.player;
                    session.state = 2;
                    world.write_model(@session);
                    let position = piece.position;
                    world.emit_event(@Winner { session_id, player: piece.player, position });
                }

                // Make the jump
                let land_pos = self.calculate_jump_position(piece, square);
                self.change_is_alive(piece, land_pos);
            }
        }

        // Todo: Improve this function to check if the new coordinates is valid.
        fn update_piece_position(ref self: ContractState, mut piece: Piece, square: Piece) {
            // Check if there is a piece in the square
            if square.is_alive && piece.position != square.position {
                self.update_alive_position(piece, square);
            } else {
                // Get the coordinates of the square and do the swap
                let coordinates = Coordinates::new(square.row, square.col);
                self.change_is_alive(piece, coordinates);
            }
        }

        fn check_is_valid_position(self: @ContractState, coordinates: Coordinates) -> bool {
            let row = coordinates.row;
            let col = coordinates.col;
            // Check if the coordinates is out of bounds
            if row < 8 && col < 8 {
                // Check if the coordinates is valid on the board setup
                match row {
                    0 => col == 1 || col == 3 || col == 5 || col == 7,
                    1 => col == 0 || col == 2 || col == 4 || col == 6,
                    2 => col == 1 || col == 3 || col == 5 || col == 7,
                    3 => col == 0 || col == 2 || col == 4 || col == 6,
                    4 => col == 1 || col == 3 || col == 5 || col == 7,
                    5 => col == 0 || col == 2 || col == 4 || col == 6,
                    6 => col == 1 || col == 3 || col == 5 || col == 7,
                    7 => col == 0 || col == 2 || col == 4 || col == 6,
                    _ => false,
                }
            } else {
                false
            }
        }
    }
}

