pragma solidity 0.8.16;

contract RWAHubOffChainRedemptionsEvents {
  event RedemptionRequestedServicedOffChain(
    address indexed user,
    bytes32 indexed redemptionId,
    uint256 rwaTokenAmountIn,
    bytes32 offChainDestination
  );
  event OffChainRedemptionPaused(address caller);
  event OffChainRedemptionUnpaused(address caller);
  event OffChainRedemptionMinimumSet(uint256 oldMinimum, uint256 newMinimum);
}
