#[derive(Copy, Drop, Serde, Introspect, Debug)]
pub struct Coordinates {
    pub row: u8,
    pub col: u8,
}

#[generate_trait]
impl CoordinatesImpl of CoordinatesTrait {
    fn new(row: u8, col: u8) -> Coordinates {
        Coordinates { row, col }
    }
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
