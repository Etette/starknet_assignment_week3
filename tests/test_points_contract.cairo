

use src::PointRedeemer::{PointRedeemer, PointsAdded, PointsRedeemed};
use starknet::ContractAddress;
use starknet::test_utils::{deploy, assert_event_emitted};

// Helper function to deploy the contract and initialize the test user
fn setup() -> (PointRedeemer, ContractAddress) {
    let contract = deploy::<PointRedeemer>();
    let user: ContractAddress = ContractAddress::from_felt(12345);
    (contract, user)
}

// Helper function to assert user points balance
fn assert_user_points(contract: PointRedeemer, user: ContractAddress, expected_points: u32) {
    let user_points = contract.get_points(user);
    assert(user_points == expected_points, 'Unexpected user points balance');
}

// Combined test for adding and redeeming points
#[test]
fn test_add_and_redeem_points() {
    let (contract, user) = setup();

    // Test adding points
    contract.add_points(user, 100);
    assert_user_points(contract, user, 100);

    // Verify PointsAdded event emission
    assert_event_emitted::<PointsAdded>(contract, |event| {
        event.user == user && event.points == 100
    });

    // Test redeeming points
    contract.redeem_points(user, 50);
    assert_user_points(contract, user, 50);

    // Verify PointsRedeemed event emission
    assert_event_emitted::<PointsRedeemed>(contract, |event| {
        event.user == user && event.points == 50
    });
}

// Test handling of insufficient points during redemption
#[test]
fn test_insufficient_points_redeem() {
    let (contract, user) = setup();

    // Add points less than needed for redemption
    contract.add_points(user, 30);

    // Attempt to redeem more points than the user has
    let result = contract.redeem_points(user, 50);

    // Check that an error was returned
    assert(result.is_err(), 'Expected an error due to insufficient points');

    // Ensure the points balance remains unchanged
    assert_user_points(contract, user, 30);
}

// Test the get_points function for initial and updated balances
#[test]
fn test_get_points_initial_and_updated() {
    let (contract, user) = setup();

    // Check initial points balance
    assert_user_points(contract, user, 0);

    // Add points and verify retrieval
    contract.add_points(user, 70);
    assert_user_points(contract, user, 70);
}
