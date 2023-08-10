// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "contracts/external/chainalysis/ISanctionsList.sol";

contract MockSanctionsOracle is ISanctionsList {
  address[] public sanctionedAddreses;

  function addAddress(address addr) public {
    sanctionedAddreses.push(addr);
  }

  function isSanctioned(address addr) external view override returns (bool) {
    for (uint256 i = 0; i < sanctionedAddreses.length; ++i) {
      if (sanctionedAddreses[i] == addr) {
        return true;
      }
    }
    return false;
  }
}
