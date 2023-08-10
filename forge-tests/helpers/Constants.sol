pragma solidity 0.8.16;

import "contracts/RWAHub.sol";
import "contracts/Pricer.sol";
import "contracts/PricerWithOracle.sol";
import "contracts/kyc/KYCRegistry.sol";
import "contracts/external/openzeppelin/contracts/token/IERC20.sol";

// Known production mainnet token contracts.
contract Tokens {
  /*//////////////////////////////////////////////////////////////
                      Ethereum Tokens
  //////////////////////////////////////////////////////////////*/
  IERC20 public USDC = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
  IERC20 public DAI = IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);
  IERC20 public FRAX = IERC20(0x853d955aCEf822Db058eb8505911ED77F175b99e);
  IERC20 public LUSD = IERC20(0x5f98805A4E8be255a32880FDeC7F6728C6568bA0);
  IERC20 public USDT = IERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7);
}

contract Oracles {
  // Chainalysis
  ISanctionsList public constant SANCTIONS_ORACLE =
    ISanctionsList(0x40C57923924B5c5c5455c48D93317139ADDaC8fb);
}

contract Constants {
  // Manager addresses
  address constant guardian = address(0xFEDBAD);
  address constant managerAdmin = address(0xC0FFEE);
  address constant pauser = address(0xFFFFFFF);
  address constant assetSender = address(0xFEEDBEEF);
  address constant feeRecipient = address(0x123456);
  address constant relayer = address(0xBADBEEF);
  address constant instantMintAssetManager = address(0xBAEBAE);

  // User Addresses
  address constant alice = address(0x9999991);
  address constant bob = address(0x9999992);
  address constant charlie = address(0x9999993);
  address constant badActor = address(0xBADBAD);
}
