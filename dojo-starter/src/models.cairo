use starknet::ContractAddress;

#[derive(Copy, Drop, Serde, Debug)]
#[dojo::model]
pub struct Piece {
    #[key]
    pub player: ContractAddress,
    #[key]
    pub position: Position,
    pub is_king: bool,
    pub is_alive: bool,
}

#[derive(Copy, Drop, Serde, IntrospectPacked, Debug)]
pub struct Position {
    pub raw: u32,
    pub col: u32
}

#[generate_trait]
impl PositionImpl of PositionTrait {
    fn is_zero(self: Position) -> bool {
        if self.raw - self.col == 0 {
            return true;
        }
        false
    }

    fn is_equal(self: Position, b: Position) -> bool {
        self.raw == b.raw && self.col == b.col
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
//         let position = Vec2 { x: 420, y: 0 };
//         assert(position.is_equal(Vec2 { x: 420, y: 0 }), 'not equal');
//     }
// }


