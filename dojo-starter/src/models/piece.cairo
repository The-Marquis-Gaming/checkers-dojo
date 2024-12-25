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

#[generate_trait]
impl PieceImpl of PieceTrait {
    fn new(
        session_id: u64,
        row: u8,
        col: u8,
        player: ContractAddress,
        position: Position,
        is_king: bool,
        is_alive: bool,
    ) -> Piece {
        Piece { session_id, row, col, player, position, is_king, is_alive }
    }
}
