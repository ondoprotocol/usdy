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

task("1-ommf-prod", "Deploy OMMF from factory contract").setAction(
  async ({}, hre) => {
    // Setup Params
    const name = "OMMFFactory";
    let params: BaseProposalRequestParams = {
      via: PROD_GUARDIAN_OMMF,
      viaType: "Gnosis Safe",
    };

    const ommfFactory = await hre.ethers.getContract(name);
    const network = await hre.run("getCurrentNetwork");
    const abi = await hre.run("getDeployedContractABI", { contract: name });

    let contract = {
      network: network,
      address: ommfFactory.address,
    };

    // Add OMMF Factory contract to defender
    await addContract(network, ommfFactory.address, name, abi);
    console.log(SUCCESS_CHECK + "Added Cash Factory to Defender");

    // Propose the deployment in gnosis defender
    params.title = "Deploy OMMF";
    params.description = "Deploy OMMF token from factory";
    await proposeFunctionCall({
      contract: contract,
      params: params,
      functionName: "deployOMMF",
      functionInterface: [
        {
          name: "registry",
          type: "address",
        },
        {
          name: "requirementGroup",
          type: "uint256",
        },
      ],
      functionInputs: [PROD_KYC_REGISTRY, PROD_OMMF_KYC_GROUP],
    });
    console.log(SUCCESS_CHECK + "Proposed OMMF Deployment from factory");
  }
);
