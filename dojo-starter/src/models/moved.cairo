use starknet::ContractAddress;

#[derive(Copy, Drop, Serde)]
#[dojo::event]
pub struct Moved {
    #[key]
    pub session_id: u64,
    #[key]
    pub player: ContractAddress,
    pub row: u8,
    pub col: u8,
}