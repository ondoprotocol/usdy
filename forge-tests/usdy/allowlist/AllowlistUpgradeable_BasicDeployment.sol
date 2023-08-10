pragma solidity 0.8.16;

import "forge-tests/MinimalTestRunner.sol";
import "contracts/usdy/allowlist/AllowlistFactory.sol";
import "contracts/interfaces/IAllowlistClient.sol";

contract AllowlistEvents {
  event TermAdded(bytes32 hashedMessage, uint256 termIndex);
  event CurrentTermIndexSet(uint256 oldIndex, uint256 newIndex);
  event ValidTermIndexesSet(uint256[] oldIndexes, uint256[] newIndexes);

  event AccountStatusSetByAdmin(
    address indexed account,
    uint256 indexed termIndex,
    bool status
  );
  event AccountAddedSelf(address indexed account, uint256 indexed termIndex);
  event AccountAddedFromSignature(
    address indexed account,
    uint256 indexed termIndex,
    uint8 v,
    bytes32 r,
    bytes32 s
  );
  event AccountStatusSet(
    address indexed account,
    uint256 indexed termIndex,
    bool status
  );
}

abstract contract AllowlistUpgradeable_BasicDeployment is
  AllowlistEvents,
  MinimalTestRunner
{
  AllowlistUpgradeable allowlist; // Proxy with abi of implementation
  AllowlistProxy allowlistProxy;
  ProxyAdmin allowlistProxyAdmin;
  AllowlistUpgradeable allowlistImplementation;

  uint256[] indexes;

  address allowlistSetter = address(0x4444444);
  address allowlistAdmin = address(0x3333333);

  string public constant TERM_1 = "tester abc";
  string public constant TERM_2 = "tester def";
  string public constant TERM_3 = "tester ghi";

  function setUp() public virtual {
    _deployAllowlist();
  }

  function _deployAllowlist() internal {
    AllowlistFactory factory = new AllowlistFactory(guardian);
    vm.prank(guardian);
    (address proxy, address admin, address impl) = factory.deployAllowlist(
      allowlistAdmin,
      allowlistSetter
    );

    allowlist = AllowlistUpgradeable(proxy);
    allowlistProxy = AllowlistProxy(payable(proxy));
    allowlistProxyAdmin = ProxyAdmin(admin);
    allowlistImplementation = AllowlistUpgradeable(impl);
    vm.startPrank(allowlistAdmin);
    allowlist.addTerm(TERM_1);
    indexes.push(0);
    allowlist.setValidTermIndexes(indexes);
    vm.stopPrank();
    delete indexes;
  }

  function _addAccountToAllowlistCurrentTerm(address account) internal {
    uint256 termIndex = allowlist.currentTermIndex();
    vm.prank(allowlistSetter);
    allowlist.setAccountStatus(account, termIndex, true);
  }

  function _removeAccountFromAllowlistCurrentTerm(address account) internal {
    uint256 termIndex = allowlist.currentTermIndex();
    vm.prank(allowlistSetter);
    allowlist.setAccountStatus(account, termIndex, false);
  }
}
