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

  // Execute in script for prod
  const blocklist = await ethers.getContract("Blocklist");
  await blocklist.transferOwnership(guardian.address);
  await blocklist.connect(guardian).acceptOwnership();
};

deployBlocklist.tags = ["Local", "Blocklist"];
export default deployBlocklist;
