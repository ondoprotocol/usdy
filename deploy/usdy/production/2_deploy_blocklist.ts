import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { KYC_REGISTRY } from "../../mainnet_constants";
const { ethers } = require("hardhat");

const deployBlocklist: DeployFunction = async function (
  hre: HardhatRuntimeEnvironment
) {
  const { deployments, getNamedAccounts } = hre;
  const { save } = deployments;
  const { deployer } = await getNamedAccounts();
  const { deploy } = deployments;
  const signers = await ethers.getSigners();

  const guardian = signers[1];

  await deploy("Blocklist", {
    from: deployer,
    args: [],
    log: true,
  });
};

deployBlocklist.tags = ["Prod-Blocklist", "Prod-USDY-2"];
export default deployBlocklist;
