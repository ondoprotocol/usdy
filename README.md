# Ondo RWA

Ondo's RWA protocol allows for whitelisted (KYC'd) users to hold exposure to Real World Assets (RWAs) through yield-bearing or rebasing ERC20 tokens.

# USDY

USDY - Is a non-rebasing ERC20 token that represents United States Dollar Yielding deposit. Since this token in non-rebasing the value accrual mechanism occurs exclusively through price appreciation (most similar to [OUSG](https://docs.ondo.finance/funds-and-cash-management/asset-strategy#ousg-and-ostb)). This tokens is not subject to the same KYC requirements as OUSG/OMMF and instead gates transfers based on an allowlist and blocklist.

# Contracts

## RWAHubs

### RWAHub

**The largest and most important contract in the protocol.** RWAHub is an abstract contract which governs the subscription and redemption RWATokens (OMMF/USDY/OUSG) tokens. The contract facilitates giving holders exposure to RWAs by transferring the deposited USDC to 3rd-party custodians. The RWAHub tracks deposits and redemptions linearly. Each deposit and redemption is given a unique subscription or redemption Id which is the numerical value represented as a `bytes32` object.

To mint RWA tokens, a user must send USDC to the contract and call `requestSubscription`. At some point after the funds have been off-ramped and the RWA has been purchased through the custodian, a `priceId` is set by a trusted EOA for a given `depositId` through a call to `setPriceIdForDeposits`. This `priceId` determines the exchange rate between USDC and the desired RWA. Once the exchange rate is set, users can claim their CASH token by calling `claimMint`. The price associated for each `priceId` is stored in the `Pricer.sol` contract. Each RWAHub will have a corresponding pricer. More information on the Pricer is below.

Users can also mint RWA tokens by sending USDC to a specified address. An EOA with the `RELAYER_ROLE` will monitor the off-chain address for deposits and add a proof of the deposit through calling `addProof`. The depositId will be the transaction hash of the transfer that send USDC to the specified address. A `priceId` must also be set for these off-chain deposits. The RWAHub will make **external-calls** to the pricer for retrieving prices on all mints and redemptions.

To redeem a RWA for USDC, users must burn their RWA tokens by calling `requestRedemption`. At some point after the RWA has been sold by the custodian and funds have been on-ramped to USDC, a `priceId` is set for the corresponding `redemptionId` by a trusted EOA through a call to `setPriceIdForRedemptions`. After the `priceId` has been set for a given redemption, the user may claim their USDC through a call to `claimRedemption`.

The base contract that inherits from `RWAHub` must implement the `_checkRestrictions` function which will make the same transfer checks that the RWA itself makes. The reason for this check is to not allow invalid accounts to be able to request subscriptions or claim redemptions of the rwa.

### RWAHubOffChainRedemptions

Is a child contract of RWAHub, which adds functionality to have users request that their redemption be serviced through an off-chain wire transfer.

## Pricer

The pricer contract sets priceIds for given prices. The contract expects an rwaOracle contract that confirms to the `IRWAOracleSetter` interface to which the pricer can update prices. Every time a price is added through `addPrice`, the pricer adds a new priceId with an associated price and makes an **external-call** to `setPrice` in the rwaOracle. If the rwaOracle and pricer are not in sync with their latest prices, the pricer can catch up to the rwaOracle's price with a call to `addLatestOraclePrice`. A priceId of 0 should never be used and clients should revert with a 0 priceId. The `rwaOracles` were audited previously and a link to the report can be found [here](https://drive.google.com/file/d/1hdP63ACMdXz-a70Hu6Kromfnw6ixAx-4/view?usp=sharing) and an abridged version [here](https://hackmd.io/CQf5dztDTzWBu29Qat8X7A?view).

## SanctionsListClient

Contracts that want to interface with a SanctionsList can do so by inheriting from `SanctionsListClient` or `SanctionsListClientUpgradeable`. We currently use [Chainalysis sanctions oracle](https://go.chainalysis.com/chainalysis-oracle-docs.html) as the sanctions list.

## Upgradeable Token Architecture & Factories

All Tokens and the allowlist contract in this repo conform to an EIP-1967 Upgradable Proxy convention. Each Token exists as an array of 3 contracts:

- `Proxy.sol`: The proxy contract
- `ProxyAdmin.sol`: The OZ Proxy Admin Contract, given the ability to upgrade the implementation contract of the proxy
- `Implementation`: The Contract to which `proxy.sol` delegate calls to.

These upgradable Proxies are deployed through a `<>_factory.sol` contract, which will handle some of the role transfers, and complete the first step of initialization.

## USDY

### USDY Token

The USDY contract is an upgradeable (Transparent Upgradeable Proxy) with transfer restrictions. USDY is not required to abide by the same transfer restrictions as OUSG/OMMF. In order to hold, send and receive USDY. A user will need to add themselves to the [allowlist](contracts/usdy/allowlist/AllowlistUpgradeable.sol), not be present on the [blocklist](contracts/usdy/blocklist/Blocklist.sol), and not be on a [sanctionsList](https://etherscan.io/address/0x40C57923924B5c5c5455c48D93317139ADDaC8fb).
Thus, every transfer makes an **external-call** to each of these 3 contracts.

### USDY Manager

The `USDYManager` is the gateway for minting/redeeming USDY tokens. The contract allows for off chain redemptions by inheriting from `RWAHubOffChainRedemptions`. The `_checkRestrictions` function does not check if the account is on the allowlist because the user can always add itself to the allowlist for a given term (see below). The USDY Manager has additional functions to set when a user can claim. For a list of `depositIds`, the `TIMESTAMP_SETTER_ROLE` sets when a user can claim the USDY they have requested to mint. The `_claimMint` function enforces that the timestamp to claim has been passed for the given `depositId`.

### Allowlist

The allowlist is an upgradeable contract that maintains a list of allowed addresses. By default, all contracts pass the allowlist check in `isAllowed`. An EOA is "allowed" if it has added itself to the allowlist for a _valid term_. A term is a string of conditions that the EOA must verify it has read and agreed to. A _valid term_ is a term that the `ALLOWLIST_ADMIN` has marked as valid to be on the allowlist with. Valid terms are denoted as an array of `validIndexes` that map to valid terms in the `terms` array. The valid terms are set by the `ALLOWLIST_ADMIN` calling `setValidTermIndexes`. An EOA can add itself to the allowlist either by calling `addSelfToAllowlist` for a given term or by passing in a signature signing a given term through `addAccountToAllowlist`.

Contracts that want to utilize the Allowlist can do so either by inherited `AllowlistClient` or `AllowlistClientUpgradeable` and implementing the method to set the allowlist.

### Blocklist

The blocklist is a non-upgradeable contract that maintains a list of addresses that are blocked from interacting with a set of contracts. Addresses can be added and removed to the blocklist by the owner of the contract. Contracts that want to utilize the Blocklist can do so either by inherited `BlocklistClient` or `BlocklistUpgradeable` and implementing a method to set the blocklist.

# Testing and Development

## Setup

- Install Node >= 16
- Run `yarn install`
- Install forge
- Copy `.env.example` to a new file `.env` in the root directory of the repo. Keep the `FORK_FROM_BLOCK_NUMBER_MAINNET` value the same. Fill in a dummy mnemonic and add a RPC_URL to populate `MAINNET_RPC_URL`.
- Run `yarn init-repo`

## Commands

- Start a local blockchain: `yarn local-node`
  - The scripts found under `scripts/ci/event_coverage.ts` aim to interact with the contracts in a way that maximizes the count of distinct event types emitted. For example:

```sh
yarn hardhat run --network localhost scripts/ci/event_coverage.ts
```

- Run Tests: `yarn test-forge`

- Generate Gas Report: `yarn test-forge --gas-report`

## Writing Tests and Forge Scripts

For testing with Foundry, `forge-tests/OMMF_BasicDeployment.sol` & `forge-tests/USDY_BasicDeployment.sol` were added to allow for users to easily deploy and setup the OMMF & USDY protocol for local testing.

To setup and write tests for contracts within foundry from a deployed state please include the following layout within your testing file. Helper functions are provided within each of these respective setup files.

```solidity
pragma solidity 0.8.16;

import "forge-tests/OMMF_BasicDeployment.sol";

contract Test_case_someDescription is OMMF_BasicDeployment {
  function testName() public {
    console.log(ommf.name());
  }
}
```

_Note_:

- Within the foundry tests `address(this)` is given certain permissioned roles. Please use a freshly generated address when writing POC's related to bypassing access controls.

## VS Code

CTRL+Click in Vs Code may not work due to usage of relative and absolute import paths.
