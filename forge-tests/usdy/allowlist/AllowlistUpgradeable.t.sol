pragma solidity 0.8.16;

import "contracts/usdy/allowlist/AllowlistUpgradeable.sol";
import "contracts/usdy/allowlist/AllowlistFactory.sol";
import "contracts/interfaces/IAllowlistClient.sol";
import "forge-tests/usdy/allowlist/AllowlistUpgradeable_BasicDeployment.sol";
import "forge-tests/MinimalTestRunner.sol";
import "contracts/external/openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract FakeContract {}

contract Test_Allowlist is AllowlistUpgradeable_BasicDeployment {
  uint256[] otherIndexes;

  uint256 public constant signerPrivateKey = 0xB0B;
  address public signer;
  uint8 v;
  bytes32 r;
  bytes32 s;

  // Sets storage variables of test contract
  function _makeSignature(string memory message) private {
    bytes memory sb = bytes(message);
    bytes32 hashedMessage = ECDSA.toEthSignedMessageHash(sb);
    (uint8 _v, bytes32 _r, bytes32 _s) = vm.sign(
      signerPrivateKey,
      hashedMessage
    );
    v = _v;
    r = _r;
    s = _s;
  }

  function setUp() public override {
    super.setUp();
    signer = vm.addr(signerPrivateKey);
  }

  /*//////////////////////////////////////////////////////////////
                      Test Factory Construction
  //////////////////////////////////////////////////////////////*/

  function test_ProxyAdminSetup() public {
    assertEq(allowlistProxyAdmin.owner(), guardian);
    assertEq(
      allowlistProxyAdmin.getProxyImplementation(
        TransparentUpgradeableProxy(payable(address(allowlist)))
      ),
      address(allowlistImplementation)
    );
    assertEq(
      allowlistProxyAdmin.getProxyAdmin(
        TransparentUpgradeableProxy(payable(address(allowlist)))
      ),
      address(allowlistProxyAdmin)
    );
  }

  function test_Proxy() public {
    vm.startPrank(address(allowlistProxyAdmin));
    assertEq(
      TransparentUpgradeableProxy(payable(address(allowlist))).admin(),
      address(allowlistProxyAdmin)
    );
    assertEq(
      TransparentUpgradeableProxy(payable(address(allowlist))).implementation(),
      address(allowlistImplementation)
    );
    vm.stopPrank();
  }

  function test_Impl() public {
    vm.startPrank(address(allowlistProxyAdmin));
    assertEq(
      TransparentUpgradeableProxy(payable(address(allowlist))).admin(),
      address(allowlistProxyAdmin)
    );
    assertEq(
      TransparentUpgradeableProxy(payable(address(allowlist))).implementation(),
      address(allowlistImplementation)
    );
    vm.stopPrank();
  }

  function test_ProxyAccessControlState() public {
    assertEq(allowlist.getRoleMemberCount(allowlist.DEFAULT_ADMIN_ROLE()), 1);
    assertEq(allowlist.getRoleMemberCount(allowlist.ALLOWLIST_ADMIN()), 1);
    assertEq(allowlist.getRoleMemberCount(allowlist.ALLOWLIST_SETTER()), 1);

    assertEq(
      allowlist.getRoleMember(allowlist.DEFAULT_ADMIN_ROLE(), 0),
      allowlistAdmin
    );
    assertEq(
      allowlist.getRoleMember(allowlist.ALLOWLIST_ADMIN(), 0),
      allowlistAdmin
    );
    assertEq(
      allowlist.getRoleMember(allowlist.ALLOWLIST_SETTER(), 0),
      allowlistSetter
    );
  }

  /*//////////////////////////////////////////////////////////////
                          Test Term Setters
  //////////////////////////////////////////////////////////////*/

  function test_getCurrentTerm() public {
    assertEq(allowlist.getCurrentTerm(), TERM_1);
    uint256 curIdx = allowlist.currentTermIndex();
    assertEq(curIdx, 0);
    assertEq(allowlist.terms(curIdx), allowlist.getCurrentTerm());
  }

  function test_addTerm() public {
    vm.expectEmit(true, true, true, true);
    emit TermAdded(keccak256(bytes(TERM_2)), 1);
    vm.prank(allowlistAdmin);
    allowlist.addTerm(TERM_2);
    uint256 curIdx = allowlist.currentTermIndex();
    assertEq(allowlist.getCurrentTerm(), TERM_2);
    assertEq(curIdx, 1);
    assertEq(allowlist.terms(curIdx), allowlist.getCurrentTerm());
  }

  function test_addTerm_fail_AC() public {
    vm.expectRevert(_formatACRevert(alice, allowlist.ALLOWLIST_ADMIN()));
    vm.prank(alice);
    allowlist.addTerm(TERM_2);
  }

  function test_setCurrentTermIndex() public {
    vm.prank(allowlistAdmin);
    allowlist.addTerm(TERM_2);
    uint256 oldIdx = allowlist.currentTermIndex();
    vm.expectEmit(true, true, true, true);
    emit CurrentTermIndexSet(oldIdx, 0);
    vm.prank(allowlistAdmin);
    allowlist.setCurrentTermIndex(0);
    assertEq(allowlist.currentTermIndex(), 0);
  }

  function test_setCurrentTermIndex_OOB() public {
    vm.expectRevert(IAllowlist.InvalidTermIndex.selector);
    vm.prank(allowlistAdmin);
    allowlist.setCurrentTermIndex(1);
  }

  function test_setCurrentTermIndex_fail_AC() public {
    vm.prank(allowlistAdmin);
    allowlist.addTerm(TERM_2);
    vm.expectRevert(_formatACRevert(alice, allowlist.ALLOWLIST_ADMIN()));
    vm.prank(alice);
    allowlist.setCurrentTermIndex(0);
  }

  function test_setValidTermIndexes() public {
    vm.startPrank(allowlistAdmin);
    allowlist.addTerm(TERM_2);
    allowlist.addTerm(TERM_3);
    indexes.push(1);
    indexes.push(2);
    otherIndexes.push(0);
    vm.expectEmit(true, true, true, true);
    emit ValidTermIndexesSet(otherIndexes, indexes);
    allowlist.setValidTermIndexes(indexes);
    vm.stopPrank();
    assertEq(allowlist.validIndexes(0), 1);
    assertEq(allowlist.validIndexes(1), 2);
    delete indexes;
    delete otherIndexes;
  }

  function test_setValidTermIndexes_fail_OOB() public {
    vm.startPrank(allowlistAdmin);
    allowlist.addTerm(TERM_2);
    allowlist.addTerm(TERM_3);
    indexes.push(1);
    indexes.push(2);
    // 3 is out of bounds
    indexes.push(3);
    vm.expectRevert(IAllowlist.InvalidTermIndex.selector);
    allowlist.setValidTermIndexes(indexes);
    vm.stopPrank();
    delete indexes;
    delete otherIndexes;
  }

  function test_setValidTermIndexes_fail_AC() public {
    vm.expectRevert(_formatACRevert(alice, allowlist.ALLOWLIST_ADMIN()));
    vm.prank(alice);
    allowlist.setValidTermIndexes(indexes);
  }

  /*//////////////////////////////////////////////////////////////
                      Test AllowlistUpgradeable logic
  //////////////////////////////////////////////////////////////*/

  function test_normalAddSignature() public {
    _makeSignature(allowlist.getCurrentTerm());
    vm.expectEmit(true, true, true, true);
    emit AccountAddedFromSignature(
      signer,
      allowlist.currentTermIndex(),
      v,
      r,
      s
    );
    allowlist.addAccountToAllowlist(
      allowlist.currentTermIndex(),
      signer,
      v,
      r,
      s
    );
    assertTrue(allowlist.isAllowed(signer));
  }

  function test_invalidateOldTerm() public {
    // Signs and add term 1
    _makeSignature(allowlist.getCurrentTerm());
    allowlist.addAccountToAllowlist(
      allowlist.currentTermIndex(),
      signer,
      v,
      r,
      s
    );
    vm.startPrank(allowlistAdmin);
    allowlist.addTerm(TERM_2);
    indexes.push(1);
    // now only term 2 is valid.
    allowlist.setValidTermIndexes(indexes);
    vm.stopPrank();
    assertFalse(allowlist.isAllowed(signer));
    delete indexes;
  }

  function test_twoTermsSignedAndValid() public {
    // Signs and add term 1
    _makeSignature(allowlist.getCurrentTerm());
    allowlist.addAccountToAllowlist(
      allowlist.currentTermIndex(),
      signer,
      v,
      r,
      s
    );
    vm.prank(allowlistAdmin);
    allowlist.addTerm(TERM_2);
    // Signs and add term 2
    _makeSignature(allowlist.getCurrentTerm());
    allowlist.addAccountToAllowlist(
      allowlist.currentTermIndex(),
      signer,
      v,
      r,
      s
    );
    indexes.push(0);
    indexes.push(1);
    // both terms are valid.
    vm.prank(allowlistAdmin);
    allowlist.setValidTermIndexes(indexes);
    assertTrue(allowlist.isAllowed(signer));
    delete indexes;
  }

  function test_noValidTerms() public {
    // Signs and add term 1
    _makeSignature(allowlist.getCurrentTerm());
    allowlist.addAccountToAllowlist(
      allowlist.currentTermIndex(),
      signer,
      v,
      r,
      s
    );
    vm.prank(allowlistAdmin);
    allowlist.addTerm(TERM_2);
    // Signs and add term 2
    _makeSignature(allowlist.getCurrentTerm());
    allowlist.addAccountToAllowlist(
      allowlist.currentTermIndex(),
      signer,
      v,
      r,
      s
    );
    // Add empty list
    vm.prank(allowlistAdmin);
    allowlist.setValidTermIndexes(indexes);
    assertFalse(allowlist.isAllowed(signer));
  }

  function test_contractsAllowed() public {
    FakeContract fc = new FakeContract();
    assertTrue(allowlist.isAllowed(address(fc)));
  }

  function test_verify_fail_incorrectTermPassed() public {
    _makeSignature(allowlist.getCurrentTerm());
    vm.prank(allowlistAdmin);
    allowlist.addTerm(TERM_2);
    vm.expectRevert(IAllowlist.InvalidSigner.selector);
    allowlist.addAccountToAllowlist(1, signer, v, r, s);
  }

  function test_verify_fail_alreadyVerified() public {
    _makeSignature(allowlist.getCurrentTerm());
    allowlist.addAccountToAllowlist(0, signer, v, r, s);
    vm.expectRevert(IAllowlist.AlreadyVerified.selector);
    allowlist.addAccountToAllowlist(0, signer, v, r, s);
  }

  function test_verify_fail_badV() public {
    _makeSignature(allowlist.getCurrentTerm());
    v = 29;
    vm.expectRevert(IAllowlist.InvalidVSignature.selector);
    allowlist.addAccountToAllowlist(0, signer, v, r, s);
  }

  function test_verify_fail_badSigner() public {
    _makeSignature(allowlist.getCurrentTerm());
    vm.expectRevert(IAllowlist.InvalidSigner.selector);
    allowlist.addAccountToAllowlist(0, alice, v, r, s);
  }

  function test_addSelfToAllowlist() public {
    assertFalse(allowlist.isAllowed(alice));
    vm.expectEmit(true, true, true, true);
    emit AccountAddedSelf(alice, 0);
    emit AccountStatusSet(alice, 0, true);
    vm.prank(alice);
    allowlist.addSelfToAllowlist(0);
    assertTrue(allowlist.isAllowed(alice));
  }

  function test_addSelfToAllowlist_fail_alreadySet() public {
    vm.prank(alice);
    allowlist.addSelfToAllowlist(0);
    vm.expectRevert(IAllowlist.AlreadyVerified.selector);
    vm.prank(alice);
    allowlist.addSelfToAllowlist(0);
  }

  function test_addSelfToAllowlist_fail_OOB() public {
    vm.expectRevert(IAllowlist.InvalidTermIndex.selector);
    vm.prank(alice);
    allowlist.addSelfToAllowlist(1);
  }

  function test_setAccountStatus_True() public {
    vm.expectEmit(true, true, true, true);
    emit AccountStatusSetByAdmin(alice, 0, true);
    emit AccountStatusSet(alice, 0, true);
    vm.prank(allowlistSetter);
    allowlist.setAccountStatus(alice, 0, true);
    assertTrue(allowlist.isAllowed(alice));
  }

  function test_setAccountStatus_False() public {
    vm.prank(alice);
    allowlist.addSelfToAllowlist(0);
    vm.expectEmit(true, true, true, true);
    emit AccountStatusSetByAdmin(alice, 0, false);
    emit AccountStatusSet(alice, 0, false);
    vm.prank(allowlistSetter);
    allowlist.setAccountStatus(alice, 0, false);
    assertFalse(allowlist.isAllowed(alice));
  }

  function test_setAccountStatus_fail_AC() public {
    vm.expectRevert(
      _formatACRevert(address(this), allowlist.ALLOWLIST_SETTER())
    );
    allowlist.setAccountStatus(alice, 0, true);
  }

  function test_setAccountStatus_fail_OOB() public {
    vm.prank(allowlistSetter);
    vm.expectRevert(IAllowlist.InvalidTermIndex.selector);
    allowlist.setAccountStatus(alice, 1, true);
  }
}
