use starknet::ContractAddress;

#[starknet::interface]
pub trait IPointRedeemer<TContractState> {
    fn add_points(ref self: TContractState, user: ContractAddress, points: u32);
    fn redeem_points(ref self: TContractState, user: ContractAddress, points: u32);
    fn get_points(self: @TContractState, user: ContractAddress) -> u32;
}

#[starknet::contract]
pub mod PointRedeemer {
    // use super::IPointRedeemer;
    use super::IPointRedeemer;
use starknet::storage::{ Map,
                            StoragePointerReadAccess,
                            StoragePointerWriteAccess,
                            // StorageMapReadAccess,
                            // StorageMapWriteAccess,
                            StoragePathEntry,
    };
   
    use core::starknet::ContractAddress;
    // use super::IPointRedeemer<ContractState>;

    #[storage]
    struct Storage {
        user: Map::<ContractAddress, u32>,
    }
    
    #[event]
    #[derive(Copy, Drop,starknet::Event)]
    pub enum Event {
        PointsAdded: PointsAdded, 
        PointsRedeemed: PointsRedeemed,
    }
    #[derive(Copy, Drop, starknet::Event)]
    pub struct PointsAdded {
        pub user: ContractAddress,
        pub points: u32,
    }
    #[derive(Copy, Drop, Debug, PartialEq, starknet::Event)]
    pub struct PointsRedeemed {
        pub user: ContractAddress,
        pub points: u32,
    }

    #[abi(embed_v0)]
    impl PointsRedeemerImpl of super::IPointRedeemer<ContractState>{

        fn add_points(ref self: ContractState, user: ContractAddress, points: u32){
            let current_point = self.get_points(user);
            self.user.entry(user).write(current_point + points);
            self.emit(Event::PointsAdded(PointsAdded {user: user, points: points}));
        }


        fn redeem_points(ref self: ContractState, user: ContractAddress, points: u32) {
            let current_points = self.get_points(user);
            assert(points <= current_points, 'Insufficient points');
            self.user.entry(user).write(current_points - points);
            self.emit(Event::PointsRedeemed(PointsRedeemed { user: user, points: points }));        
        }

        fn get_points(self: @ContractState, user: ContractAddress) -> u32 {
            return self.user.entry(user).read();
        }
    }

}
    
    

