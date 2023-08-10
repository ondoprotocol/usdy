pragma solidity 0.8.16;

import "contracts/PricerWithOracle.sol";
import "contracts/interfaces/IPricerWithOracle.sol";
import "contracts/rwaOracles/RWAOracleExternalComparisonCheck.sol";
import "forge-tests/helpers/MockChainlinkPriceOracle.sol";
import "forge-tests/MinimalTestRunner.sol";

contract Test_PricerWithOracle is MinimalTestRunner {
  PricerWithOracle public pricer;
  uint256 newPrice = 1020e17;
  int256 newPriceCL = 1010e8;

  // Oracle Info
  RWAOracleExternalComparisonCheck oracle;
  MockChainlinkPriceOracle mockChainlinkOracle;
  uint80 public currentRoundId = 1;
  int256 public constant INITIAL_CL_PRICE = 1000e8;
  int256 public constant INITIAL_RWA_PRICE = 100e18;
  int256 public constant BPS_DENOMINATOR = 10_000;

  function setUp() public {
    // Deploy Mock Chainlink and SHV Oracles
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

    // Deploy pricer
    pricer = new PricerWithOracle(
      address(this), // Admin
      address(this), // Pricer
      address(oracle)
    );

    oracle.grantRole(oracle.SETTER_ROLE(), address(pricer));
  }

  function setNewChainlinkPrice(int256 bps) private returns (int256) {
    (, int256 last_price, , , ) = mockChainlinkOracle.latestRoundData();
    int256 priceToSet = (last_price * (BPS_DENOMINATOR + bps)) /
      BPS_DENOMINATOR;
    mockChainlinkOracle.setRoundData(
      currentRoundId,
      priceToSet,
      block.timestamp - 1,
      block.timestamp,
      currentRoundId
    );
    ++currentRoundId;
    return priceToSet;
  }

  function test_initialization() public {
    // Check priceId array
    assertEq(pricer.priceIds(0), 1);
    assertEq(pricer.currentPriceId(), 1);

    // Check that priceId 1 is initialized properly
    assertEq(pricer.latestPriceId(), 1);
    (uint256 pricerInitialPrice, uint256 pricerInitialTimestamp) = pricer
      .prices(1);
    assertEq(pricerInitialPrice, uint256(INITIAL_RWA_PRICE));

    // Check that pricer price matches oracle price
    (uint256 oraclePrice, uint256 oracleTimestamp) = oracle.getPriceData();
    assertEq(pricerInitialPrice, oraclePrice);

    // Check that pricer latest timestmap matches oracle timestasmp
    assertEq(pricerInitialTimestamp, oracleTimestamp);
  }

  function test_addPrice_fail_accessControl() public {
    vm.expectRevert(_formatACRevert(alice, pricer.PRICE_UPDATE_ROLE()));
    vm.prank(alice);
    pricer.addPrice(100, block.timestamp);
  }

  function test_addPrice_fail_invalidPrice() public {
    vm.expectRevert(Pricer.InvalidPrice.selector);
    pricer.addPrice(0, block.timestamp);
  }

  function test_addPrice_fail_latestPriceMismatch() public {
    // Set a price in oracle
    vm.warp(block.timestamp + oracle.MIN_PRICE_UPDATE_WINDOW() + 1);
    setNewChainlinkPrice(200);
    vm.warp(block.timestamp + 2 hours);
    oracle.setPrice(1020e17);

    // Try to add a price in pricer
    vm.expectRevert(PricerWithOracle.LatestPriceMismatch.selector);
    pricer.addPrice(1020e17, block.timestamp);
  }

  function test_addPrice() public {
    // Set Chainlink data
    vm.warp(block.timestamp + oracle.MIN_PRICE_UPDATE_WINDOW() + 1);
    setNewChainlinkPrice(200);
    vm.warp(block.timestamp + 2 hours);

    vm.expectEmit(true, true, true, true);
    emit PriceAdded(2, newPrice, block.timestamp);
    pricer.addPrice(newPrice, block.timestamp);
  }

  function test_addPrice_checkPricerState() public {
    test_addPrice();
    assertEq(pricer.priceIds(1), 2);
    (uint256 price, uint256 timestamp) = pricer.prices(2);
    assertEq(price, newPrice);
    assertEq(timestamp, block.timestamp);
    assertEq(pricer.latestPriceId(), 2);
  }

  function test_addPrice_oracleUpdateAndSync() public {
    test_addPrice();
    assertEq(oracle.rwaPrice(), int256(newPrice));
    (uint256 oraclePrice, uint256 oraclePriceTimestamp) = oracle.getPriceData();
    assertEq(oraclePrice, pricer.getLatestPrice());
    (, uint256 latestPricerTimestamp) = pricer.prices(pricer.latestPriceId());
    assertEq(oraclePriceTimestamp, latestPricerTimestamp);
  }

  function test_updatePrice_fail_accessControl() public {
    vm.expectRevert(_formatACRevert(alice, pricer.PRICE_UPDATE_ROLE()));
    vm.prank(alice);
    pricer.updatePrice(1, newPrice);
  }

  function test_updatePrice_fail_invalidPrice() public {
    vm.expectRevert(Pricer.InvalidPrice.selector);
    pricer.updatePrice(1, 0);
  }

  function test_updatePrice_fail_priceIDExistence() public {
    vm.expectRevert(Pricer.PriceIdDoesNotExist.selector);
    pricer.updatePrice(2, newPrice);
  }

  function test_updatePrice() public {
    // Add price to pricer
    test_addPrice();

    // Get old data and update price
    (uint256 initialPrice, uint256 initialPriceTimestamp) = pricer.prices(2);
    uint256 updatedPrice = initialPrice + 1;
    vm.expectEmit(true, true, true, true);
    emit PriceUpdated(2, initialPrice, updatedPrice);
    pricer.updatePrice(2, updatedPrice);

    // Check State
    assertEq(pricer.priceIds(1), 2); // PriceId array doesn't change
    assertEq(pricer.latestPriceId(), 2); // Latest price doesn't change
    (uint256 pricerUpdatedPrice, uint256 pricerUpdatedTimestamp) = pricer
      .prices(2);
    assertEq(pricerUpdatedPrice, updatedPrice);
    assertEq(pricerUpdatedTimestamp, initialPriceTimestamp);
  }

  function test_addLatestOraclePrice_fail_accessControl() public {
    vm.expectRevert(_formatACRevert(alice, pricer.PRICE_UPDATE_ROLE()));
    vm.prank(alice);
    pricer.addLatestOraclePrice();
  }

  function test_addLatestOraclePrice_fail_matchedPrices() public {
    // Add a price to pricer and oracle
    test_addPrice();

    vm.expectRevert(PricerWithOracle.PricesAlreadyMatch.selector);
    pricer.addLatestOraclePrice();
  }

  function test_addLatestOraclePrice1() public {
    // Set Chainlink data & oracle price
    vm.warp(block.timestamp + oracle.MIN_PRICE_UPDATE_WINDOW() + 1);
    setNewChainlinkPrice(200);
    vm.warp(block.timestamp + 1 hours);

    oracle.setPrice(int256(newPrice));
    (uint256 latestOraclePrice, uint256 latestOracleTimestamp) = oracle
      .getPriceData();

    // Expect revert if you try to add a price to pricer
    vm.expectRevert(PricerWithOracle.LatestPriceMismatch.selector);
    pricer.addPrice(newPrice, block.timestamp);

    // Add latest oracle price by catching up
    vm.expectEmit(true, true, true, true);
    emit PriceAdded(2, newPrice, latestOracleTimestamp);
    pricer.addLatestOraclePrice();

    // Check state
    assertEq(pricer.latestPriceId(), 2);
    assertEq(pricer.priceIds(1), 2);
    (uint256 price, uint256 timestamp) = pricer.prices(2);
    assertEq(price, latestOraclePrice);
    assertEq(timestamp, latestOracleTimestamp);
  }

  function test_addLatestOraclePrice_postAddPrice() public {
    // Catch up pricer to oracle, now on priceId 2
    test_addLatestOraclePrice1();

    // Update oracle price
    vm.warp(block.timestamp + oracle.MIN_PRICE_UPDATE_WINDOW() + 1);
    setNewChainlinkPrice(200);
    vm.warp(block.timestamp + 1 hours);

    // Update price in pricer
    uint256 updatedPrice = 1040e17;
    pricer.addPrice(updatedPrice, block.timestamp);

    // Check state
    assertEq(pricer.latestPriceId(), 3);
    assertEq(pricer.priceIds(2), 3);
    (uint256 price, uint256 timestamp) = pricer.prices(3);
    assertEq(price, updatedPrice);
    (uint256 latestOraclePrice, uint256 latestOracleTimestamp) = oracle
      .getPriceData();
    assertEq(timestamp, latestOracleTimestamp);
    assertEq(price, latestOraclePrice);
  }

  // Helper Events
  event PriceAdded(uint256 indexed priceId, uint256 price, uint256 timestamp);
  event PriceUpdated(
    uint256 indexed priceId,
    uint256 oldPrice,
    uint256 newPrice
  );
}
