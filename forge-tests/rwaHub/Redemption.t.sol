// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "forge-tests/BaseTestRunner.sol";

abstract contract Test_RWAHub_Redemptions is BaseTestRunner {
  function _initializeUsersArray() internal virtual;

  /*//////////////////////////////////////////////////////////////
                        Request Redemption
  //////////////////////////////////////////////////////////////*/

  function test_rwaHub_requestRedeem_fail_when_paused() public pauseState {
    _mintRWAToUser(alice, 101e18);
    vm.startPrank(alice);
    rwa.approve(address(rwaHub), 101e18);
    vm.expectRevert(IRWAHub.FeaturePaused.selector);
    rwaHub.requestRedemption(101e18);
  }

  function test_rwaHub_requestRedeem() public {
    rwaHubRequestRedemption(alice, 1000e18);
    // Assert that all of alice's RWA tokens has been burned
    assertEq(rwa.balanceOf(alice), 0);

    (address user_, uint256 amt, uint256 priceId) = rwaHub
      .redemptionIdToRedeemer(FIRST_REDEMPTION_ID);

    // Assert that the alice is correct
    assertEq(user_, alice);
    // Assert that the amount is correct
    assertEq(amt, 1000e18);
    // Assert that the priceId is uninitialized
    assertEq(priceId, 0);

    // Assert that the redemptionId has been incremented
    assertEq(rwaHub.redemptionRequestCounter(), 2);
  }

  function test_fuzz_rwaHub_requestRedeem(uint256 amount) public {
    vm.assume(amount > 100e18);
    vm.assume(amount < 5_000e18);
    rwaHubRequestRedemption(alice, amount);

    // Assert that all of the user's RWA tokens have been burned
    assertEq(rwa.balanceOf(alice), 0);

    (address user_, uint256 amt, uint256 priceId) = rwaHub
      .redemptionIdToRedeemer(FIRST_REDEMPTION_ID);

    // Assert that the alice is correct
    assertEq(user_, alice);
    // Assert that the amount is correct
    assertEq(amt, amount);
    // Assert that the priceId is uninitialized
    assertEq(priceId, 0);

    // Assert that the redemptionId has been incremented
    assertEq(rwaHub.redemptionRequestCounter(), 2);
  }

  function test_redemptionId_increasing() public {
    _initializeUsersArray();

    for (uint256 i = 0; i < 300; ++i) {
      _mintRWAToUser(address(users[i]), 2_000e18);

      vm.startPrank(address(users[i]));
      rwa.approve(address(rwaHub), 2_000e18);
      rwaHub.requestRedemption(2_000e18);
      vm.stopPrank();

      (address alice, uint256 amt, uint256 priceId) = rwaHub
        .redemptionIdToRedeemer(bytes32(uint256(i + 1)));

      assertEq(rwaHub.redemptionRequestCounter(), i + 2);
      // Assert that the alice is correct
      assertEq(alice, address(users[i]));
      // Assert that the amt is correct
      assertEq(amt, 2_000e18);
      // Assert that the priceId is uninitialized
      assertEq(priceId, 0);
    }
  }

  /*//////////////////////////////////////////////////////////////
                    Request Redemption and Claim
  //////////////////////////////////////////////////////////////*/

  function test_rwaHub_claimRedemption_fail_paused()
    public
    postRequestState(1000e18)
    pauseState
  {
    vm.expectRevert(IRWAHub.FeaturePaused.selector);
    vm.prank(alice);
    rwaHub.claimRedemption(redemptionIds);
  }

  function test_rwaHub_setPriceIdForRedemptions_fail_repeat()
    public
    postRequestState(1000e18)
  {
    redemptionIds.push(FIRST_REDEMPTION_ID);
    priceIds.push(1);
    vm.startPrank(managerAdmin);
    rwaHub.setPriceIdForRedemptions(redemptionIds, priceIds);
    vm.expectRevert(IRWAHub.PriceIdAlreadySet.selector);
    rwaHub.setPriceIdForRedemptions(redemptionIds, priceIds);
    vm.stopPrank();
  }

  function test_rwaHub_claimRedemption()
    public
    postRequestState(1000e18)
    preRedeemProcessState(100_000e6)
  {
    vm.prank(managerAdmin);
    redemptionIds.push(FIRST_REDEMPTION_ID);
    priceIds.push(1);
    rwaHub.setPriceIdForRedemptions(redemptionIds, priceIds);
    delete redemptionIds;
    delete priceIds;

    redemptionIds.push(FIRST_REDEMPTION_ID);

    vm.prank(alice);
    rwaHub.claimRedemption(redemptionIds);

    // Assert that the alice receives USDC
    assertEq(USDC.balanceOf(alice), 1000e6 * (pricer.getLatestPrice() / 1e18));

    (address user_, uint256 amt, uint256 priceId) = rwaHub
      .redemptionIdToRedeemer(FIRST_REDEMPTION_ID);

    // Assert that the entry has been removed
    assertEq(user_, address(0));
    assertEq(amt, 0);
    assertEq(priceId, 0);
  }

  function test_fuzz_rwaHub_claimRedemption(uint128 amount) public {
    vm.assume(amount > 100e18);
    vm.assume(amount < 2_000e18);

    rwaHubRequestRedemption(alice, amount);
    uint256 amt = uint256(amount);
    vm.prank(managerAdmin);

    redemptionIds.push(FIRST_REDEMPTION_ID);
    priceIds.push(1);
    rwaHub.setPriceIdForRedemptions(redemptionIds, priceIds);
    delete redemptionIds;
    delete priceIds;
    redemptionIds.push(FIRST_REDEMPTION_ID);

    grantApprovalToHub((amt * pricer.getLatestPrice()) / 1e30);
    vm.prank(alice);
    rwaHub.claimRedemption(redemptionIds);

    // Assert that the alice receives USDC
    assertEq(
      USDC.balanceOf(alice),
      ((amt * 1e18) * pricer.getLatestPrice()) / ((1e36 / 1e6) * 1e18)
    );

    (address user_, uint256 amt_, uint256 priceId) = rwaHub
      .redemptionIdToRedeemer(FIRST_REDEMPTION_ID);

    // Assert that the entry has been removed
    assertEq(user_, address(0));
    assertEq(amt_, 0);
    assertEq(priceId, 0);
  }

  function test_fuzz_rwaHub_claimRedemption_t(
    uint128 amount,
    uint128 price
  ) public {
    vm.assume(amount > 100e18);
    vm.assume(amount < 20_000e18);
    vm.assume(price > 0);
    vm.assume(price < 100e18);

    rwaHubRequestRedemption(alice, amount);

    uint256 amt = uint256(amount);
    uint256 rate = uint256(price) + 100e18;

    pricer.addPrice(rate, block.timestamp + 1000);

    vm.prank(managerAdmin);
    redemptionIds.push(FIRST_REDEMPTION_ID);
    priceIds.push(2);
    rwaHub.setPriceIdForRedemptions(redemptionIds, priceIds);
    delete redemptionIds;
    delete priceIds;

    redemptionIds.push(FIRST_REDEMPTION_ID);

    grantApprovalToHub((amount * rate) / 1e30);
    vm.prank(alice);
    rwaHub.claimRedemption(redemptionIds);

    // Assert that the alice receives USDC
    console.log(USDC.balanceOf(alice));
    assertEq(USDC.balanceOf(alice), (amt * rate) / (1e36 / 1e6));

    (address user_, uint256 amt_, uint256 priceId) = rwaHub
      .redemptionIdToRedeemer(FIRST_REDEMPTION_ID);

    // Assert that the entry has been removed
    assertEq(user_, address(0));
    assertEq(amt_, 0);
    assertEq(priceId, 0);
  }

  /*//////////////////////////////////////////////////////////////
                              Utils
  //////////////////////////////////////////////////////////////*/
  function rwaHubRequestRedemption(address user, uint256 amount) public {
    _mintRWAToUser(user, amount);
    vm.startPrank(user);
    rwa.approve(address(rwaHub), amount);
    rwaHub.requestRedemption(amount);
    vm.stopPrank();
  }

  function grantApprovalToHub(uint256 collateralAmount) public {
    address sender = address(rwaHub.assetSender());
    deal(address(USDC), sender, collateralAmount);
    uint256 toSend = USDC.balanceOf(address(rwaHub.assetSender()));
    vm.prank(address(rwaHub.assetSender()));
    USDC.approve(address(rwaHub), toSend);
  }

  modifier postRequestState(uint256 amount) {
    rwaHubRequestRedemption(alice, amount);
    _;
  }

  modifier preRedeemProcessState(uint256 redeemAmt) {
    grantApprovalToHub(redeemAmt);
    _;
  }

  modifier pauseState() {
    vm.prank(pauser);
    rwaHub.pauseRedemption();
    _;
  }
}
