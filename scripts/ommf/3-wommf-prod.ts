import { task } from "hardhat/config";
import {
  addContract,
  BaseProposalRequestParams,
  proposeFunctionCall,
} from "../utils/defender-helper";
import {
  PROD_GUARDIAN_OMMF,
  PROD_KYC_REGISTRY,
  PROD_OMMF_KYC_GROUP,
} from "../../deploy/mainnet_constants";
import { SUCCESS_CHECK } from "../utils/shell";
import { BigNumber } from "ethers";

task("3-wommf-prod", "Deploy WOMMF from factory Contract").setAction(
  async ({}, hre) => {
    const name = "WOMMFFactory";
    let params: BaseProposalRequestParams = {
      via: PROD_GUARDIAN_OMMF,
      viaType: "Gnosis Safe",
    };

    const wommfFactory = await hre.ethers.getContract(name);
    const network = await hre.run("getCurrentNetwork");
    const abi = await hre.run("getDeployedContractABI", { contract: name });

    let contract = {
      network: network,
      address: wommfFactory.address,
    };

    const ommf = await hre.ethers.getContract("OMMF");

    await addContract(network, wommfFactory.address, name, abi);
    console.log(SUCCESS_CHECK + "Added Cash Factory to Defender");

    // Propose the deployment in gnosis defender
    params.title = "Deploy WOMMF";
    params.description = "Deploy WOMMF token from factory";
    await proposeFunctionCall({
      contract: contract,
      params: params,
      functionName: "deployWOMMF",
      functionInterface: [
        {
          type: "string",
          name: "name",
        },
        {
          type: "string",
          name: "ticker",
        },
        {
          type: "address",
          name: "ommfAddress",
        },
        {
          type: "address",
          name: "registry",
        },
        {
          type: "uint256",
          name: "requirementGroup",
        },
      ],
      functionInputs: [
        "Wrapped OMMF",
        "WOMMF",
        ommf.address,
        PROD_KYC_REGISTRY,
        PROD_OMMF_KYC_GROUP,
      ],
    });
    console.log(SUCCESS_CHECK + "Proposed WOMMF Deployment from factory");
  }
);
