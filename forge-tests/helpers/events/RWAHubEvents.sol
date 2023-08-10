pragma solidity 0.8.16;

contract RWAHubEvents {
  event FeeRecipientSet(address oldFeeRecipient, address newFeeRecipient);
  event AssetSenderSet(address oldAssetSender, address newAssetSender);
  event MinimumDepositAmountSet(uint256 oldMinimum, uint256 newMinimum);
  event MinimumRedemptionAmountSet(uint256 oldRedeemMin, uint256 newRedeemMin);
  event MintFeeSet(uint256 oldFee, uint256 newFee);
  event RedemptionFeeSet(uint256 oldFee, uint256 newFee);
  event RedemptionRequested(
    address indexed user,
    bytes32 indexed redemptionId,
    uint256 rwaAmountIn
  );
  event MintRequested(
    address indexed user,
    bytes32 indexed depositId,
    uint256 collateralAmountDeposited,
    uint256 depositAmountAfterFee,
    uint256 feeAmount
  );
  event RedemptionCompleted(
    address indexed user,
    bytes32 indexed redemptionId,
    uint256 rwaAmountRequested,
    uint256 collateralAmountReturned
  );
  event MintCompleted(
    address indexed user,
    bytes32 indexed depositId,
    uint256 rwaAmountOut,
    uint256 collateralAmountDeposited,
    uint256 price,
    uint256 priceId
  );
  event PriceIdSetForDeposit(
    bytes32 indexed depositIdSet,
    uint256 indexed priceIdSet
  );
  event PriceIdSetForRedemption(
    bytes32 indexed redemptionIdSet,
    uint256 indexed priceIdSet
  );
  event NewPricerSet(address oldPricer, address newPricer);
  event DepositProofAdded(
    bytes32 indexed txHash,
    address indexed user,
    uint256 depositAmountAfterFee,
    uint256 feeAmount,
    uint256 timestamp
  );
  event SubscriptionPaused(address caller);
  event RedemptionPaused(address caller);
  event SubscriptionUnpaused(address caller);
  event RedemptionUnpaused(address caller);
}
