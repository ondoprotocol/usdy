pragma solidity 0.8.16;

contract RWAHubNonStableInstantMintEvents {
  event InstantMint(
    address indexed user,
    uint256 collateralAmountDeposited,
    uint256 collateralAmountAfterFees,
    uint256 feesInCollateral,
    uint256 rwaGiven,
    uint256 priceMinted,
    bytes32 depositId
  );
  event ExcessMintClaimed(
    address indexed user,
    uint256 rwaOwedAtSetPrice,
    uint256 rwaPreviouslyGiven,
    uint256 rwaExcessGiven,
    uint256 priceClaimed,
    bytes32 depositId
  );
  event InstantMintGivenOverriden(
    bytes32 indexed depositId,
    uint256 oldGivenAmt,
    uint256 newGivenAmt
  );
  event InstantMintAssetManagerSet(
    address oldInstantAssetManager,
    address newInstantAssetManager
  );
  event InstantMintAmountSet(
    uint256 oldInstantMintBps,
    uint256 newInstantMintBps
  );
  event InstantMintPaused(address caller);
  event InstantMintUnpaused(address caller);
  event ClaimExcessPaused(address caller);
  event ClaimExcessUnpaused(address caller);
  event InstantMintFeeSet(uint256 oldFee, uint256 newFee);
  event InstantMintLimitSet(uint256 mintLimit);
  event InstantMintLimitDurationSet(uint256 mintLimitDuration);
}
