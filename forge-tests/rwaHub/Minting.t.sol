// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "forge-tests/BaseTestRunner.sol";
import "forge-tests/helpers/events/RWAHubEvents.sol";

abstract contract Test_RWAHub_Minting is BaseTestRunner, RWAHubEvents {
  bytes32 public constant mockTxHash = bytes32(uint256(0xfeed));

  function _initializeUsersArray() internal virtual;

  function _restrictUser(address user) internal virtual;

  function _expectOpinionatedRestrictionRevert() internal virtual;

  /*//////////////////////////////////////////////////////////////
                         Subscription Tests
  //////////////////////////////////////////////////////////////*/

  function test_rwaHub_requestSubscription_fail_paused() public pausedState {
    _seedWithCollateral(alice, 1_000e6);
    vm.startPrank(alice);
    USDC.approve(address(rwaHub), 1_000e6);
    vm.expectRevert(IRWAHub.FeaturePaused.selector);
    rwaHub.requestSubscription(1_000e6);
    vm.stopPrank();
  }

  function test_rwaHub_requestSubscription_fail_restricted() public {
    _restrictUser(alice);
    _expectOpinionatedRestrictionRevert();
    vm.prank(alice);
    rwaHub.requestSubscription(1_000e6);
  }

  function test_rwaHub_requestSubscription() public {
    _seedWithCollateral(alice, 1_000_000e6);
    vm.startPrank(alice);
    USDC.approve(address(rwaHub), 1_000_000e6);
    vm.expectEmit(true, true, true, true);
    emit MintRequested(alice, FIRST_DEPOSIT_ID, 1_000_000e6, 1_000_000e6, 0);
    rwaHub.requestSubscription(1_000_000e6);
    vm.stopPrank();

    (address user, uint256 amount, uint256 priceId) = rwaHub
      .depositIdToDepositor(FIRST_DEPOSIT_ID);

    // Check user's address is correct
    assertEq(user, alice);
    // Check tha the user deposit amt is correct
    assertEq(amount, 1_000_000e6);
    // Check that the priceId is uninitialized
    assertEq(priceId, 0);
  }

  function test_fuzz_rwaHub_requestSubscription(uint256 amount) public {
    vm.assume(amount < 100_000_000e6);
    vm.assume(amount > rwaHub.minimumDepositAmount());

    _rwaHubDeposit(alice, amount);

    (address user, uint256 amt, uint256 priceId) = rwaHub.depositIdToDepositor(
      FIRST_DEPOSIT_ID
    );

    // Check user's address is correct
    assertEq(user, alice);
    // Check that the user deposited amt is correct
    assertEq(amt, amount);
    // Check that the priceId is uninitialized
    assertEq(priceId, 0);
  }

  function test_rwaHub_depositIdIncreasing() public {
    _initializeUsersArray();

    for (uint256 i = 0; i < 300; ++i) {
      _seedWithCollateral(users[i], 20_000e6);

      vm.startPrank(users[i]);
      USDC.approve(address(rwaHub), 20_000e6);
      rwaHub.requestSubscription(20_000e6);
      vm.stopPrank();

      (address user, uint256 amt, uint256 priceId) = rwaHub
        .depositIdToDepositor(bytes32(uint256(i + 1)));

      assertEq(rwaHub.subscriptionRequestCounter(), i + 2);
      assertEq(user, users[i]);
      assertEq(amt, 20_000e6);
      assertEq(priceId, 0);
    }
  }

  /*//////////////////////////////////////////////////////////////
                    Off-Chain Subscription Tests
  //////////////////////////////////////////////////////////////*/

  function test_rwaHub_addProof_fail_accessControl() public {
    vm.expectRevert(_formatACRevert(alice, rwaHub.RELAYER_ROLE()));
    vm.prank(alice);
    rwaHub.addProof(mockTxHash, alice, 100e6, 0, block.timestamp);
  }

  function test_rwaHub_addProof_fail_restricted() public {
    _restrictUser(alice);
    _expectOpinionatedRestrictionRevert();
    vm.prank(relayer);
    rwaHub.addProof(mockTxHash, alice, 100e6, 0, block.timestamp);
  }

  function test_rwaHub_addProof_fail_proofExists() public {
    vm.startPrank(relayer);
    rwaHub.addProof(mockTxHash, alice, 100e6, 0, block.timestamp);
    vm.expectRevert(IRWAHub.DepositProofAlreadyExists.selector);
    rwaHub.addProof(mockTxHash, alice, 100e6, 0, block.timestamp);
    vm.stopPrank();
  }

  function test_rwaHub_addProof() public {
    vm.prank(relayer);
    vm.expectEmit(true, true, true, true);
    emit DepositProofAdded(mockTxHash, alice, 100e6, 1e6, block.timestamp);
    rwaHub.addProof(mockTxHash, alice, 100e6, 1e6, block.timestamp);

    // State checks
    (address user, uint256 amountDeposited, uint256 priceId) = rwaHub
      .depositIdToDepositor(mockTxHash);
    assertEq(user, alice);
    assertEq(amountDeposited, 100e6);
    assertEq(priceId, 0);
  }

  function test_rwaHub_getProof_nonExistent() public {
    (address user, uint256 amountDeposited, uint256 priceId) = rwaHub
      .depositIdToDepositor(mockTxHash);
    assertEq(user, address(0));
    assertEq(amountDeposited, 0);
    assertEq(priceId, 0);
  }

  function test_rwaHub_addProof_claim() public {
    vm.prank(relayer);
    rwaHub.addProof(mockTxHash, alice, 100e6, 0, block.timestamp);

    // Set price
    depositIds.push(mockTxHash);
    priceIds.push(1);
    vm.prank(managerAdmin);
    rwaHub.setPriceIdForDeposits(depositIds, priceIds);
    _preClaimStep();
    rwaHub.claimMint(depositIds);

    // Assert that the deposit entry has been removed
    (address user, uint256 amt, uint256 priceId) = rwaHub.depositIdToDepositor(
      FIRST_DEPOSIT_ID
    );
    assertEq(user, address(0));
    assertEq(amt, 0);
    assertEq(priceId, 0);

    uint256 rwaBal = rwa.balanceOf(address(alice));
    assertEq(rwaBal, (100e18 * 1e18) / pricer.getLatestPrice());
  }

  /*//////////////////////////////////////////////////////////////
                      Deposit and Claim Tests
  //////////////////////////////////////////////////////////////*/

  function test_setPriceIdForDeposits_fail_repeat() public {
    _rwaHubDeposit(alice, 90_000e6);

    depositIds.push(FIRST_DEPOSIT_ID);
    priceIds.push(1);
    vm.startPrank(managerAdmin);
    rwaHub.setPriceIdForDeposits(depositIds, priceIds);
    vm.expectRevert(IRWAHub.PriceIdAlreadySet.selector);
    rwaHub.setPriceIdForDeposits(depositIds, priceIds);
    vm.stopPrank();
  }

  function test_rwaHub_deposit_and_claim() public {
    _rwaHubDeposit(alice, 90_000e6);

    depositIds.push(FIRST_DEPOSIT_ID);
    priceIds.push(1);

    vm.prank(managerAdmin);
    rwaHub.setPriceIdForDeposits(depositIds, priceIds);
    _preClaimStep();
    vm.expectEmit(true, true, true, true);
    emit MintCompleted(
      alice,
      FIRST_DEPOSIT_ID,
      90_000e36 / pricer.getPrice(1),
      90_000e6,
      pricer.getPrice(1),
      1
    );
    rwaHub.claimMint(depositIds);

    (address user, uint256 amt, uint256 priceId) = rwaHub.depositIdToDepositor(
      FIRST_DEPOSIT_ID
    );

    // Assert that the deposit entry has been removed
    assertEq(user, address(0));
    assertEq(amt, 0);
    assertEq(priceId, 0);

    uint256 rwaBal = rwa.balanceOf(address(alice));
    assertEq(rwaBal, (90_000e18 * 1e18) / pricer.getLatestPrice());
  }

  function test_fuzz_rwaHub_deposit_and_claim(uint256 amount) public {
    vm.assume(amount < 100_000_000e6);
    vm.assume(amount > rwaHub.minimumDepositAmount());

    _rwaHubDeposit(alice, amount);

    depositIds.push(FIRST_DEPOSIT_ID);
    priceIds.push(1);

    vm.prank(managerAdmin);
    rwaHub.setPriceIdForDeposits(depositIds, priceIds);
    _preClaimStep();
    rwaHub.claimMint(depositIds);

    (address user, uint256 amt, uint256 priceId) = rwaHub.depositIdToDepositor(
      FIRST_DEPOSIT_ID
    );

    // Assert that the deposit entry has been removed
    assertEq(user, address(0));
    assertEq(amt, 0);
    assertEq(priceId, 0);

    uint256 rwaBal = rwa.balanceOf(alice);
    assertEq(rwaBal, (amount * 1e12 * 1e18) / pricer.getLatestPrice());
  }

  function test_fuzz_rwaHub_deposit_and_claim_vary_price(
    uint256 amount,
    uint64 price
  ) public {
    vm.assume(amount < 100_000_000e6);
    vm.assume(amount > 100e6);
    vm.assume(price > 0);
    uint256 rate = 1e18 + uint256(price);

    _rwaHubDeposit(alice, amount);

    depositIds.push(FIRST_DEPOSIT_ID);

    priceIds.push(2);

    pricer.addPrice(rate, block.timestamp);

    vm.prank(managerAdmin);
    rwaHub.setPriceIdForDeposits(depositIds, priceIds);
    _preClaimStep();
    rwaHub.claimMint(depositIds);

    (address user, uint256 amt, uint256 priceId) = rwaHub.depositIdToDepositor(
      FIRST_DEPOSIT_ID
    );

    // Assert that the deposit entry has been removed
    assertEq(user, address(0));
    assertEq(amt, 0);
    assertEq(priceId, 0);

    uint256 rwaBal = rwa.balanceOf(alice);
    assertEq(rwaBal, (amount * 1e30) / rate);
  }

  /*//////////////////////////////////////////////////////////////
                             Claim Tests
  //////////////////////////////////////////////////////////////*/

  function test_rwaHub_claim_fail_priceIdNotSet() public postDepositState {
    depositIds.push(FIRST_DEPOSIT_ID);
    _preClaimStep();
    vm.expectRevert(IRWAHub.PriceIdNotSet.selector);
    rwaHub.claimMint(depositIds);
  }

  function test_rwaHub_fail_paused() public postDepositState pausedState {
    depositIds.push(FIRST_DEPOSIT_ID);
    _preClaimStep();
    vm.expectRevert(IRWAHub.FeaturePaused.selector);
    rwaHub.claimMint(depositIds);
  }

  /*//////////////////////////////////////////////////////////////
                               Utils
  //////////////////////////////////////////////////////////////*/

  // Allows tests that inherit from this to perform some action before
  // the claim.
  function _preClaimStep() internal virtual {}

  function _rwaHubDeposit(address user, uint256 amount) internal {
    _seedWithCollateral(address(user), amount);
    vm.startPrank(address(user));
    USDC.approve(address(rwaHub), amount);
    rwaHub.requestSubscription(amount);
    vm.stopPrank();
  }

  modifier postDepositState() {
    _rwaHubDeposit(alice, 1_000_000e6);
    _;
  }

  modifier pausedState() {
    vm.prank(pauser);
    rwaHub.pauseSubscription();
    _;
  }
}
