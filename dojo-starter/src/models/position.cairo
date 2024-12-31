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
