pragma solidity 0.8.16;

import "forge-tests/USDY_BasicDeployment.sol";

contract USDYTest is USDY_BasicDeployment {
  function setUp() public override {
    super.setUp();
    _addAccountToAllowlistCurrentTerm(bob);
    vm.prank(guardian);
    usdy.mint(alice, 1000e18);
  }

  function test_usdy_name() public {
    assertEq(usdy.name(), "USDY");
  }

  function test_usdy_symbol() public {
    assertEq(usdy.symbol(), "USDY");
  }

  function test_usdy_decimals() public {
    assertEq(usdy.decimals(), 18);
  }

  function test_pause() public {
    vm.prank(guardian);
    usdy.pause();
    assertTrue(usdy.paused());
  }

  function test_mint_fail_when_paused() public pausedState {
    vm.expectRevert("ERC20Pausable: token transfer while paused");
    vm.prank(guardian);
    usdy.mint(bob, 10e18);
  }

  function test_burn_fail_when_paused() public pausedState {
    vm.startPrank(guardian);
    usdy.grantRole(usdy.BURNER_ROLE(), guardian);
    vm.expectRevert("ERC20Pausable: token transfer while paused");
    usdy.burn(alice, 10e18);
    vm.stopPrank();
  }

  function test_pause_fail_AC() public {
    vm.expectRevert("ERC20PresetMinterPauser: must have pauser role to pause");
    usdy.pause();
  }

  function test_unpause() public pausedState {
    vm.prank(guardian);
    usdy.unpause();
    assertFalse(usdy.paused());
  }

  function test_unpause_fail_AC() public {
    vm.prank(guardian);
    usdy.pause();
    vm.expectRevert(
      "ERC20PresetMinterPauser: must have pauser role to unpause"
    );
    usdy.unpause();
    assertTrue(usdy.paused());
  }

  function test_transfer_fail_paused() public pausedState {
    vm.expectRevert("ERC20Pausable: token transfer while paused");
    vm.prank(alice);
    usdy.transfer(bob, 1000e18);
  }

  function test_transfer_fail_from_allowlist() public {
    _removeAccountFromAllowlistCurrentTerm(alice);

    vm.expectRevert("USDY: 'from' address not on allowlist");
    vm.prank(alice);
    usdy.transfer(bob, 1000e18);
  }

  function test_transfer_fail_to_allowlist() public {
    _removeAccountFromAllowlistCurrentTerm(bob);

    vm.expectRevert("USDY: 'to' address not on allowlist");
    vm.prank(alice);
    usdy.transfer(bob, 1000e18);
  }

  function test_transfer_fail_sender_allowlist() public {
    vm.prank(alice);
    usdy.approve(charlie, 1000e18);

    vm.expectRevert("USDY: 'sender' address not on allowlist");
    vm.prank(charlie);
    usdy.transferFrom(alice, bob, 1000e18);
  }

  function test_transfer_fail_from_blocklist() public {
    _addToBlocklist(alice);

    vm.expectRevert("USDY: 'from' address blocked");
    vm.prank(alice);
    usdy.transfer(bob, 1000e18);
  }

  function test_transfer_fail_to_blocklist() public {
    _addToBlocklist(bob);

    vm.expectRevert("USDY: 'to' address blocked");
    vm.prank(alice);
    usdy.transfer(bob, 1000e18);
  }

  function test_transfer_fail_sender_blocklist() public {
    _addToBlocklist(charlie);
    _addAccountToAllowlistCurrentTerm(charlie);

    vm.prank(alice);
    usdy.approve(charlie, 1000e18);
    vm.expectRevert("USDY: 'sender' address blocked");
    vm.prank(charlie);
    usdy.transferFrom(alice, bob, 1000e18);
  }

  function test_transfer_fail_from_sanctions() public {
    _addToSanctionsList(alice);

    vm.expectRevert("USDY: 'from' address sanctioned");
    vm.prank(alice);
    usdy.transfer(bob, 1000e18);
  }

  function test_transfer_fail_to_sanctions() public {
    _addToSanctionsList(bob);

    vm.expectRevert("USDY: 'to' address sanctioned");
    vm.prank(alice);
    usdy.transfer(bob, 1000e18);
  }

  function test_transfer_fail_sender_sanctions() public {
    _addToSanctionsList(charlie);
    _addAccountToAllowlistCurrentTerm(charlie);

    vm.prank(alice);
    usdy.approve(charlie, 1000e18);
    vm.expectRevert("USDY: 'sender' address sanctioned");
    vm.prank(charlie);
    usdy.transferFrom(alice, bob, 1000e18);
  }

  function test_burn() public {
    uint256 totalSupply = usdy.totalSupply();
    vm.startPrank(guardian);
    usdy.grantRole(usdy.BURNER_ROLE(), guardian);
    usdy.burn(alice, 1000e18);
    vm.stopPrank();

    assertEq(usdy.totalSupply(), totalSupply - 1000e18);
    assertEq(usdy.balanceOf(alice), 0);
  }

  function test_burn_fail_AC() public {
    vm.expectRevert(_formatACRevert(charlie, usdy.BURNER_ROLE()));
    vm.prank(charlie);
    usdy.burn(alice, 1000e18);
  }

  function test_setSanctionsList_fail_AC() public {
    vm.expectRevert(_formatACRevert(bob, usdy.LIST_CONFIGURER_ROLE()));
    vm.prank(bob);
    usdy.setSanctionsList(charlie);
  }

  function test_setSanctionsList() public {
    ISanctionsList newSanctionsList = new MockSanctionsOracle();
    vm.startPrank(guardian);
    usdy.grantRole(usdy.LIST_CONFIGURER_ROLE(), guardian);
    vm.expectEmit(true, true, true, true);
    emit SanctionsListSet(address(sanctionsList), address(newSanctionsList));
    usdy.setSanctionsList(address(newSanctionsList));
    vm.stopPrank();
    assertEq(address(usdy.sanctionsList()), address(newSanctionsList));
  }

  function test_setBlocklist_fail_AC() public {
    vm.expectRevert(_formatACRevert(bob, usdy.LIST_CONFIGURER_ROLE()));
    vm.prank(bob);
    usdy.setBlocklist(charlie);
  }

  function test_setBlocklist() public {
    Blocklist newBlocklist = new Blocklist();
    vm.startPrank(guardian);
    usdy.grantRole(usdy.LIST_CONFIGURER_ROLE(), guardian);
    vm.expectEmit(true, true, true, true);
    emit BlocklistSet(address(blocklist), address(newBlocklist));
    usdy.setBlocklist(address(newBlocklist));
    vm.stopPrank();
    assertEq(address(usdy.blocklist()), address(newBlocklist));
  }

  function test_setAllowlist_fail_AC() public {
    vm.expectRevert(_formatACRevert(bob, usdy.LIST_CONFIGURER_ROLE()));
    vm.prank(bob);
    usdy.setAllowlist(charlie);
  }

  function test_setAllowlist() public {
    address oldAllowlist = address(usdy.allowlist());
    _deployAllowlist();
    vm.startPrank(guardian);
    usdy.grantRole(usdy.LIST_CONFIGURER_ROLE(), guardian);
    vm.expectEmit(true, true, true, true);
    emit AllowlistSet(oldAllowlist, address(allowlist));
    usdy.setAllowlist(address(allowlist));
    vm.stopPrank();
    assertEq(address(usdy.allowlist()), address(allowlist));
  }

  /*//////////////////////////////////////////////////////////////
                      Modifiers and Events
  //////////////////////////////////////////////////////////////*/

  modifier pausedState() {
    vm.prank(guardian);
    usdy.pause();
    _;
  }

  event SanctionsListSet(address oldSanctionsList, address newSanctionsList);
  event BlocklistSet(address oldBlocklist, address newBlocklist);
  event AllowlistSet(address oldAllowlist, address newAllowlist);
}
