import { keccak256 } from "ethers/lib/utils";

// USDY
const USDY_PROXY_ADDRESS = "0x96F6eF951840721AdBF46Ac996b59E0235CB985C";
const USDY_IMPL_ADDRESS = "0xea0F7EEbDc2Ae40edFE33bf03D332F8A7f617528";
const USDY_PROXY_ADMIN_ADDRESS = "0x3eD61633057da0Bc58F84b2B9002845E56f94c19";
const USDY_MANAGER_ADDRESS = "0x25A103A1D6AeC5967c1A4fe2039cdc514886b97e";
const SANCTIONS_LIST_ADDRESS = "0x40C57923924B5c5c5455c48D93317139ADDaC8fb";
const USDY_PRICER_ADDRESS = "0x7fb0228c6338da4EC948Df7b6a8E22aD2Bb2bfB5";
// Blocklist
const BLOCKLIST_ADDRESS = "0xd8c8174691d936E2C80114EC449037b13421B0a8";

// Allowlist
const ALLOWLIST_PROXY_ADDRESS = "0x13300511f43768a30bb2bf10b63B6d502D1F7FE5";
const ALLOWLIST_IMPL_ADDRESS = "0x196a4cd6c6A1441A46C5D884DE148Fe6e1E950F7";
const ALLOWLIST_PROXY_ADMIN = "0xeAa659DC72B39c164cA61B3570044Fd0dcC160Db";

// Oracle
const USDY_RWA_ORACLE_RATE_CHECK_ADDRESS = "";
const USDY_INITIAL_PRICE = "1000000000000000000";
const MIN_PRICE_UPDATE_WINDOW_RATE_CHECK = "82800";
const MAX_CHANGE_DIFF_BPS_RATE_CHECK = "100";

// Constants
const ZERO_ADDRESS = "0x0000000000000000000000000000000000000000";
const ZERO_ROLE =
  "0x0000000000000000000000000000000000000000000000000000000000000000";

// External Addresses
const USDY_MULTISIG = "0x1a694A09494E214a3Be3652e4B343B7B81A73ad7";
const PAUSER = "0x2e55b738F5969Eea10fB67e326BEE5e2fA15A2CC";
const USDC_ADDRESS = "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48";
const USDY_MANAGER_ASSET_SENDER = "0x5Eb3ac7D9B8220C484307a2506D611Cc759626Ca";
const USDY_MANAGER_ASSET_RECIPIENT =
  "0xbDa73A0F13958ee444e0782E1768aB4B76EdaE28";

const usdy_config = {
  usdy: {
    usdyProxyAddress: USDY_PROXY_ADDRESS,
    usdyProxy: {
      proxyAdmin: USDY_PROXY_ADMIN_ADDRESS,
      rollback: ZERO_ADDRESS,
      beacon: ZERO_ADDRESS,
      implementation: USDY_IMPL_ADDRESS,
      DEFAULT_ADMIN_ROLE: ZERO_ROLE,
      BURNER_ROLE: keccak256(Buffer.from("BURNER_ROLE", "utf-8")),
      LIST_CONFIGURER_ROLE: keccak256(
        Buffer.from("LIST_CONFIGURER_ROLE", "utf-8")
      ),
      MINTER_ROLE: keccak256(Buffer.from("MINTER_ROLE", "utf-8")),
      PAUSER_ROLE: keccak256(Buffer.from("PAUSER_ROLE", "utf-8")),
      implementationStorage: {
        DEFAULT_ADMIN_ROLE: ZERO_ROLE,
        BURNER_ROLE: keccak256(Buffer.from("BURNER_ROLE", "utf-8")),
        LIST_CONFIGURER_ROLE: keccak256(
          Buffer.from("LIST_CONFIGURER_ROLE", "utf-8")
        ),
        MINTER_ROLE: keccak256(Buffer.from("MINTER_ROLE", "utf-8")),
        PAUSER_ROLE: keccak256(Buffer.from("PAUSER_ROLE", "utf-8")),
        decimals: 18,
        allowlist: ALLOWLIST_PROXY_ADDRESS,
        blocklist: BLOCKLIST_ADDRESS,
        sanctionsList: SANCTIONS_LIST_ADDRESS,
        name: "Ondo U.S. Dollar Yield",
        paused: false,
        symbol: "USDY",
      },
    },
    usdyProxyRoleMembers: {
      defaultAdminRoleMembers: [USDY_MULTISIG],
      burnerRoleMembers: [],
      listConfigurerRoleMembers: [USDY_MULTISIG],
      minterRoleMembers: [USDY_MANAGER_ADDRESS],
      pauserRoleMembers: [USDY_MULTISIG, PAUSER],
    },
    usdyProxyAdmin: {
      getProxyAdmin: USDY_PROXY_ADMIN_ADDRESS,
      getProxyImplementation: USDY_IMPL_ADDRESS,
      owner: USDY_MULTISIG,
    },
  },
  allowlist: {
    allowlistProxyAddress: ALLOWLIST_PROXY_ADDRESS,
    allowlistProxy: {
      proxyAdmin: ALLOWLIST_PROXY_ADMIN,
      rollback: ZERO_ADDRESS,
      beacon: ZERO_ADDRESS,
      implementation: ALLOWLIST_IMPL_ADDRESS,
      DEFAULT_ADMIN_ROLE: ZERO_ROLE,
      ALLOWLIST_SETTER: keccak256(Buffer.from("ALLOWLIST_SETTER", "utf-8")),
      ALLOWLIST_ADMIN: keccak256(Buffer.from("ALLOWLIST_ADMIN", "utf-8")),
      implementationStorage: {
        DEFAULT_ADMIN_ROLE: ZERO_ROLE,
        ALLOWLIST_SETTER: keccak256(Buffer.from("ALLOWLIST_SETTER", "utf-8")),
        ALLOWLIST_ADMIN: keccak256(Buffer.from("ALLOWLIST_ADMIN", "utf-8")),
        currentTermIndex: 0,
      },
    },
    allowlistRoleMembers: {
      defaultAdminRoleMembers: [USDY_MULTISIG],
      allowlistSetterRoleMembers: [USDY_MULTISIG],
      allowlistAdminRoleMembers: [USDY_MULTISIG],
    },
    allowlistProxyAdmin: {
      getProxyAdmin: ALLOWLIST_PROXY_ADMIN,
      getProxyImplementation: ALLOWLIST_IMPL_ADDRESS,
      owner: USDY_MULTISIG,
    },
  },
  blocklist: {
    blocklistAddress: BLOCKLIST_ADDRESS,
    storage: {
      name: "Ondo Finance Blocklist Oracle",
      owner: USDY_MULTISIG,
    },
  },
  usdyManager: {
    usdyManagerAddress: USDY_MANAGER_ADDRESS,
    storage: {
      BPS_DENOMINATOR: "10000",
      DEFAULT_ADMIN_ROLE: ZERO_ROLE,
      MANAGER_ADMIN: keccak256(Buffer.from("MANAGER_ADMIN", "utf-8")),
      PAUSER_ADMIN: keccak256(Buffer.from("PAUSER_ADMIN", "utf-8")),
      PRICE_ID_SETTER_ROLE: keccak256(
        Buffer.from("PRICE_ID_SETTER_ROLE", "utf-8")
      ),
      RELAYER_ROLE: keccak256(Buffer.from("RELAYER_ROLE", "utf-8")),
      TIMESTAMP_SETTER_ROLE: keccak256(
        Buffer.from("TIMESTAMP_SETTER_ROLE", "utf-8")
      ),
      assetRecipient: USDY_MANAGER_ASSET_RECIPIENT,
      assetSender: USDY_MANAGER_ASSET_SENDER,
      feeRecipient: USDY_MULTISIG,
      blocklist: BLOCKLIST_ADDRESS,
      collateral: USDC_ADDRESS,
      rwa: USDY_PROXY_ADDRESS,
      minimumDepositAmount: "500000000",
      minimumOffChainRedemptionAmount: "500000000000000000000",
      minimumRedemptionAmount: "500000000000000000000",
      mintFee: "0",
      pricer: USDY_PRICER_ADDRESS,
      redemptionFee: "0",
      sanctionsList: SANCTIONS_LIST_ADDRESS,
    },
    usdyManagerRoleMembers: {
      defaultAdminRoleMembers: [USDY_MULTISIG],
      managerAdminRoleMembers: [USDY_MULTISIG],
      pauserAdminRoleMembers: [PAUSER],
      priceIDSetterRoleMembers: [USDY_MULTISIG],
      relayerRoleMembers: [USDY_MULTISIG],
      timestampSetterRoleMembers: [USDY_MULTISIG],
    },
  },
  rwaOracleRateCheck: {
    rwaOracleRateCheckAddress: USDY_RWA_ORACLE_RATE_CHECK_ADDRESS,
    storage: {
      DEFAULT_ADMIN_ROLE: ZERO_ROLE,
      SETTER_ROLE: keccak256(Buffer.from("SETTER_ROLE", "utf-8")),
      roleMembers: {
        defaultAdminRoleMembers: [USDY_MULTISIG],
        setterRoleMembers: [USDY_MULTISIG, USDY_PRICER_ADDRESS],
      },
      oracleData: {
        MIN_PRICE_UPDATE_WINDOW: MIN_PRICE_UPDATE_WINDOW_RATE_CHECK,
        MAX_CHANGE_DIFF_BPS: MAX_CHANGE_DIFF_BPS_RATE_CHECK,
        rwaPrice: USDY_INITIAL_PRICE,
      },
    },
  },
  usdy_pricer: {
    usdyPricerAddress: USDY_PRICER_ADDRESS,
    storage: {
      DEFAULT_ADMIN_ROLE: ZERO_ROLE,
      PRICE_UPDATE_ROLE: keccak256(Buffer.from("PRICE_UPDATE_ROLE", "utf-8")),
    },
    usdyPricerRoleMembers: {
      defaultAdminRoleMembers: [USDY_MULTISIG],
      priceUpdateRoleMembers: [USDY_MULTISIG],
    },
  },
};

export default usdy_config;
