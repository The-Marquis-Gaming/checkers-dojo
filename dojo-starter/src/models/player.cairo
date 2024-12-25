use starknet::ContractAddress;

#[derive(Copy, Drop, Serde, Debug)]
#[dojo::model]
pub struct Player {
    #[key]
    pub player: ContractAddress,
    pub remaining_pieces: u8,
}

#[generate_trait]
impl PlayerImpl of PlayerTrait {
    fn new(player: ContractAddress, remaining_pieces: u8) -> Player {
        Player { player, remaining_pieces }
    }
}
