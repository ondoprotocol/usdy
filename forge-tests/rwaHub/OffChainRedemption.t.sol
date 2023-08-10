// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "forge-tests/helpers/events/RWAHubOffChainRedemptionsEvents.sol";
import "contracts/RWAHubOffChainRedemptions.sol";
import "forge-tests/BaseTestRunner.sol";

abstract contract Test_OffChainRedemption_Manager is
  BaseTestRunner,
  RWAHubOffChainRedemptionsEvents
{
  bytes32 public constant BANK_ACCOUNT =
    keccak256("ROUTING:123456,ACCOUNT:123456");
  // RWA hub under test. MUST BE SET BY INHERITING CONTRACT
  RWAHubOffChainRedemptions public rwaHubOffChain;

  function _setRWAHubOffChainRedemptions(address _rwaHubOffChain) public {
    rwaHubOffChain = RWAHubOffChainRedemptions(_rwaHubOffChain);
  }

  function test_requestRedemptionServicedOffchain_fail_min() public {
    vm.startPrank(managerAdmin);
    vm.expectEmit(true, true, true, true);
    emit OffChainRedemptionMinimumSet(100e18, 10);
    rwaHubOffChain.setOffChainRedemptionMinimum(10);
    vm.stopPrank();
    vm.startPrank(alice);
    rwa.approve(address(rwaHubOffChain), 1000e18);
    vm.expectRevert(IRWAHub.RedemptionTooSmall.selector);
    rwaHubOffChain.requestRedemptionServicedOffchain(9, BANK_ACCOUNT);
    vm.stopPrank();
  }

  function test_setOffChainRedemptionMinimum_fail_AC() public {
    vm.expectRevert(_formatACRevert(bob, rwaHub.MANAGER_ADMIN()));
    vm.prank(bob);
    rwaHubOffChain.setOffChainRedemptionMinimum(10);
  }

  function test_requestRedemptionServicedOffchain()
    public
    postClaimState(alice, 1000e18)
  {
    vm.startPrank(alice);
    rwa.approve(address(rwaHubOffChain), 1000e18);
    vm.expectEmit(true, true, true, true);
    emit RedemptionRequestedServicedOffChain(
      alice,
      FIRST_REDEMPTION_ID,
      1000e18,
      BANK_ACCOUNT
    );
    rwaHubOffChain.requestRedemptionServicedOffchain(1000e18, BANK_ACCOUNT);
    vm.stopPrank();

    // Assert that all of alice's RWA tokens has been burned
    assertEq(rwa.balanceOf(alice), 0);
  }

  function test_requestRedemptionServicedOffchain_fail_paused()
    public
    postClaimState(alice, 1000e18)
  {
    vm.prank(pauser);
    rwaHubOffChain.pauseOffChainRedemption();

    vm.startPrank(alice);
    rwa.approve(address(rwaHubOffChain), 1000e18);
    vm.expectRevert(IRWAHub.FeaturePaused.selector);
    rwaHubOffChain.requestRedemptionServicedOffchain(1000e18, BANK_ACCOUNT);
    vm.stopPrank();
  }

  function test_pauseOffChainRedemption_fail_AC() public {
    vm.expectRevert(_formatACRevert(charlie, rwaHubOffChain.PAUSER_ADMIN()));
    vm.prank(charlie);
    rwaHubOffChain.pauseOffChainRedemption();
  }

  function test_pauseOffChainRedemption() public {
    vm.prank(pauser);
    vm.expectEmit(true, true, true, true);
    emit OffChainRedemptionPaused(pauser);
    rwaHubOffChain.pauseOffChainRedemption();

    assertTrue(rwaHubOffChain.offChainRedemptionPaused());
  }

  function test_unpauseOffChainRedemption_fail_AC() public {
    vm.expectRevert(_formatACRevert(charlie, rwaHubOffChain.MANAGER_ADMIN()));
    vm.prank(charlie);
    rwaHubOffChain.unpauseOffChainRedemption();
  }

  function test_unpauseOffChainRedemption() public {
    vm.prank(pauser);
    rwaHubOffChain.pauseOffChainRedemption();

    vm.prank(managerAdmin);
    vm.expectEmit(true, true, true, true);
    emit OffChainRedemptionUnpaused(managerAdmin);
    rwaHubOffChain.unpauseOffChainRedemption();
    assertFalse(rwaHubOffChain.offChainRedemptionPaused());
  }
}
