import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { PROD_ORACLE, PROD_GUARDIAN_USDY } from "../../mainnet_constants";
const { ethers } = require("hardhat");

const deploy_usdyPricer: DeployFunction = async function (
  hre: HardhatRuntimeEnvironment
) {
  const { deployments, getNamedAccounts } = hre;
  const { deployer } = await getNamedAccounts();
  const { deploy } = deployments;

  await deploy("USDY_Pricer", {
    from: deployer,
    contract: "USDYPricer",
    args: [PROD_GUARDIAN_USDY, PROD_GUARDIAN_USDY],
    log: true,
  });
};

deploy_usdyPricer.tags = ["Prod-USDY-Pricer", "Prod-USDY-5"];
export default deploy_usdyPricer;
