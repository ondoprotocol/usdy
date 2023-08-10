import { task } from "hardhat/config";
import {
  addContract,
  BaseProposalRequestParams,
  proposeFunctionCall,
} from "../utils/defender-helper";
import {
  PROD_GUARDIAN_USDY,
  SANCTION_ADDRESS,
} from "../../deploy/mainnet_constants";
import { SUCCESS_CHECK } from "../utils/shell";

task("3-usdy-prod", "Deploy USDY from factory contract").setAction(
  async ({}, hre) => {
    const name = "USDYFactory";
    let params: BaseProposalRequestParams = {
      via: PROD_GUARDIAN_USDY,
      viaType: "Gnosis Safe",
    };

    const usdyFactory = await hre.ethers.getContract(name);
    const blocklist = await hre.ethers.getContract("Blocklist");
    const allowlist = await hre.ethers.getContract("Allowlist");
    const network = await hre.run("getCurrentNetwork");
    const abi = await hre.run("getDeployedContractABI", { contract: name });

    let contract = {
      network: network,
      address: usdyFactory.address,
    };

    // Add USDY Factory contract to defender
    await addContract(network, usdyFactory.address, name, abi);
    console.log(SUCCESS_CHECK + "Added USDY Factory to Defender");

    // Propose the deployment in gnosis defender
    params.title = "Deploy USDY";
    params.description = "Deploy USDY token from factory";
    let listData = [blocklist.address, allowlist.address, SANCTION_ADDRESS];
    await proposeFunctionCall({
      contract: contract,
      params: params,
      functionName: "deployUSDY",
      functionInterface: [
        {
          name: "name",
          type: "string",
        },
        {
          name: "ticker",
          type: "string",
        },
        {
          components: [
            {
              name: "blocklist",
              type: "address",
            },
            {
              name: "allowlist",
              type: "address",
            },
            {
              name: "sanctionsList",
              type: "address",
            },
          ],
          name: "listData",
          type: "tuple",
        },
      ],
      functionInputs: ["Ondo U.S. Dollar Yield", "USDY", listData],
    });
    console.log(SUCCESS_CHECK + "Proposed USDY Deployment from factory");
  }
);
