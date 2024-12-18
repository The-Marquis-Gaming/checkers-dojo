use starknet::ContractAddress;
use super::position::Position;

#[derive(Copy, Drop, Serde)]
#[dojo::event]
pub struct Winner {
    #[key]
    pub session_id: u64,
    #[key]
    pub player: ContractAddress,
    pub position: Position,
}