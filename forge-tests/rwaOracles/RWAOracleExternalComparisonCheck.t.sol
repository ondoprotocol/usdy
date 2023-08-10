pragma solidity 0.8.16;

import "contracts/rwaOracles/RWAOracleExternalComparisonCheck.sol";
import "contracts/rwaOracles/IRWAOracleExternalComparisonCheck.sol";
import "contracts/external/chainlink/AggregatorV3Interface.sol";
import "forge-tests/MinimalTestRunner.sol";
import "forge-tests/helpers/MockChainlinkPriceOracle.sol";

contract RWAOracleExternalComparisonCheckTest is MinimalTestRunner {
  event RWAExternalComparisonCheckPriceSet(
    int256 oldChainlinkPrice,
    uint80 indexed oldRoundId,
    int256 newChainlinkPrice,
    uint80 indexed newRoundId,
    int256 oldRwaPrice,
    int256 newRwaPrice
  );

  event ChainlinkPriceIgnored(
    int256 oldChainlinkPrice,
    uint80 indexed oldRoundId,
    int256 newChainlinkPrice,
    uint80 indexed newRoundId
  );

  RWAOracleExternalComparisonCheck oracle;
  MockChainlinkPriceOracle mockChainlinkOracle;
  uint80 public currentRoundId = 1;
  int256 public constant INITIAL_CL_PRICE = 1000e8;
  int256 public constant INITIAL_RWA_PRICE = 100e18;
  int256 public constant BPS_DENOMINATOR = 10_000;

  function setUp() public {
    mockChainlinkOracle = new MockChainlinkPriceOracle(
      8,
      "Mock oracle for testing"
    );
    mockChainlinkOracle.setRoundData(
      currentRoundId,
      INITIAL_CL_PRICE,
      block.timestamp - 1,
      block.timestamp,
      currentRoundId
    );

    ++currentRoundId;
    oracle = new RWAOracleExternalComparisonCheck(
      INITIAL_RWA_PRICE,
      address(mockChainlinkOracle),
      "CONSTRAINED OUSG ORACLE TEST",
      address(this), //admin
      address(this) //setter role
    );
  }

  function setNewChainlinkPrice(int256 bps) private returns (int256) {
    (, int256 last_price, , , ) = mockChainlinkOracle.latestRoundData();
    int256 newPrice = (last_price * (BPS_DENOMINATOR + bps)) / BPS_DENOMINATOR;
    mockChainlinkOracle.setRoundData(
      currentRoundId,
      newPrice,
      block.timestamp - 1,
      block.timestamp,
      currentRoundId
    );
    ++currentRoundId;
    return newPrice;
  }

  function test_roundIDFailure() public {
    (, int256 last_price, , , ) = mockChainlinkOracle.latestRoundData();
    mockChainlinkOracle.setRoundData(
      currentRoundId,
      last_price + 1,
      block.timestamp - 1,
      block.timestamp,
      currentRoundId + 1
    );
    vm.expectRevert(
      IRWAOracleExternalComparisonCheck.CorruptedChainlinkResponse.selector
    );
    oracle.setPrice(INITIAL_RWA_PRICE);
  }

  function test_constructor_nominal() public {
    assertEq(INITIAL_RWA_PRICE, oracle.rwaPrice());
    assertEq(block.timestamp, oracle.priceTimestamp());
    assertEq(address(mockChainlinkOracle), address(oracle.chainlinkOracle()));
    string memory desc = "CONSTRAINED OUSG ORACLE TEST";
    assertEq(desc, oracle.description());
    (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    ) = oracle.lastSetRound();
    assertEq(currentRoundId - 1, roundId);
    assertEq(INITIAL_CL_PRICE, answer);
    assertEq(block.timestamp - 1, startedAt);
    assertEq(block.timestamp, updatedAt);
    assertEq(currentRoundId - 1, answeredInRound);
  }

  function test_constructorFailNegativePrice() public {
    mockChainlinkOracle.setRoundData(
      currentRoundId,
      -1, // Negative price
      block.timestamp - 1,
      block.timestamp,
      currentRoundId
    );
    vm.expectRevert(
      IRWAOracleExternalComparisonCheck.CorruptedChainlinkResponse.selector
    );
    oracle = new RWAOracleExternalComparisonCheck(
      INITIAL_RWA_PRICE,
      address(mockChainlinkOracle),
      "CONSTRAINED OUSG ORACLE TEST",
      address(this),
      address(this)
    );
  }

  function test_constructorFailRoundTooOld() public {
    mockChainlinkOracle.setRoundData(
      currentRoundId,
      1,
      block.timestamp - 26 hours - 1,
      block.timestamp - 26 hours,
      currentRoundId
    );
    vm.expectRevert(
      IRWAOracleExternalComparisonCheck.ChainlinkOraclePriceStale.selector
    );
    oracle = new RWAOracleExternalComparisonCheck(
      INITIAL_RWA_PRICE,
      address(mockChainlinkOracle),
      "CONSTRAINED OUSG ORACLE TEST",
      address(this),
      address(this)
    );
  }

  function test_priceDataGetter() public {
    vm.warp(block.timestamp + oracle.MIN_PRICE_UPDATE_WINDOW() + 1);
    setNewChainlinkPrice(100);
    vm.warp(block.timestamp + 2 hours);
    // Nominal RWA price update
    oracle.setPrice(1011e17);
    (uint256 price, uint256 timestamp) = oracle.getPriceData();
    assertEq(1011e17, price);
    assertEq(block.timestamp, timestamp);
    assertEq(1011e17, oracle.rwaPrice());
    assertEq(block.timestamp, oracle.priceTimestamp());
  }

  function test_doublePriceSetFail() public {
    vm.warp(block.timestamp + oracle.MIN_PRICE_UPDATE_WINDOW());
    setNewChainlinkPrice(60);
    vm.warp(block.timestamp + 1 minutes);
    oracle.setPrice(100e18);
    vm.warp(block.timestamp + 24 hours);
    // We must have a new round in CL in order to set a new price
    vm.expectRevert(
      IRWAOracleExternalComparisonCheck.ChainlinkRoundNotUpdated.selector
    );
    oracle.setPrice(100e18);
  }

  function test_staleCLOracleRound() public {
    vm.warp(block.timestamp + oracle.MIN_PRICE_UPDATE_WINDOW());
    setNewChainlinkPrice(60);
    vm.warp(block.timestamp + oracle.MAX_CL_WINDOW() + 1);
    vm.expectRevert(
      IRWAOracleExternalComparisonCheck.ChainlinkOraclePriceStale.selector
    );
    // Can't set the price because CL oracle latest round is > 25 hours old
    oracle.setPrice(100e18);
  }

  function test_priceUpdatedTooRecently() public {
    vm.warp(block.timestamp + oracle.MIN_PRICE_UPDATE_WINDOW());
    setNewChainlinkPrice(60);
    oracle.setPrice(100e18);
    vm.warp(block.timestamp + 1);
    setNewChainlinkPrice(60);
    vm.warp(block.timestamp + oracle.MIN_PRICE_UPDATE_WINDOW() - 1 hours);
    vm.expectRevert(
      IRWAOracleExternalComparisonCheck.PriceUpdateWindowViolation.selector
    );
    // Can't set the price because CL oracle latest round is > 25 hours old
    oracle.setPrice(100e18);
  }

  function test_onlySetter() public {
    vm.warp(block.timestamp + oracle.MIN_PRICE_UPDATE_WINDOW() + 1);
    // CL Price goes up 60 bps
    mockChainlinkOracle.setRoundData(
      currentRoundId,
      1006e8,
      block.timestamp,
      block.timestamp + 1,
      currentRoundId
    );
    vm.expectRevert(_formatACRevert(alice, oracle.SETTER_ROLE()));
    vm.prank(alice);
    oracle.setPrice(INITIAL_RWA_PRICE);
  }

  /// Relative Constraint Tests ///
  function test_relativeDeviationAtUpperBound() public {
    // The price of chainlink instrument changes +1%,
    // so the RWA price can increase by 1.74%
    vm.warp(block.timestamp + oracle.MIN_PRICE_UPDATE_WINDOW() + 1);
    setNewChainlinkPrice(100);

    ++currentRoundId;
    vm.warp(block.timestamp + 2 hours);
    // RWA gets updated 2 hours after, (23 hours)
    oracle.setPrice(10174e16);
    assertEq(10174e16, oracle.rwaPrice());
    assertEq(block.timestamp, oracle.priceTimestamp());
  }

  function test_relativeDeviationAtLowerBound() public {
    // The price of chainlink instrument changes +1%,
    // so the RWA price can increase by .26%
    vm.warp(block.timestamp + oracle.MIN_PRICE_UPDATE_WINDOW() + 1);
    setNewChainlinkPrice(100);
    vm.warp(block.timestamp + 2 hours);
    // RWA gets updated 2 hours after, (23 hours)
    oracle.setPrice(10026e16);
    assertEq(10026e16, oracle.rwaPrice());
    assertEq(block.timestamp, oracle.priceTimestamp());
  }

  function test_relativeDeviationOutsideUpperBound() public {
    // The price of chainlink instrument changes +1%,
    // so the RWA price can increase by 1.74%
    vm.warp(block.timestamp + oracle.MIN_PRICE_UPDATE_WINDOW() + 1);
    setNewChainlinkPrice(100);
    vm.warp(block.timestamp + 2 hours);
    // RWA gets updated 2 hours after, (23 hours)
    vm.expectRevert(
      IRWAOracleExternalComparisonCheck
        .DeltaDifferenceConstraintViolation
        .selector
    );
    oracle.setPrice(10175e16);
  }

  function test_relativeDeviationOutsideLowerBound() public {
    // The price of chainlink instrument changes +1%,
    // so the RWA price can increase by .26%
    vm.warp(block.timestamp + oracle.MIN_PRICE_UPDATE_WINDOW() + 1);
    setNewChainlinkPrice(100);
    // RWA gets updated 2 hours after, (23 hours)
    vm.expectRevert(
      IRWAOracleExternalComparisonCheck
        .DeltaDifferenceConstraintViolation
        .selector
    );
    oracle.setPrice(10025e16);
  }

  /// Absolute Constraint Tests ///
  function test_absoluteDeviationAtUpperBound() public {
    // In 23 hours, the price of chainlink instrument changes +2%,
    // The most RWA price can ever change is +2%
    vm.warp(block.timestamp + oracle.MIN_PRICE_UPDATE_WINDOW() + 1);
    setNewChainlinkPrice(200);
    ++currentRoundId;
    vm.warp(block.timestamp + 2 hours);
    // RWA gets updated 2 hours after, (23 hours)
    oracle.setPrice(1020e17);
    assertEq(1020e17, oracle.rwaPrice());
    assertEq(block.timestamp, oracle.priceTimestamp());
  }

  function test_absoluteDeviationAtLowerBound() public {
    // The price of chainlink instrument changes -2%,
    // The most the RWA price can ever change is -2%
    vm.warp(block.timestamp + oracle.MIN_PRICE_UPDATE_WINDOW() + 1);
    setNewChainlinkPrice(-200);
    vm.warp(block.timestamp + 2 hours);
    // RWA gets updated 2 hours after, (23 hours)
    oracle.setPrice(98e18);
    assertEq(98e18, oracle.rwaPrice());
    assertEq(block.timestamp, oracle.priceTimestamp());
  }

  function test_absoluteDeviationOutsideUpperBound() public {
    // The price of chainlink instrument changes +2%.
    // The most RWA price can ever change is +2%
    vm.warp(block.timestamp + oracle.MIN_PRICE_UPDATE_WINDOW() + 1);
    setNewChainlinkPrice(200);
    vm.warp(block.timestamp + 2 hours);
    // RWA gets updated 2 hours after, (23 hours)
    vm.expectRevert(
      IRWAOracleExternalComparisonCheck
        .AbsoluteDifferenceConstraintViolated
        .selector
    );
    oracle.setPrice(1021e17);
  }

  function test_absoluteDeviationOutsideLowerBound() public {
    // The price of chainlink instrument changes -2%.
    // The most the RWA price can ever change is -2%
    vm.warp(block.timestamp + oracle.MIN_PRICE_UPDATE_WINDOW() + 1);
    setNewChainlinkPrice(-200);
    vm.warp(block.timestamp + 2 hours);
    // RWA gets updated 2 hours after, (23 hours)
    vm.expectRevert(
      IRWAOracleExternalComparisonCheck
        .AbsoluteDifferenceConstraintViolated
        .selector
    );
    oracle.setPrice(979e17);
  }

  /// Test bypass scenarios ///
  function test_bypassCheckCLTooHigh() public {
    // 11 days have passed without a chainlink update
    vm.warp(block.timestamp + 11 days);
    // CL instrument price increases 275 bps,
    // This is more than MAX_ABSOLUTE_DIFF_BPS +
    // MAX_CHANGE_DIFF_BPS, so CL check is ignored.
    setNewChainlinkPrice(275);
    // The CL check is ignored, so we can set in any range
    // as defined by absolute constraint.
    oracle.setPrice(100e18);
    assertEq(100e18, oracle.rwaPrice());
  }

  function test_bypassCheckCLTooLow() public {
    // 11 days have passed without a chainlink update
    vm.warp(block.timestamp + 11 days);
    // An hour later, the oracle gets updated. (Same price)
    vm.warp(block.timestamp + 1 hours);
    int256 newPrice = setNewChainlinkPrice(-275);
    // The CL check is ignored, so we can set in any range
    // as defined by absolute constraint.
    vm.expectEmit(true, true, true, true);
    emit ChainlinkPriceIgnored(
      INITIAL_CL_PRICE,
      currentRoundId - 2,
      newPrice,
      currentRoundId - 1
    );
    oracle.setPrice(100e18);
    assertEq(100e18, oracle.rwaPrice());
    assertEq(block.timestamp, oracle.priceTimestamp());
  }

  function test_bypassCheckCLUpperBound() public {
    // 11 days have passed without a chainlink update
    vm.warp(block.timestamp + 11 days);
    // An hour later, the oracle gets updated. (Same price)
    vm.warp(block.timestamp + 1 hours);
    setNewChainlinkPrice(274);

    vm.expectEmit(true, true, true, true);
    emit RWAExternalComparisonCheckPriceSet(
      INITIAL_CL_PRICE,
      currentRoundId - 2,
      10274e7,
      currentRoundId - 1,
      INITIAL_RWA_PRICE,
      102e18
    );
    // The only allowable value is +200 bps because CL price is not
    // ignored
    oracle.setPrice(102e18);
  }

  function test_bypassCheckCLUpperBoundFailure() public {
    // 11 days have passed without a chainlink update
    vm.warp(block.timestamp + 11 days);
    setNewChainlinkPrice(274);

    vm.expectRevert(
      IRWAOracleExternalComparisonCheck
        .DeltaDifferenceConstraintViolation
        .selector
    );
    // The only allowable value is +200 bps because CL price is not
    // ignored
    oracle.setPrice(10199e16);
  }

  function test_bypassCheckCLLowerBound() public {
    // 11 days have passed without a chainlink update
    vm.warp(block.timestamp + 11 days);
    setNewChainlinkPrice(-274);
    vm.expectEmit(true, true, true, true);
    emit RWAExternalComparisonCheckPriceSet(
      INITIAL_CL_PRICE,
      currentRoundId - 2,
      9726e7,
      currentRoundId - 1,
      INITIAL_RWA_PRICE,
      98e18
    );
    // The only allowable value is -200 bps because CL price is not
    // ignored
    oracle.setPrice(98e18);
  }

  function test_bypassCheckCLLowerBoundFailure() public {
    // 11 days have passed without a chainlink update
    vm.warp(block.timestamp + 11 days);
    setNewChainlinkPrice(-274);

    vm.expectRevert(
      IRWAOracleExternalComparisonCheck
        .DeltaDifferenceConstraintViolation
        .selector
    );
    // The only allowable value is -200 bps because CL price is not
    // ignored
    oracle.setPrice(9801e16);
  }

  function test_pricesInDifferentDirectionsCLDown() public {
    vm.warp(block.timestamp + oracle.MIN_PRICE_UPDATE_WINDOW() + 1);
    // CL Price goes down 60 bps
    setNewChainlinkPrice(-60);
    vm.warp(block.timestamp + 2 hours);
    // Since limit is 74 bps, RWA Price can go up 14 bps
    oracle.setPrice(10014e16);
    assertEq(10014e16, oracle.rwaPrice());
  }

  function test_pricesInDifferentDirectionsCLUp() public {
    vm.warp(block.timestamp + oracle.MIN_PRICE_UPDATE_WINDOW() + 1);
    // CL Price goes up 60 bps
    setNewChainlinkPrice(60);
    vm.warp(block.timestamp + 2 hours);
    // Since limit is 100 bps, RWA Price can down -14 bps
    oracle.setPrice(9986e16);
    assertEq(9986e16, oracle.rwaPrice());
  }
}
