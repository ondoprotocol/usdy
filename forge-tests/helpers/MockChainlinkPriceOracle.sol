// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "contracts/external/chainlink/AggregatorV3Interface.sol";

contract MockChainlinkPriceOracle is AggregatorV3Interface {
  uint8 public decimals;
  string public description;
  uint80 roundId;
  int256 answer;
  uint256 startedAt;
  uint256 updatedAt;
  uint80 answeredInRound;

  constructor(uint8 _decimals, string memory _description) {
    decimals = _decimals;
    description = _description;
  }

  function version() external pure override returns (uint256) {
    return 1;
  }

  function setDecimals(uint8 _decimals) external {
    decimals = _decimals;
  }

  function setRoundData(
    uint80 _roundId,
    int256 _answer,
    uint256 _startedAt,
    uint256 _updatedAt,
    uint80 _answeredInRound
  ) external {
    roundId = _roundId;
    answer = _answer;
    startedAt = _startedAt;
    updatedAt = _updatedAt;
    answeredInRound = _answeredInRound;
  }

  function getRoundData(
    uint80
  ) external view override returns (uint80, int256, uint256, uint256, uint80) {
    return latestRoundData();
  }

  function latestRoundData()
    public
    view
    override
    returns (uint80, int256, uint256, uint256, uint80)
  {
    return (roundId, answer, startedAt, updatedAt, answeredInRound);
  }
}
