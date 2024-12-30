use starknet::ContractAddress;

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

#[generate_trait]
impl SessionImpl of SessionTrait {
    fn new(
        session_id: u64,
        player_1: ContractAddress,
        player_2: ContractAddress,
        turn: u8,
        winner: ContractAddress,
        state: u8,
    ) -> Session {
        Session { session_id, player_1, player_2, turn, winner, state }
    }
}
