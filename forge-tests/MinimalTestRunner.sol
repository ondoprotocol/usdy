pragma solidity 0.8.16;

import "forge-tests/helpers/Constants.sol";
import "forge-tests/helpers/DSTestPlus.sol";

/// @notice Contract to be inherited by tests that require no shared setup
abstract contract MinimalTestRunner is DSTestPlus, Constants, Tokens {
  function _formatACRevert(
    address account,
    bytes32 role
  ) internal pure returns (bytes memory) {
    string memory error1 = "AccessControl: account ";
    string memory error2 = " is missing role ";
    return
      abi.encodePacked(
        error1,
        Strings.toHexString(uint160(account), 20),
        error2,
        Strings.toHexString(uint256(role))
      );
  }
}
