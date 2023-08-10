pragma solidity 0.8.16;

import "contracts/rwaOracles/RWAOracleRateCheck.sol";
import "forge-tests/MinimalTestRunner.sol";

contract Test_RWAOracleRateCheck is MinimalTestRunner {
  RWAOracleRateCheck rwaOracle;

  function setUp() public {
    rwaOracle = new RWAOracleRateCheck(address(this), address(this), 100e18);
  }

  function test_constrainedSetter_initialization() public {
    vm.expectEmit(true, true, true, true);
    emit RWAPriceSet(0, 100e18, block.timestamp);
    rwaOracle = new RWAOracleRateCheck(address(this), address(this), 100e18);
    assertEq(rwaOracle.rwaPrice(), 100e18);
    assertEq(rwaOracle.priceTimestamp(), block.timestamp);
  }

  function test_constrainedSetter_accessControl() public {
    assertEq(rwaOracle.getRoleMemberCount(rwaOracle.DEFAULT_ADMIN_ROLE()), 1);
    assertEq(
      rwaOracle.getRoleMember(rwaOracle.DEFAULT_ADMIN_ROLE(), 0),
      address(this)
    );
    assertEq(rwaOracle.getRoleMemberCount(rwaOracle.SETTER_ROLE()), 1);
    assertEq(
      rwaOracle.getRoleMember(rwaOracle.SETTER_ROLE(), 0),
      address(this)
    );
  }

  function test_constrainedSetter_fail_initialization() public {
    vm.expectRevert(RWAOracleRateCheck.InvalidPrice.selector);
    RWAOracleRateCheck badSetter = new RWAOracleRateCheck(
      address(this),
      address(this),
      0
    );
  }

  function test_constrainedSetter_setPrice_fail_accessControl() public {
    vm.expectRevert(_formatACRevert(alice, rwaOracle.SETTER_ROLE()));
    vm.prank(alice);
    rwaOracle.setPrice(100e18);
  }

  function test_constrainedSetter_setPrice_fail_negative() public {
    vm.expectRevert(RWAOracleRateCheck.InvalidPrice.selector);
    rwaOracle.setPrice(-1);
  }

  function test_constrainedSetter_setPrice_fail_zeroPrice() public {
    vm.expectRevert(RWAOracleRateCheck.InvalidPrice.selector);
    rwaOracle.setPrice(0);
  }

  function test_constrainedSetter_setPrice_fail_tooSoon() public {
    vm.expectRevert(RWAOracleRateCheck.PriceUpdateWindowViolation.selector);
    rwaOracle.setPrice(100e18);
  }

  function test_constrainedSetter_setPrice_fail_tooLarge() public {
    vm.warp(block.timestamp + rwaOracle.MIN_PRICE_UPDATE_WINDOW());
    vm.expectRevert(
      RWAOracleRateCheck.DeltaDifferenceConstraintViolation.selector
    );
    rwaOracle.setPrice(102e18);
  }

  function test_constrainedSetter_setPrice_fail_tooSmall() public {
    vm.warp(block.timestamp + rwaOracle.MIN_PRICE_UPDATE_WINDOW());
    vm.expectRevert(
      RWAOracleRateCheck.DeltaDifferenceConstraintViolation.selector
    );
    rwaOracle.setPrice(98e18);
  }

  function test_constrainedSetter_setPrice() public {
    vm.warp(block.timestamp + rwaOracle.MIN_PRICE_UPDATE_WINDOW());
    vm.expectEmit(true, true, true, true);
    emit RWAPriceSet(100e18, 1005e17, block.timestamp);
    rwaOracle.setPrice(1005e17); // 100.5
    assertEq(rwaOracle.rwaPrice(), 1005e17);
    assertEq(rwaOracle.priceTimestamp(), block.timestamp);
  }

  function test_constrainedSetter_maxDeviationPositive() public {
    vm.warp(block.timestamp + rwaOracle.MIN_PRICE_UPDATE_WINDOW());
    rwaOracle.setPrice(101e18);
    assertEq(rwaOracle.rwaPrice(), 101e18);
  }

  function test_constrainedSetter_maxDeviationNegative() public {
    vm.warp(block.timestamp + rwaOracle.MIN_PRICE_UPDATE_WINDOW());
    rwaOracle.setPrice(99e18);
    assertEq(rwaOracle.rwaPrice(), 99e18);
  }

  function test_constrainedSetter_getPriceData() public {
    test_constrainedSetter_setPrice();
    (uint256 price, uint256 timestamp) = rwaOracle.getPriceData();
    assertEq(price, 1005e17);
    assertEq(timestamp, block.timestamp);
  }

  function test_constrainedSetter_fuzz_multipleUpdates(uint256 salt) public {
    uint256 minimumUpdateWindow = rwaOracle.MIN_PRICE_UPDATE_WINDOW();
    int256 maxPriceDeviation = int256(rwaOracle.MAX_CHANGE_DIFF_BPS());
    for (uint256 i = 0; i < 100; i++) {
      vm.warp(block.timestamp + minimumUpdateWindow);
      bool increasePrice = (salt >> i) & 1 == 1 ? true : false;
      int256 oldPrice = rwaOracle.rwaPrice();
      int256 diff = (oldPrice * maxPriceDeviation) / 10000;
      if (increasePrice) {
        rwaOracle.setPrice(oldPrice + diff);
        assertEq(rwaOracle.rwaPrice(), oldPrice + diff);
      } else {
        rwaOracle.setPrice(oldPrice - diff);
        assertEq(rwaOracle.rwaPrice(), oldPrice - diff);
      }
    }
  }

  function test_constrainedSetter_roundUp() public {
    // Initial price is 100e18
    // New price is 101.005e18 -> -100.5 bps difference, should round up to -101
    vm.warp(block.timestamp + rwaOracle.MIN_PRICE_UPDATE_WINDOW());
    vm.expectRevert(
      RWAOracleRateCheck.DeltaDifferenceConstraintViolation.selector
    );
    rwaOracle.setPrice(101.005e18);
  }

  // Events
  event RWAPriceSet(int256 oldPrice, int256 newPrice, uint256 timestamp);
}
