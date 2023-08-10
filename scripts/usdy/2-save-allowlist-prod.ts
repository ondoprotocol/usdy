import { task, types } from "hardhat/config";
import { addContract } from "../utils/defender-helper";
import { SUCCESS_CHECK } from "../utils/shell";

task("2-save-usdy-prod", "Save AllowList Prod and Add to Defender").setAction(
  async ({}, hre) => {
    const { save } = hre.deployments;
    const allowlistFactory = await hre.ethers.getContract("AllowlistFactory");
    const allowProxy = await allowlistFactory.allowlistProxy();
    const allowProxyAdmin = await allowlistFactory.allowlistProxyAdmin();

    const allowArtifact = await hre.deployments.getExtendedArtifact(
      "AllowlistUpgradeable"
    );
    const paArtifact = await hre.deployments.getExtendedArtifact("ProxyAdmin");

    let allowProxied = {
      address: allowProxy,
      ...allowArtifact,
    };
    let allowPA = {
      address: allowProxyAdmin,
      ...paArtifact,
    };
    await save("Allowlist", allowProxied);
    await save("ProxyAdminAllowlist", allowPA);

    const abiAllow = await hre.run("getDeployedContractABI", {
      contract: "Allowlist",
    });
    const abiPA = await hre.run("getDeployedContractABI", {
      contract: "ProxyAdminAllowlist",
    });

    const network = await hre.run("getCurrentNetwork");

    await addContract(network, allowProxy, "Allowlist Proxy", abiAllow);
    console.log(SUCCESS_CHECK + "Added Allowlist Proxy to defender");
    await addContract(network, allowProxyAdmin, "Allowlist Proxy Admin", abiPA);
    console.log(SUCCESS_CHECK + "Added Allowlist Proxy Admin to defender");
  }
);
