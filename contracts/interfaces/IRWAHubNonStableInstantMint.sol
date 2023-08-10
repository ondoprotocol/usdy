/**SPDX-License-Identifier: BUSL-1.1

      ▄▄█████████▄
   ╓██▀└ ,╓▄▄▄, '▀██▄
  ██▀ ▄██▀▀╙╙▀▀██▄ └██µ           ,,       ,,      ,     ,,,            ,,,
 ██ ,██¬ ▄████▄  ▀█▄ ╙█▄      ▄███▀▀███▄   ███▄    ██  ███▀▀▀███▄    ▄███▀▀███,
██  ██ ╒█▀'   ╙█▌ ╙█▌ ██     ▐██      ███  █████,  ██  ██▌    └██▌  ██▌     └██▌
██ ▐█▌ ██      ╟█  █▌ ╟█     ██▌      ▐██  ██ └███ ██  ██▌     ╟██ j██       ╟██
╟█  ██ ╙██    ▄█▀ ▐█▌ ██     ╙██      ██▌  ██   ╙████  ██▌    ▄██▀  ██▌     ,██▀
 ██ "██, ╙▀▀███████████⌐      ╙████████▀   ██     ╙██  ███████▀▀     ╙███████▀`
  ██▄ ╙▀██▄▄▄▄▄,,,                ¬─                                    '─¬
   ╙▀██▄ '╙╙╙▀▀▀▀▀▀▀▀
      ╙▀▀██████R⌐

 */
pragma solidity 0.8.16;

import "contracts/interfaces/IRWAHub.sol";

interface IRWAHubNonStableInstantMint {
  /**
   * @notice Event emitted when an instant mint is completed
   *
   * @param user                      The address of the user
   * @param collateralAmountDeposited The amount of collateral deposited
   * @param collateralAmountAfterFees The amount of collateral after fees
   * @param feesInCollateral          The amount of fees in collateral
   * @param rwaGiven                  The amount of rwa minted to the user
   * @param priceMinted               The price at which the rwa was minted at
   * @param depositId                 The id of the deposit in RWAHub
   */
  event InstantMint(
    address indexed user,
    uint256 collateralAmountDeposited,
    uint256 collateralAmountAfterFees,
    uint256 feesInCollateral,
    uint256 rwaGiven,
    uint256 priceMinted,
    bytes32 depositId
  );

  /**
   * @notice Event emitted when the excess of the instant mint is claimed
   *
   * @param user           The address of the user
   * @param totalRWAOwed   The total amount of rwa owed (instant mint + excess)
   * @param rwaExcessDue   The amount of excess rwa owed
   * @param rwaExcessGiven The amount of rwa excess given in this claim
   * @param priceClaimed   The price at which the excess rwa was claimed at
   * @param depositId      The id of the deposit in RWAHub
   */
  event ExcessMintClaimed(
    address indexed user,
    uint256 totalRWAOwed,
    uint256 rwaExcessDue,
    uint256 rwaExcessGiven,
    uint256 priceClaimed,
    bytes32 depositId
  );

  /**
   * @notice Event emitted when instant mint given is overriden
   *
   * @param depositId   The id of the deposit in RWAHub
   * @param oldGivenAmt The old amount of rwa given
   * @param newGivenAmt The new amount of rwa given
   */
  event InstantMintGivenOverriden(
    bytes32 indexed depositId,
    uint256 oldGivenAmt,
    uint256 newGivenAmt
  );

  /**
   * @notice Event emitted when instant mint asset manager is set
   *
   * @param oldInstantMintAssetManager Old instant mint asset manager
   * @param newInstantMintAssetManager New instant mint asset manager
   */
  event InstantMintAssetManagerSet(
    address oldInstantMintAssetManager,
    address newInstantMintAssetManager
  );

  /**
   * @notice Event emitted when instant mint amount % (in bps) is set
   *
   * @param oldInstantMintBps Old instant mint amount in bps
   * @param newInstantMintBps New instant mint amount in bps
   */
  event InstantMintAmountSet(
    uint256 oldInstantMintBps,
    uint256 newInstantMintBps
  );

  /**
   * @notice Event emitted when instant mints are paused
   *
   * @param caller Address which initiated the pause
   */
  event InstantMintPaused(address caller);

  /**
   * @notice Event emitted when instant mints are unpaused
   *
   * @param caller Address which initiated the unpause
   */
  event InstantMintUnpaused(address caller);

  /**
   * @notice Event emitted when claiming excess is paused
   *
   * @param caller Address which initiated the pause
   */
  event ClaimExcessPaused(address caller);

  /**
   * @notice Event emitted when claiming excess is unpaused
   *
   * @param caller Address which initiated the unpause
   */
  event ClaimExcessUnpaused(address caller);

  /**
   * @notice Event emitted when instant mint fee is set
   *
   * @param oldFee Old fee
   * @param newFee New fee
   *
   * @dev See inheriting contract for decimals representation
   */
  event InstantMintFeeSet(uint256 oldFee, uint256 newFee);

  // Errors
  error CannotClaimExcess();
  error CannotClaimMint();
}
