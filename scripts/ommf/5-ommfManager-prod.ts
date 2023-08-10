import { task } from "hardhat/config";
import {
  BaseProposalRequestParams,
  addContract,
  proposeGrantRole,
  proposeFunctionCall,
} from "../utils/defender-helper";
import { SUCCESS_CHECK } from "../utils/shell";
import {
  PROD_GUARDIAN_OMMF,
  PROD_MANAGER_ADMIN_OMMF,
} from "../../deploy/mainnet_constants";
import { keccak256 } from "ethers/lib/utils";

task(
  "5-ommfManager-prod",
  "Grant MINTER_ROLE to ommfManager, and sets the pricer"
).setAction(async ({}, hre) => {
  const name = "OMMFManager";
  const ommfManager = await hre.ethers.getContract(name);
  let params: BaseProposalRequestParams = {
    via: PROD_GUARDIAN_OMMF,
    viaType: "Gnosis Safe",
  };
  const network = await hre.run("getCurrentNetwork");
  const abi = await hre.run("getDeployedContractABI", { contract: name });

  // Add ommfManager to defender
  await addContract(network, ommfManager.address, name, abi);
  console.log(SUCCESS_CHECK + "Added ommfManager to Defender");

  // Grant MINTER_ROLE to ommfManager on OMMF
  const ommf = await hre.ethers.getContract("OMMF");
  let ommfContract = {
    network: network,
    address: ommf.address,
  };
  params.title = "Grant MINTER_ROLE to ommfManager on OMMF";
  params.description = "Grant MINTER_ROLE to ommfManager on OMMF";
  await proposeGrantRole({
    params: params,
    contract: ommfContract,
    role: keccak256(Buffer.from("MINTER_ROLE", "utf-8")),
    account: ommfManager.address,
  });
  console.log(
    SUCCESS_CHECK + "Grant ommfManager Proposal submitted to Defender"
  );

  // Set Pricer in OMMFManager
  const pricer = await hre.ethers.getContract("Pricer");
  let ommfManagerContract = {
    network: network,
    address: ommfManager.address,
  };
  params.title = "Set Pricer";
  params.description = "Set pricer in ommf Manager";
  await proposeFunctionCall({
    contract: ommfManagerContract,
    params: params,
    functionName: "setPricer",
    functionInterface: [
      {
        type: "address",
        name: "newPricer",
      },
    ],
    functionInputs: [pricer.address],
  });
  console.log(SUCCESS_CHECK + "SetPricer Proposal submitted to Defender");

  const PRICER_ROLE = keccak256(Buffer.from("PRICE_ID_SETTER_ROLE", "utf-8"));
  params.title = "Grant Manager Admin PRICE_ID_SETTER_ROLE";
  params.description = "Grant Role to managerAdmin";
  await proposeGrantRole({
    params: params,
    contract: ommfManagerContract,
    role: PRICER_ROLE,
    account: PROD_MANAGER_ADMIN_OMMF,
  });
  console.log(
    SUCCESS_CHECK + "Grant PRICE_ID_SETTER_ROLE proposed in Defender"
  );
});
