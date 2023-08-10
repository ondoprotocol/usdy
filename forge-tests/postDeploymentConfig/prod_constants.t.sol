pragma solidity 0.8.16;

contract PROD_CONSTANTS_USDY {
  // usdyHub Role members
  address public usdyhub_default_admin =
    0x1a694A09494E214a3Be3652e4B343B7B81A73ad7;
  address public usdyhum_manager_admin =
    0x1a694A09494E214a3Be3652e4B343B7B81A73ad7;
  address public usdyhub_pauser_admin =
    0x2e55b738F5969Eea10fB67e326BEE5e2fA15A2CC;
  address public usdyhub_price_id_setter_role =
    0x1a694A09494E214a3Be3652e4B343B7B81A73ad7;
  address public usdyhub_relayer_role =
    0x1a694A09494E214a3Be3652e4B343B7B81A73ad7;
  address public usdyhub_timestamp_setter_role =
    0x1a694A09494E214a3Be3652e4B343B7B81A73ad7;

  address public asset_sender = 0x5Eb3ac7D9B8220C484307a2506D611Cc759626Ca;
  address public asset_recipient = 0xbDa73A0F13958ee444e0782E1768aB4B76EdaE28;
  address public fee_recipient = 0x1a694A09494E214a3Be3652e4B343B7B81A73ad7;
  address public usdy_asset = 0x96F6eF951840721AdBF46Ac996b59E0235CB985C;
  address public usdy_pricer = 0x7fb0228c6338da4EC948Df7b6a8E22aD2Bb2bfB5;
  uint256 public min_deposit_amt = 500e6;
  uint256 public min_redeem_amt = 500e18;
  uint256 public mint_fee = 0;
  uint256 public redeem_fee = 0;
  address public collateral = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
  uint256 public decimals_multiplier = 10 ** 12;
  uint256 public bps_denominator = 10_000;
  bool public instant_minting_paused = true;

  address public block_list = 0xd8c8174691d936E2C80114EC449037b13421B0a8;
  address public sanctions_list = 0x40C57923924B5c5c5455c48D93317139ADDaC8fb;

  // usdy Token proxy
  address public usdy_proxy_admin_address =
    0x3eD61633057da0Bc58F84b2B9002845E56f94c19;
  bytes32 public usdy_proxy_admin_bytes =
    bytes32(uint256(uint160(usdy_proxy_admin_address)));
  address public usdy_impl_address = 0xea0F7EEbDc2Ae40edFE33bf03D332F8A7f617528;
  bytes32 public usdy_impl_bytes = bytes32(uint256(uint160(usdy_impl_address)));

  // USDY
  uint256 public decimals = 18;
  bool public paused = false;
  address public usdy_allowlist = 0x13300511f43768a30bb2bf10b63B6d502D1F7FE5;
  address public usdy_blocklist = 0xd8c8174691d936E2C80114EC449037b13421B0a8;
  address public usdy_sanctionslist =
    0x40C57923924B5c5c5455c48D93317139ADDaC8fb;
  string public name = "Ondo U.S. Dollar Yield";
  string public symbol = "USDY";

  address public usdy_default_admin =
    0x1a694A09494E214a3Be3652e4B343B7B81A73ad7;
  address public usdy_minter_role = 0x25A103A1D6AeC5967c1A4fe2039cdc514886b97e;
  address public usdy_pauser_role = 0x2e55b738F5969Eea10fB67e326BEE5e2fA15A2CC;
  address public usdy_burner_role = 0x2626fB9dEbd067B05659A0303dB498B1382593f2;
  address public usdy_list_config_role =
    0x1a694A09494E214a3Be3652e4B343B7B81A73ad7;

  // PA Owner USDY
  address public usdy_pa_owner = 0x1a694A09494E214a3Be3652e4B343B7B81A73ad7;

  // allowlist proxy
  address public allow_proxy_admin_address =
    0xeAa659DC72B39c164cA61B3570044Fd0dcC160Db;
  bytes32 public allow_proxy_admin_bytes =
    bytes32(uint256(uint160(allow_proxy_admin_address)));
  address public allow_impl_address =
    0x196a4cd6c6A1441A46C5D884DE148Fe6e1E950F7;
  bytes32 public allow_impl_bytes =
    bytes32(uint256(uint160(allow_impl_address)));

  // allowlist
  address public allow_default_admin =
    0x1a694A09494E214a3Be3652e4B343B7B81A73ad7;
  address public allow_allowlist_admin =
    0x1a694A09494E214a3Be3652e4B343B7B81A73ad7;
  address public allow_allowlist_setter =
    0x1a694A09494E214a3Be3652e4B343B7B81A73ad7;

  // PA Owner Allowlist
  address public allow_pa_owner = 0x1a694A09494E214a3Be3652e4B343B7B81A73ad7;

  // Blocklist
  address public block_owner = 0x1a694A09494E214a3Be3652e4B343B7B81A73ad7;

  // Pricer
  address public pricer_default_admin =
    0x1a694A09494E214a3Be3652e4B343B7B81A73ad7;
  address public pricer_price_update_role =
    0x1a694A09494E214a3Be3652e4B343B7B81A73ad7;
}
