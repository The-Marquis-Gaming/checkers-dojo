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