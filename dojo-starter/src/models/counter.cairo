// Future model to handle lobbies dynamically
#[derive(Copy, Drop, Serde, Debug)]
#[dojo::model]
pub struct Counter {
    #[key]
    pub global_key: felt252,
    value: u64
}

#[generate_trait]
impl CounterImpl of CounterTrait {
    fn get_value(self: Counter) -> u64 {
        self.value
    }

    fn increment(ref self: Counter) -> () {
        self.value += 1;
    }

    fn decrement(ref self: Counter) -> () {
        self.value -= 1;
    }

    fn reset(ref self: Counter) -> () {
        self.value = 0;
    }
}