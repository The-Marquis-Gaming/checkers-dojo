use starknet::ContractAddress;

#[derive(Copy, Drop, Serde, Debug)]
#[dojo::model]
pub struct Piece {
    #[key]
    pub session_id: u64,
    #[key]
    pub row: u8,
    #[key]
    pub col: u8,
    pub player: ContractAddress,
    pub position: Position,
    pub is_king: bool,
    pub is_alive: bool,
}

#[derive(Copy, Drop, Serde, Debug)]
#[dojo::model]
pub struct Session {
    #[key]
    pub session_id: u64,
    pub player_1: ContractAddress,
    pub player_2: ContractAddress,
    pub turn: u8, // 0 for Up (Player 1) and 1 for Down (Player 2)
    pub winner: ContractAddress,
    pub state: u8, // 0 for open, 1 for ongoing, 2 for finished
}

#[derive(Copy, Drop, Serde, Debug)]
#[dojo::model]
pub struct Player {
    #[key]
    pub player: ContractAddress,
    pub remaining_pieces: u8,
}

// Future model to handle lobbies dynamically
#[derive(Copy, Drop, Serde, Debug)]
#[dojo::model]
pub struct Counter {
    #[key]
    pub global_key: felt252,
    value: u64
}

#[generate_trait]
impl CounterImpl of CounterTrait {
    fn get_value(self: Counter) -> u64 {
        self.value
    }

    fn increment(ref self: Counter) -> () {
        self.value += 1;
    }

    fn decrement(ref self: Counter) -> () {
        self.value -= 1;
    }

    fn reset(ref self: Counter) -> () {
        self.value = 0;
    }
}

#[derive(Serde, Copy, Drop, Introspect, PartialEq, Debug)]
pub enum Position {
    None,
    Up,
    Down,
}

impl PositionIntoFelt252 of Into<Position, felt252> {
    fn into(self: Position) -> felt252 {
        match self {
            Position::None => 0,
            Position::Up => 1,
            Position::Down => 2,
        }
    }
}

#[derive(Copy, Drop, Serde, Introspect, Debug)]
pub struct Coordinates {
    pub row: u8,
    pub col: u8
}

#[generate_trait]
impl PositionImpl of PositionTrait {
    fn is_zero(self: Coordinates) -> bool {
        if self.row - self.col == 0 {
            return true;
        }
        false
    }

    fn is_equal(self: Coordinates, b: Coordinates) -> bool {
        self.row == b.row && self.col == b.col
    }
}
// #[cfg(test)]
// mod tests {
//     use super::{Vec2, Vec2Trait};

//     #[test]
//     fn test_vec_is_zero() {
//         assert(Vec2Trait::is_zero(Vec2 { x: 0, y: 0 }), 'not zero');
//     }

//     #[test]
//     fn test_vec_is_equal() {
//         let coordinates = Vec2 { x: 420, y: 0 };
//         assert(coordinates.is_equal(Vec2 { x: 420, y: 0 }), 'not equal');
//     }
// }