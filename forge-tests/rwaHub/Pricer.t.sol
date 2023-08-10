pragma solidity 0.8.16;

import "contracts/Pricer.sol";
import "forge-tests/MinimalTestRunner.sol";

contract Test_Pricer is MinimalTestRunner {
  Pricer public pricer;
  uint256 constant initialPrice = 1e18;
  uint256 constant newPrice = 2e18;

  function setUp() public {
    // Deploy pricer
    pricer = new Pricer(
      address(this), // Admin
      address(this) // Pricer
    );
  }

  function test_initialization() public {
    assertEq(pricer.hasRole(pricer.DEFAULT_ADMIN_ROLE(), address(this)), true);
    assertEq(pricer.hasRole(pricer.PRICE_UPDATE_ROLE(), address(this)), true);
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

  function test_addPrice() public {
    vm.expectEmit(true, true, true, true);
    emit PriceAdded(1, initialPrice, block.timestamp);
    pricer.addPrice(initialPrice, block.timestamp);

    // Checks
    assertEq(pricer.priceIds(0), 1);
    assertEq(pricer.currentPriceId(), 1);
    (uint256 price, uint256 timestamp) = pricer.prices(1);
    assertEq(price, initialPrice);
    assertEq(timestamp, block.timestamp);
    assertEq(pricer.latestPriceId(), 1);
  }

  function test_addPrice_multiple() public {
    pricer.addPrice(initialPrice, block.timestamp);
    vm.warp(block.timestamp + 2 hours);

    vm.expectEmit(true, true, true, true);
    emit PriceAdded(2, newPrice, block.timestamp);
    pricer.addPrice(newPrice, block.timestamp);

    // Checks
    assertEq(pricer.priceIds(1), 2);
    assertEq(pricer.currentPriceId(), 2);
    (uint256 price, uint256 timestamp) = pricer.prices(2);
    assertEq(price, newPrice);
    assertEq(timestamp, block.timestamp);
    assertEq(pricer.latestPriceId(), 2);
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
    pricer.addPrice(initialPrice, block.timestamp);

    // Get old data and update price
    (uint256 _initialPrice, uint256 initialPriceTimestamp) = pricer.prices(1);
    uint256 updatedPrice = _initialPrice + 1;
    vm.expectEmit(true, true, true, true);
    emit PriceUpdated(1, _initialPrice, updatedPrice);
    pricer.updatePrice(1, updatedPrice);

    // Check State
    assertEq(pricer.priceIds(0), 1); // PriceId array doesn't change
    assertEq(pricer.latestPriceId(), 1); // Latest price doesn't change
    (uint256 pricerUpdatedPrice, uint256 pricerUpdatedTimestamp) = pricer
      .prices(1);
    assertEq(pricerUpdatedPrice, updatedPrice);
    assertEq(pricerUpdatedTimestamp, initialPriceTimestamp);
  }

  // Helper Events
  event PriceAdded(uint256 indexed priceId, uint256 price, uint256 timestamp);
  event PriceUpdated(
    uint256 indexed priceId,
    uint256 oldPrice,
    uint256 newPrice
  );
}
