use super::coordinates::Coordinates;

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