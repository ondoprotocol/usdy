import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import {
  PROD_ASSET_SENDER_USDY,
  PROD_FEE_RECIPIENT_USDY,
  PROD_MANAGER_ADMIN_USDY,
  PROD_ORACLE,
  PROD_PAUSER_USDY,
  SANCTION_ADDRESS,
  USDC_MAINNET,
  ZERO_ADDRESS,
} from "../../mainnet_constants";
import { parseUnits } from "ethers/lib/utils";
const { ethers } = require("hardhat");

const deploy_usdyManager: DeployFunction = async function (
  hre: HardhatRuntimeEnvironment
) {
  const { deployments, getNamedAccounts } = hre;
  const { deployer } = await getNamedAccounts();
  const { deploy } = deployments;

  const factoryUSDY = await ethers.getContract("USDYFactory");
  const factoryAllow = await ethers.getContract("AllowlistFactory");
  const blocklist = await ethers.getContract("Blocklist");

  const usdyAddress = await factoryUSDY.usdyProxy();
  const allowlistAddress = await factoryAllow.allowlistProxy();

  if (usdyAddress == ZERO_ADDRESS) {
    throw new Error("USDY Token not deployed through factory!");
  }

  await deploy("USDYManager", {
    from: deployer,
    args: [
      USDC_MAINNET, // _collateral
      usdyAddress, // _rwa
      PROD_MANAGER_ADMIN_USDY, // managerAdmin
      PROD_PAUSER_USDY, // pauser
      PROD_ASSET_SENDER_USDY, // _assetSender
      PROD_FEE_RECIPIENT_USDY, // _feeRecipient
      parseUnits("500", 6), // _minimumDepositAmount
      parseUnits("500", 18), // _minimumRedemptionAmount
      blocklist.address, // blocklist
      SANCTION_ADDRESS, // sanctionsList
    ],
    log: true,
  });
};
deploy_usdyManager.tags = ["Prod-USDYManager", "Prod-USDY-4"];
export default deploy_usdyManager;
