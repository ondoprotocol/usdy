import { task, types } from "hardhat/config";
import { addContract } from "../utils/defender-helper";
import { SUCCESS_CHECK } from "../utils/shell";

task("4-save-wommf-prod", "Safe WOMMF Contract and Add to Defender").setAction(
  async ({}, hre) => {
    const { save } = hre.deployments;
    const wommfFactory = await hre.ethers.getContract("WOMMFFactory");
    const wommfProxy = await wommfFactory.wommfProxy();
    const wommfProxyAdmin = await wommfFactory.wommfProxyAdmin();

    const wommfArtifact = await hre.deployments.getExtendedArtifact("WOMMF");
    const paArtifact = await hre.deployments.getExtendedArtifact("ProxyAdmin");

    let wommf = {
      address: wommfProxy,
      ...wommfArtifact,
    };
    let proxyAdmin = {
      address: wommfProxyAdmin,
      ...paArtifact,
    };

    await save("WOMMF", wommf);
    await save("ProxyAdminWOMMF", proxyAdmin);

    const abiWommf = await hre.run("getDeployedContractABI", {
      contract: "WOMMF",
    });
    const abiPA = await hre.run("getDeployedContractABI", {
      contract: "ProxyAdminWOMMF",
    });

    const network = await hre.run("getCurrentNetwork");

    await addContract(network, wommfProxy, "WOMMF Proxy", abiWommf);
    console.log(SUCCESS_CHECK + "Added WOMMF Proxy to defender");
    await addContract(network, wommfProxyAdmin, "WOMMF Proxy Admin", abiPA);
    console.log(SUCCESS_CHECK + "Added OMMF Proxy Admin to defender");
  }
);
