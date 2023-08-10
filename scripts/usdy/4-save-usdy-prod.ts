import { task, types } from "hardhat/config";
import { addContract } from "../utils/defender-helper";
import { SUCCESS_CHECK } from "../utils/shell";

task("4-save-usdy-prod", "Save USDY and Add to Defender").setAction(
  async ({}, hre) => {
    const { save } = hre.deployments;
    const usdyFactory = await hre.ethers.getContract("USDYFactory");
    const usdyProxy = await usdyFactory.usdyProxy();
    const usdyPa = await usdyFactory.usdyProxyAdmin();

    const usdyArtifact = await hre.deployments.getExtendedArtifact("USDY");
    const paAtrifact = await hre.deployments.getExtendedArtifact("ProxyAdmin");

    let usdyProxied = {
      address: usdyProxy,
      ...usdyArtifact,
    };
    let usdyAdmin = {
      address: usdyPa,
      ...paAtrifact,
    };

    await save("USDY", usdyProxied);
    await save("ProxyAdminUSDY", usdyAdmin);

    const abiUSDY = await hre.run("getDeployedContractABI", {
      contract: "USDY",
    });
    const abiPA = await hre.run("getDeployedContractABI", {
      contract: "ProxyAdminUSDY",
    });

    const network = await hre.run("getCurrentNetwork");

    await addContract(network, usdyProxy, "USDY Proxy", abiUSDY);
    console.log(SUCCESS_CHECK + "Added USDY Proxy to Defender");
    await addContract(network, usdyPa, "USDY Proxy Admin", abiPA);
    console.log(SUCCESS_CHECK + "Added USDY Proxy Admin to Defender");
  }
);
