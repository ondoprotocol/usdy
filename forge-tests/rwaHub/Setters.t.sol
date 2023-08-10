// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "forge-tests/BaseTestRunner.sol";
import "forge-tests/helpers/events/RWAHubEvents.sol";

abstract contract Test_RWAHub_Setters is BaseTestRunner, RWAHubEvents {
  function _restrictUser(address user) internal virtual;

  function _expectOpinionatedRestrictionRevert() internal virtual;

  function depositToHub() public {
    _seedWithCollateral(alice, 20_000e6);

    vm.startPrank(alice);
    USDC.approve(address(rwaHub), 20_000e6);
    rwaHub.requestSubscription(20_000e6);
    vm.stopPrank();
  }

  function _redeemToHub() internal {
    vm.prank(guardian);
    rwa.mint(alice, 100e18);

    vm.startPrank(alice);
    rwa.approve(address(rwaHub), 100e18);
    rwaHub.requestRedemption(100e18);
    vm.stopPrank();
  }

  /*//////////////////////////////////////////////////////////////
                      Setting Price Id Tests
  //////////////////////////////////////////////////////////////*/

  function test_setPriceIdForDeposits_fail_AC() public {
    depositIds.push(FIRST_DEPOSIT_ID);
    priceIds.push(1);
    vm.expectRevert(_formatACRevert(badActor, rwaHub.PRICE_ID_SETTER_ROLE()));
    vm.prank(badActor);
    rwaHub.setPriceIdForDeposits(depositIds, priceIds);
  }

  function test_setPriceIdForDeposits_fail_mismatchLength() public {
    depositIds.push(FIRST_DEPOSIT_ID);
    priceIds.push(1);
    priceIds.push(2);
    vm.expectRevert(IRWAHub.ArraySizeMismatch.selector);
    vm.prank(managerAdmin);
    rwaHub.setPriceIdForDeposits(depositIds, priceIds);
  }

  function test_setPriceIdForRedemptions_fail_AC() public {
    redemptionIds.push(FIRST_REDEMPTION_ID);
    priceIds.push(1);
    vm.expectRevert(_formatACRevert(badActor, rwaHub.PRICE_ID_SETTER_ROLE()));
    vm.prank(badActor);
    rwaHub.setPriceIdForRedemptions(redemptionIds, priceIds);
  }

  function test_setPriceIdForRedemptions_fail_mismatchLength() public {
    redemptionIds.push(FIRST_REDEMPTION_ID);
    priceIds.push(1);
    priceIds.push(2);
    vm.expectRevert(IRWAHub.ArraySizeMismatch.selector);
    vm.prank(managerAdmin);
    rwaHub.setPriceIdForRedemptions(redemptionIds, priceIds);
  }

  /*//////////////////////////////////////////////////////////////
                    Unauthorized Manager Admin Role
  //////////////////////////////////////////////////////////////*/

  function test_overWriteDepositor_fail_AC() public {
    vm.expectRevert(_formatACRevert(badActor, rwaHub.MANAGER_ADMIN()));
    vm.startPrank(badActor);
    rwaHub.overwriteDepositor(FIRST_DEPOSIT_ID, badActor, 1_000_000e6, 1);
  }

  function test_overwriteRedeemer_fail_AC() public {
    vm.expectRevert(_formatACRevert(badActor, rwaHub.MANAGER_ADMIN()));
    vm.startPrank(badActor);
    rwaHub.overwriteRedeemer(FIRST_REDEMPTION_ID, badActor, 1_000_000e18, 1);
  }

  function test_setMinimumRedemptionAmount_fail_AC() public {
    vm.expectRevert(_formatACRevert(badActor, rwaHub.MANAGER_ADMIN()));
    vm.startPrank(badActor);
    rwaHub.setMinimumRedemptionAmount(1e18);
  }

  function test_setMinimumDepositAmount_fail_AC() public {
    vm.expectRevert(_formatACRevert(badActor, rwaHub.MANAGER_ADMIN()));
    vm.startPrank(badActor);
    rwaHub.setMinimumDepositAmount(1e18);
  }

  function test_setMintFee_fail_AC() public {
    vm.expectRevert(_formatACRevert(badActor, rwaHub.MANAGER_ADMIN()));
    vm.startPrank(badActor);
    rwaHub.setMintFee(10_000);
  }

  function test_setRedemptionFee_fail_AC() public {
    vm.expectRevert(_formatACRevert(badActor, rwaHub.MANAGER_ADMIN()));
    vm.startPrank(badActor);
    rwaHub.setRedemptionFee(10_000);
  }

  function test_setPricer_fail_AC() public {
    vm.expectRevert(_formatACRevert(badActor, rwaHub.MANAGER_ADMIN()));
    vm.startPrank(badActor);
    rwaHub.setPricer(address(badActor));
  }

  function test_setAssetSender_fail_AC() public {
    vm.expectRevert(_formatACRevert(badActor, rwaHub.MANAGER_ADMIN()));
    vm.prank(badActor);
    rwaHub.setAssetSender(address(badActor));
  }

  function test_setFeeRecipient_fail_AC() public {
    vm.expectRevert(_formatACRevert(badActor, rwaHub.MANAGER_ADMIN()));
    vm.prank(badActor);
    rwaHub.setFeeRecipient(address(badActor));
  }

  /*//////////////////////////////////////////////////////////////
                      Pause Utils Unauthorized
  //////////////////////////////////////////////////////////////*/

  function test_pauseSubscription_fail_AC() public {
    vm.expectRevert(_formatACRevert(badActor, rwaHub.PAUSER_ADMIN()));
    vm.startPrank(badActor);
    rwaHub.pauseSubscription();
  }

  function test_pauseRedemption_fail_AC() public {
    vm.expectRevert(_formatACRevert(badActor, rwaHub.PAUSER_ADMIN()));
    vm.startPrank(badActor);
    rwaHub.pauseRedemption();
  }

  function test_unpauseSubscription_fail_AC() public {
    vm.expectRevert(_formatACRevert(badActor, rwaHub.MANAGER_ADMIN()));
    vm.startPrank(badActor);
    rwaHub.unpauseSubscription();
  }

  function test_unpauseRedemption_fail_AC() public {
    vm.expectRevert(_formatACRevert(badActor, rwaHub.MANAGER_ADMIN()));
    vm.startPrank(badActor);
    rwaHub.unpauseRedemption();
  }

  /*//////////////////////////////////////////////////////////////
                      Authorized Setter Role
  //////////////////////////////////////////////////////////////*/

  function test_setPriceIdForDeposit() public {
    depositToHub();
    depositIds.push(FIRST_DEPOSIT_ID);

    priceIds.push(1);
    vm.expectEmit(true, true, true, true);
    emit PriceIdSetForDeposit(FIRST_DEPOSIT_ID, 1);
    vm.prank(managerAdmin);
    rwaHub.setPriceIdForDeposits(depositIds, priceIds);
    (, , uint256 priceId) = rwaHub.depositIdToDepositor(FIRST_DEPOSIT_ID);
    assertEq(priceId, 1);
  }

  function test_setPriceIdForRedemptions() public {
    _redeemToHub();
    redemptionIds.push(FIRST_REDEMPTION_ID);
    priceIds.push(1);
    vm.expectEmit(true, true, true, true);
    emit PriceIdSetForRedemption(FIRST_REDEMPTION_ID, 1);
    vm.prank(managerAdmin);
    rwaHub.setPriceIdForRedemptions(redemptionIds, priceIds);
    (, , uint256 priceId) = rwaHub.redemptionIdToRedeemer(FIRST_REDEMPTION_ID);
    assertEq(priceId, 1);
  }

  /*//////////////////////////////////////////////////////////////
                   Authorized Manager Admin Role
  //////////////////////////////////////////////////////////////*/

  function test_overWriteDepositor_fail_restricted() public {
    _restrictUser(alice);
    vm.prank(managerAdmin);
    _expectOpinionatedRestrictionRevert();
    rwaHub.overwriteDepositor(FIRST_DEPOSIT_ID, alice, 1_000_000e6, 1);
  }

  function test_overWriteDepositor() public {
    vm.prank(managerAdmin);
    rwaHub.overwriteDepositor(FIRST_DEPOSIT_ID, alice, 1_000e6, 1);
    (address user, uint256 amount, uint256 priceId) = rwaHub
      .depositIdToDepositor(FIRST_DEPOSIT_ID);
    // Assert that the deposit was overWritten
    assertEq(user, alice);
    assertEq(amount, 1_000e6);
    assertEq(priceId, 1);
  }

  function test_overwriteRedeemer_fail_restricted() public {
    _restrictUser(alice);
    vm.prank(managerAdmin);
    _expectOpinionatedRestrictionRevert();
    rwaHub.overwriteRedeemer(FIRST_REDEMPTION_ID, alice, 10e18, 1);
  }

  function test_overwriteRedeemer() public {
    vm.prank(managerAdmin);
    rwaHub.overwriteRedeemer(FIRST_REDEMPTION_ID, alice, 10e18, 1);
    (address user, uint256 amount, uint256 priceId) = rwaHub
      .redemptionIdToRedeemer(FIRST_REDEMPTION_ID);
    // Assert that the deposit was overWritten
    assertEq(user, alice);
    assertEq(amount, 10e18);
    assertEq(priceId, 1);
  }

  function test_setMinimumDepositAmount_fail_tooSmall() public {
    vm.prank(managerAdmin);
    vm.expectRevert(IRWAHub.AmountTooSmall.selector);
    rwaHub.setMinimumDepositAmount(9999);
  }

  function test_setMinimumDepositAmount() public {
    vm.expectEmit(true, true, true, true);
    emit MinimumDepositAmountSet(100e6, 1000e6);
    vm.prank(managerAdmin);
    rwaHub.setMinimumDepositAmount(1000e6);
    assertEq(rwaHub.minimumDepositAmount(), 1000e6);
  }

  function test_setMinimumRedemptionAmount_fail_tooSmall() public {
    vm.prank(managerAdmin);
    vm.expectRevert(IRWAHub.AmountTooSmall.selector);
    rwaHub.setMinimumRedemptionAmount(9999);
  }

  function test_setMinimumRedemptionAmount() public {
    vm.expectEmit(true, true, true, true);
    emit MinimumRedemptionAmountSet(100e18, 10e18);
    vm.prank(managerAdmin);
    rwaHub.setMinimumRedemptionAmount(10e18);
    assertEq(rwaHub.minimumRedemptionAmount(), 10e18);
  }

  function test_setMintFee() public {
    vm.expectEmit(true, true, true, true);
    emit MintFeeSet(0, 1);
    vm.prank(managerAdmin);
    rwaHub.setMintFee(1);
    assertEq(rwaHub.mintFee(), 1);
  }

  function test_setRedemptionFee() public {
    vm.expectEmit(true, true, true, true);
    emit RedemptionFeeSet(0, 1);
    vm.prank(managerAdmin);
    rwaHub.setRedemptionFee(1);
    assertEq(rwaHub.redemptionFee(), 1);
  }

  function test_setPricer() public {
    vm.expectEmit(true, true, true, true);
    emit NewPricerSet(address(rwaHub.pricer()), address(1));
    vm.prank(managerAdmin);
    rwaHub.setPricer(address(1));
    assertEq(address(rwaHub.pricer()), address(1));
  }

  function test_setAssetSender() public {
    vm.expectEmit(true, true, true, true);
    emit AssetSenderSet(rwaHub.assetSender(), address(1));
    vm.prank(managerAdmin);
    rwaHub.setAssetSender(address(1));
    assertEq(rwaHub.assetSender(), address(1));
  }

  function test_setFeeRecipient() public {
    vm.expectEmit(true, true, true, true);
    emit FeeRecipientSet(rwaHub.feeRecipient(), address(1));
    vm.prank(managerAdmin);
    rwaHub.setFeeRecipient(address(1));
    assertEq(rwaHub.feeRecipient(), address(1));
  }

  /*//////////////////////////////////////////////////////////////
                      Authorized Pause Utils
  //////////////////////////////////////////////////////////////*/

  function test_pauseSubscription() public {
    vm.startPrank(managerAdmin);
    rwaHub.grantRole(rwaHub.PAUSER_ADMIN(), managerAdmin);
    vm.expectEmit(true, true, true, true);
    emit SubscriptionPaused(managerAdmin);
    rwaHub.pauseSubscription();
    vm.stopPrank();
  }

  function test_unpauseSubscription() public {
    test_pauseSubscription();

    vm.prank(managerAdmin);
    vm.expectEmit(true, true, true, true);
    emit SubscriptionUnpaused(managerAdmin);
    rwaHub.unpauseSubscription();
  }

  function test_pauseRedemption() public {
    vm.startPrank(managerAdmin);
    rwaHub.grantRole(rwaHub.PAUSER_ADMIN(), managerAdmin);
    vm.expectEmit(true, true, true, true);
    emit RedemptionPaused(managerAdmin);
    rwaHub.pauseRedemption();
    vm.stopPrank();
  }

  function test_unpauseRedemption() public {
    test_pauseRedemption();

    vm.prank(managerAdmin);
    vm.expectEmit(true, true, true, true);
    emit RedemptionUnpaused(managerAdmin);
    rwaHub.unpauseRedemption();
  }
}
