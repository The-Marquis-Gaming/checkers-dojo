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