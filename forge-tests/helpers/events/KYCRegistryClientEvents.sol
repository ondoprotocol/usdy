pragma solidity 0.8.16;

contract KYCRegistryClientEvents {
  event KYCRegistrySet(address oldRegistry, address newRegistry);

  event KYCRequirementGroupSet(
    uint256 oldRequirementGroup,
    uint256 newRequirementGroup
  );
}
