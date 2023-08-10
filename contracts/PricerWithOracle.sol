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

import "contracts/external/openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "contracts/interfaces/IPricerWithOracle.sol";
import "contracts/Pricer.sol";
import "contracts/rwaOracles/IRWAOracleSetter.sol";

contract PricerWithOracle is
  AccessControlEnumerable,
  Pricer,
  IPricerWithOracle
{
  // Pointer to rwaOracle
  IRWAOracleSetter public immutable rwaOracle;

  constructor(
    address admin,
    address pricer,
    address _rwaOracle
  ) Pricer(admin, pricer) {
    rwaOracle = IRWAOracleSetter(_rwaOracle);

    // Set initial priceId data
    uint256 priceId = ++currentPriceId;
    (uint256 latestOraclePrice, uint256 timestamp) = rwaOracle.getPriceData();
    prices[priceId] = PriceInfo(latestOraclePrice, timestamp);
    priceIds.push(priceId);
    latestPriceId = priceId;
    emit PriceAdded(priceId, latestOraclePrice, timestamp);
  }

  /**
   * @notice Adds a price to the pricer
   *
   * @param price     The price to add
   * @param timestamp The timestamp associated with the price
   *
   * @dev Updates the oracle price if price is the latest
   */
  function addPrice(
    uint256 price,
    uint256 timestamp
  ) external override(Pricer, IPricer) onlyRole(PRICE_UPDATE_ROLE) {
    if (price == 0) {
      revert InvalidPrice();
    }

    // Set price
    uint256 priceId = ++currentPriceId;
    prices[priceId] = PriceInfo(price, timestamp);
    priceIds.push(priceId);

    // Update latestPriceId & Oracle Price
    if (timestamp > prices[latestPriceId].timestamp) {
      _updateOraclePrice(price, latestPriceId);
      latestPriceId = priceId;
    }

    emit PriceAdded(priceId, price, timestamp);
  }

  /**
   * @notice Adds a price in the pricer to match the oracle price
   *
   * @dev This function can be used to "catch-up" the Pricer with the oracle
   *      price if the latest oracle price was not set through the Pricer
   */
  function addLatestOraclePrice() external onlyRole(PRICE_UPDATE_ROLE) {
    (uint256 latestOraclePrice, uint256 latestOraclePriceTimestamp) = rwaOracle
      .getPriceData();

    PriceInfo memory latestPriceInfo = prices[latestPriceId];
    if (
      latestPriceInfo.price == latestOraclePrice &&
      latestPriceInfo.timestamp == latestOraclePriceTimestamp
    ) {
      revert PricesAlreadyMatch();
    }

    // Set price
    uint256 priceId = ++currentPriceId;
    prices[priceId] = PriceInfo(latestOraclePrice, latestOraclePriceTimestamp);
    priceIds.push(priceId);

    // Update latestPriceId. latestPriceInfo.timestamp is always
    // <= latestOraclePriceTimestamp, so we can skip a check
    latestPriceId = priceId;

    emit PriceAdded(priceId, latestOraclePrice, latestOraclePriceTimestamp);
  }

  /**
   * @notice Updates the RWA oracle price
   *
   * @param price         The price to set in the oracle
   * @param _latestPriceId The priceId associated with the latest price
   */
  function _updateOraclePrice(uint256 price, uint256 _latestPriceId) internal {
    (uint256 latestOraclePrice, ) = rwaOracle.getPriceData();
    if (prices[_latestPriceId].price != latestOraclePrice) {
      revert LatestPriceMismatch();
    }
    rwaOracle.setPrice(int256(price));
  }

  // Errors
  error LatestPriceMismatch();
  error PricesAlreadyMatch();
}
