import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { KYC_REGISTRY, SANCTION_ADDRESS } from "../../mainnet_constants";
const { ethers } = require("hardhat");

const deployAllowList_Factory: DeployFunction = async function (
  hre: HardhatRuntimeEnvironment
) {
  const { deployments, getNamedAccounts } = hre;
  const { save } = deployments;
  const { deployer } = await getNamedAccounts();
  const { deploy } = deployments;
  const signers = await ethers.getSigners();

  const guardian = signers[1];

  await deploy("USDYFactory", {
    from: deployer,
    args: [guardian.address],
    log: true,
  });

  // USDY deps
  const factory = await ethers.getContract("USDYFactory");
  const blocklist = await ethers.getContract("Blocklist");
  const allowlist = await ethers.getContract("Allowlist");

  await factory
    .connect(guardian)
    .deployUSDY("USDY", "USDY", [
      blocklist.address,
      allowlist.address,
      SANCTION_ADDRESS,
    ]);

  const usdyProxy = await factory.usdyProxy();
  const usdyProxyAdmin = await factory.usdyProxyAdmin();
  const usdyImplementation = await factory.usdyImplementation();

  console.log(`\nThe USDY proxy is deployed @: ${usdyProxy}`);
  console.log(`The USDY proxy admin is deployed @: ${usdyProxyAdmin}`);
  console.log(`The USDY Implementation is deployed @: ${usdyImplementation}\n`);

  const usdyArtifact = await deployments.getExtendedArtifact("USDY");
  const paAtrifact = await deployments.getExtendedArtifact("ProxyAdmin");

  let usdyProxied = {
    address: usdyProxy,
    ...usdyArtifact,
  };
  let usdyAdmin = {
    address: usdyProxyAdmin,
    ...usdyProxyAdmin,
  };
  let usdyImpl = {
    address: usdyImplementation,
    ...usdyImplementation,
  };

  await save("USDY", usdyProxied);
  await save("ProxyAdminUSDY", usdyAdmin);
  await save("USDYImplementation", usdyImpl);
};

deployAllowList_Factory.tags = ["Local", "USDY"];
export default deployAllowList_Factory;
