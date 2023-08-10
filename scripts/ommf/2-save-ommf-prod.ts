import { task, types } from "hardhat/config";
import { addContract } from "../utils/defender-helper";
import { SUCCESS_CHECK } from "../utils/shell";

task("2-save-cash-prod", "Save OMMF Contract and Add to Defender").setAction(
  async ({}, hre) => {
    const { save } = hre.deployments;
    const ommfFactory = await hre.ethers.getContract("OMMFFactory");
    const ommfProxy = await ommfFactory.ommfProxy();
    const ommfProxyAdmin = await ommfFactory.ommfProxyAdmin();

    const ommfArtifact = await hre.deployments.getExtendedArtifact("OMMF");
    const paArtifact = await hre.deployments.getExtendedArtifact("ProxyAdmin");

    let ommf = {
      address: ommfProxy,
      ...ommfArtifact,
    };
    let proxyAdmin = {
      address: ommfProxyAdmin,
      ...paArtifact,
    };

    await save("OMMF", ommf);
    await save("ProxyAdminOMMF", proxyAdmin);

    const abiOmmf = await hre.run("getDeployedContractABI", {
      contract: "OMMF",
    });
    const abiPA = await hre.run("getDeployedContractABI", {
      contract: "ProxyAdminOMMF",
    });

    const network = await hre.run("getCurrentNetwork");

    await addContract(network, ommfProxy, "OMMF Proxy", abiOmmf);
    console.log(SUCCESS_CHECK + "Added OMMF Proxy to defender");
    await addContract(network, ommfProxyAdmin, "OMMF Proxy Admin", abiPA);
    console.log(SUCCESS_CHECK + "Added OMMF Proxy Admin to defender");
  }
);
