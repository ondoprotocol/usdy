import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { KYC_REGISTRY, PROD_GUARDIAN_OMMF } from "../../mainnet_constants";
const { ethers } = require("hardhat");

const deployUSDY_Factory: DeployFunction = async function (
  hre: HardhatRuntimeEnvironment
) {
  const { deployments, getNamedAccounts } = hre;
  const { deployer } = await getNamedAccounts();
  const { deploy } = deployments;

  // Deploy the factory
  await deploy("USDYFactory", {
    from: deployer,
    args: [PROD_GUARDIAN_OMMF],
    log: true,
  });
};

deployUSDY_Factory.tags = ["Prod-USDY-Factory", "Prod-USDY-3"];
export default deployUSDY_Factory;
