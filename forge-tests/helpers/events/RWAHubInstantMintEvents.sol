pragma solidity 0.8.16;

contract RWAHubInstantMintEvents {
  event InstantMintFeeSet(uint256 oldFee, uint256 newFee);
  event InstantRedemptionFeeSet(uint256 oldFee, uint256 newFee);
  event InstantMintCompleted(
    address indexed user,
    uint256 collateralAmountDeposited,
    uint256 collateralAmountAfterFees,
    uint256 feesInCollateral,
    uint256 rwaOwed,
    uint256 price
  );
  event InstantRedemptionCompleted(
    address indexed user,
    uint256 rwaAmountBurned,
    uint256 collateralAmountAfterFees,
    uint256 feesInCollateral,
    uint256 price
  );
  event InstantMintPaused(address caller);
  event InstantMintUnpaused(address caller);
  event InstantRedemptionPaused(address caller);
  event InstantRedemptionUnpaused(address caller);
  event PriceIdSetForInstantMint(uint256 priceId);
  event PriceIdSetForInstantRedemption(uint256 priceId);
  event InstantMintLimitSet(uint256 mintLimit);
  event InstantRedemptionLimitSet(uint256 RedemptionLimit);
  event InstantMintLimitDurationSet(uint256 mintLimitDuration);
  event InstantRedemptionLimitDurationSet(uint256 RedemptionLimitDuration);
  event InstantMintAssetManagerSet(
    address oldInstantMintAssetManager,
    address newInstantMintAssetManager
  );
}
