pragma solidity 0.8.16;

import {PROD_CONSTANTS_USDY} from "forge-tests/postDeploymentConfig/prod_constants.t.sol";
import "forge-tests/USDY_BasicDeployment.sol";

contract ASSERT_FORK_USDY_PROD is PROD_CONSTANTS_USDY, USDY_BasicDeployment {
  /**
   * @notice INPUT ADDRESSES TO CHECK CONFIG OF BELOW
   *
   * USDY Deployment: 7/11/23
   * Passing on block: 17673284
   */
  address usdy_to_check = 0x96F6eF951840721AdBF46Ac996b59E0235CB985C;
  address usdyManager_to_check = 0x25A103A1D6AeC5967c1A4fe2039cdc514886b97e;

  bytes32 impl_slot =
    bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1);
  bytes32 admin_slot = bytes32(uint256(keccak256("eip1967.proxy.admin")) - 1);

  function setUp() public override {
    usdy = USDY(usdy_to_check);
    allowlist = AllowlistUpgradeable(address(usdy.allowlist()));
    blocklist = Blocklist(address(usdy.blocklist()));
    sanctionsList = ISanctionsList(usdy.sanctionsList());

    usdyManager = USDYManager(usdyManager_to_check);
    pricerUSDY = Pricer(address(usdyManager.pricer()));
  }

  function test_print_block() public view {
    console.log("The Current Block #: ", block.number);
  }

  function test_fork_assert_usdy_manager() public {
    /**
     * Check USDY Manager
     * 1) Assert Role member count
     * 2) Assert Role
     */
    assertEq(
      usdyManager.getRoleMemberCount(usdyManager.DEFAULT_ADMIN_ROLE()),
      1
    );
    assertEq(
      usdyManager.getRoleMember(usdyManager.DEFAULT_ADMIN_ROLE(), 0),
      PROD_CONSTANTS_USDY.usdyhub_default_admin
    );
    assertEq(usdyManager.getRoleMemberCount(usdyManager.MANAGER_ADMIN()), 1);
    assertEq(
      usdyManager.getRoleMember(usdyManager.MANAGER_ADMIN(), 0),
      PROD_CONSTANTS_USDY.usdyhum_manager_admin
    );
    assertEq(usdyManager.getRoleMemberCount(usdyManager.PAUSER_ADMIN()), 1);
    assertEq(
      usdyManager.getRoleMember(usdyManager.PAUSER_ADMIN(), 0),
      PROD_CONSTANTS_USDY.usdyhub_pauser_admin
    );

    assertEq(
      usdyManager.getRoleMemberCount(usdyManager.PRICE_ID_SETTER_ROLE()),
      1
    );
    assertEq(
      usdyManager.getRoleMember(usdyManager.PRICE_ID_SETTER_ROLE(), 0),
      PROD_CONSTANTS_USDY.usdyhub_price_id_setter_role
    );

    assertEq(usdyManager.getRoleMemberCount(usdyManager.RELAYER_ROLE()), 1);
    assertEq(
      usdyManager.getRoleMember(usdyManager.RELAYER_ROLE(), 0),
      PROD_CONSTANTS_USDY.usdyhub_relayer_role
    );
    // USDY specific role
    assertEq(
      usdyManager.getRoleMemberCount(usdyManager.TIMESTAMP_SETTER_ROLE()),
      1
    );
    assertEq(
      usdyManager.getRoleMember(usdyManager.TIMESTAMP_SETTER_ROLE(), 0),
      PROD_CONSTANTS_USDY.usdyhub_timestamp_setter_role
    );

    // // ASSERT USDY Manager config
    assertEq(usdyManager.assetSender(), PROD_CONSTANTS_USDY.asset_sender);
    assertEq(usdyManager.assetRecipient(), PROD_CONSTANTS_USDY.asset_recipient);
    assertEq(usdyManager.feeRecipient(), PROD_CONSTANTS_USDY.fee_recipient);
    assertEq(address(usdyManager.rwa()), PROD_CONSTANTS_USDY.usdy_asset);
    assertEq(address(usdyManager.collateral()), PROD_CONSTANTS_USDY.collateral);
    assertEq(address(usdyManager.pricer()), PROD_CONSTANTS_USDY.usdy_pricer);
    assertEq(
      usdyManager.minimumDepositAmount(),
      PROD_CONSTANTS_USDY.min_deposit_amt
    );
    assertEq(
      usdyManager.minimumRedemptionAmount(),
      PROD_CONSTANTS_USDY.min_redeem_amt
    );
    assertEq(usdyManager.mintFee(), PROD_CONSTANTS_USDY.mint_fee);
    assertEq(usdyManager.redemptionFee(), PROD_CONSTANTS_USDY.redeem_fee);
    assertEq(
      usdyManager.BPS_DENOMINATOR(),
      PROD_CONSTANTS_USDY.bps_denominator
    );
    assertEq(address(usdyManager.blocklist()), PROD_CONSTANTS_USDY.block_list);
    assertEq(
      address(usdyManager.sanctionsList()),
      PROD_CONSTANTS_USDY.sanctions_list
    );
    assertEq(
      usdyManager.decimalsMultiplier(),
      PROD_CONSTANTS_USDY.decimals_multiplier
    );
  }

  function test_fork_assert_usdy_token_proxy() public {
    // Assert Proxy Setup
    bytes32 impl = vm.load(address(usdy), impl_slot);
    bytes32 admin = vm.load(address(usdy), admin_slot);
    assertEq(impl, PROD_CONSTANTS_USDY.usdy_impl_bytes);
    assertEq(admin, PROD_CONSTANTS_USDY.usdy_proxy_admin_bytes);

    // Assert that the owner of the proxy admin is correct
    assertEq(
      ProxyAdmin(address(uint160(uint256(admin)))).owner(),
      PROD_CONSTANTS_USDY.usdy_pa_owner
    );

    /**
     * Assert Token Roles
     * 1) Assert Role count
     * 2) Assert Role membership
     */
    assertEq(usdy.getRoleMemberCount(usdy.DEFAULT_ADMIN_ROLE()), 1);
    assertEq(
      usdy.getRoleMember(usdy.DEFAULT_ADMIN_ROLE(), 0),
      PROD_CONSTANTS_USDY.usdy_default_admin
    );
    assertEq(usdy.getRoleMemberCount(usdy.MINTER_ROLE()), 1);
    assertEq(
      usdy.getRoleMember(usdy.MINTER_ROLE(), 0),
      PROD_CONSTANTS_USDY.usdy_minter_role
    );

    assertEq(usdy.getRoleMemberCount(usdy.PAUSER_ROLE()), 2);
    assertEq(
      usdy.getRoleMember(usdy.PAUSER_ROLE(), 0),
      PROD_CONSTANTS_USDY.usdy_default_admin
    );
    assertEq(
      usdy.getRoleMember(usdy.PAUSER_ROLE(), 1),
      PROD_CONSTANTS_USDY.usdy_pauser_role
    );

    /// @notice BURNER_ROLE - Not granted by default
    // assertEq(usdy.getRoleMemberCount(usdy.BURNER_ROLE()), 1);
    // assertEq(
    //   usdy.getRoleMember(usdy.BURNER_ROLE(), 0),
    //   PROD_CONSTANTS_USDY.usdy_pauser_role
    // );

    assertEq(usdy.getRoleMemberCount(usdy.LIST_CONFIGURER_ROLE()), 1);
    assertEq(
      usdy.getRoleMember(usdy.LIST_CONFIGURER_ROLE(), 0),
      PROD_CONSTANTS_USDY.usdy_list_config_role
    );

    // Assert Token config
    assertEq(address(usdy.allowlist()), PROD_CONSTANTS_USDY.usdy_allowlist);
    assertEq(address(usdy.blocklist()), PROD_CONSTANTS_USDY.usdy_blocklist);
    assertEq(
      address(usdy.sanctionsList()),
      PROD_CONSTANTS_USDY.usdy_sanctionslist
    );
    assertEq(usdy.paused(), PROD_CONSTANTS_USDY.paused);
    assertEq(usdy.decimals(), PROD_CONSTANTS_USDY.decimals);
    assertEq(usdy.name(), PROD_CONSTANTS_USDY.name);
    assertEq(usdy.symbol(), PROD_CONSTANTS_USDY.symbol);
  }

  function test_fork_assert_usdy_allowlist_proxy() public {
    // Assert Proxy setup
    bytes32 impl = vm.load(address(allowlist), impl_slot);
    bytes32 admin = vm.load(address(allowlist), admin_slot);
    assertEq(impl, PROD_CONSTANTS_USDY.allow_impl_bytes);
    assertEq(admin, PROD_CONSTANTS_USDY.allow_proxy_admin_bytes);

    // Assert that the owner of the proxy admin is correct
    assertEq(
      ProxyAdmin(address(uint160(uint256(admin)))).owner(),
      PROD_CONSTANTS_USDY.allow_pa_owner
    );

    /**
     * Assert Token Roles
     * 1) Assert Role count
     * 2) Assert Role membership
     */
    assertEq(allowlist.getRoleMemberCount(allowlist.DEFAULT_ADMIN_ROLE()), 1);
    assertEq(
      allowlist.getRoleMember(allowlist.DEFAULT_ADMIN_ROLE(), 0),
      PROD_CONSTANTS_USDY.allow_default_admin
    );
    assertEq(allowlist.getRoleMemberCount(allowlist.ALLOWLIST_ADMIN()), 1);
    assertEq(
      allowlist.getRoleMember(allowlist.ALLOWLIST_ADMIN(), 0),
      PROD_CONSTANTS_USDY.allow_allowlist_admin
    );
    assertEq(allowlist.getRoleMemberCount(allowlist.ALLOWLIST_SETTER()), 1);
    assertEq(
      allowlist.getRoleMember(allowlist.ALLOWLIST_SETTER(), 0),
      PROD_CONSTANTS_USDY.allow_allowlist_setter
    );
  }

  function test_fork_assert_blocklist() public {
    assertEq(blocklist.owner(), PROD_CONSTANTS_USDY.block_owner);
  }

  function test_fork_assert_pricer() public {
    assertEq(pricerUSDY.getRoleMemberCount(pricerUSDY.DEFAULT_ADMIN_ROLE()), 1);
    assertEq(
      pricerUSDY.getRoleMember(pricerUSDY.DEFAULT_ADMIN_ROLE(), 0),
      PROD_CONSTANTS_USDY.pricer_default_admin
    );
    assertEq(pricerUSDY.getRoleMemberCount(pricerUSDY.PRICE_UPDATE_ROLE()), 1);
    assertEq(
      pricerUSDY.getRoleMember(pricerUSDY.PRICE_UPDATE_ROLE(), 0),
      PROD_CONSTANTS_USDY.pricer_price_update_role
    );
  }
}
