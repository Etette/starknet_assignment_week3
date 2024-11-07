use crate::PointRedeemer::{IPointRedeemerDispatcher, PointRedeemerEvents, PointsAdded, PointsRedeemed};
use starknet::ContractAddress;
use starknet::testing::{declare, load, selector, start_cheat_caller_address, stop_cheat_caller_address, spy_events};

// Deploying the `PointRedeemer` contract
fn deploy_point_redeemer() -> (IPointRedeemerDispatcher, ContractAddress) {
    let contract = declare("PointRedeemer").unwrap().contract_class();
    let (contract_address, _) = contract.deploy(array![]).unwrap();
    let dispatcher = IPointRedeemerDispatcher { contract_address };
    (dispatcher, contract_address)
}

// Verify initial balance is zero for a new user
#[test]
fn test_initial_balance_is_zero() {
    let (point_redeemer, point_redeemer_address) = deploy_point_redeemer();
    let user: ContractAddress = contract_address_const::<'user'>();
    let initial_balance = load(point_redeemer_address, selector!("user"), user.into());
    assert_eq!(initial_balance, array![felt252::from(0)]);
}

// Test `add_points` functionality and verify PointsAdded event
#[test]
fn test_add_points() {
    let (point_redeemer, point_redeemer_address) = deploy_point_redeemer();
    let user: ContractAddress = contract_address_const::<'user'>();
    
    // Adding points
    point_redeemer.add_points(user, 150);
    let updated_balance = point_redeemer.get_points(user);
    assert_eq!(updated_balance, 150);

    // Capture and verify PointsAdded event
    let mut spy = spy_events();
    let expected_event = PointRedeemerEvents::PointsAdded(PointsAdded { user, points: 150 });
    spy.assert_emitted(@array![(point_redeemer_address, expected_event)]);
}

// Test `redeem_points` functionality and verify PointsRedeemed event
#[test]
fn test_redeem_points() {
    let (point_redeemer, point_redeemer_address) = deploy_point_redeemer();
    let user: ContractAddress = contract_address_const::<'user'>();
    
    // Add points first to have enough for redemption
    point_redeemer.add_points(user, 100);

    // Mock caller as the user
    start_cheat_caller_address(point_redeemer_address, user);
    point_redeemer.redeem_points(user, 40);
    stop_cheat_caller_address(point_redeemer_address);

    let updated_balance = point_redeemer.get_points(user);
    assert_eq!(updated_balance, 60);

    // Capture and verify PointsRedeemed event
    let mut spy = spy_events();
    let expected_event = PointRedeemerEvents::PointsRedeemed(PointsRedeemed { user, points: 40 });
    spy.assert_emitted(@array![(point_redeemer_address, expected_event)]);
}

// Test redeeming points with insufficient balance
#[test]
fn test_redeem_points_insufficient_balance() {
    let (point_redeemer, point_redeemer_address) = deploy_point_redeemer();
    let user: ContractAddress = contract_address_const::<'user'>();
    point_redeemer.add_points(user, 30);

    // Mock caller as the user with insufficient balance for redemption
    start_cheat_caller_address(point_redeemer_address, user);
    
    // Attempting to redeem more than balance, expecting an error
    let result = point_redeemer.redeem_points(user, 50);
    assert!(result.is_err(), "Expected error due to insufficient points");
    
    stop_cheat_caller_address(point_redeemer_address);
}

// Test adding and redeeming points together for a full workflow
#[test]
fn test_full_reward_cycle() {
    let (point_redeemer, point_redeemer_address) = deploy_point_redeemer();
    let user: ContractAddress = contract_address_const::<'user'>();
    
    // Add points
    point_redeemer.add_points(user, 200);
    assert_eq!(point_redeemer.get_points(user), 200);
    
    // Redeem some points
    start_cheat_caller_address(point_redeemer_address, user);
    point_redeemer.redeem_points(user, 100);
    stop_cheat_caller_address(point_redeemer_address);
    assert_eq!(point_redeemer.get_points(user), 100);

    // Verify both events were emitted
    let mut spy = spy_events();
    let add_event = PointRedeemerEvents::PointsAdded(PointsAdded { user, points: 200 });
    let redeem_event = PointRedeemerEvents::PointsRedeemed(PointsRedeemed { user, points: 100 });
    spy.assert_emitted(@array![
        (point_redeemer_address, add_event),
        (point_redeemer_address, redeem_event)
    ]);
}
