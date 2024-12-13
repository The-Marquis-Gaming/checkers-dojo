#[derive(Copy, Drop, Serde, Introspect, Debug)]
pub struct Coordinates {
    pub row: u8,
    pub col: u8
}