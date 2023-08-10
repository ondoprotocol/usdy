import { subtask, task, types } from "hardhat/config";
import { Network } from "defender-base-client";

subtask("getCurrentNetwork", "Get current network").setAction(
  async ({}, hre) => {
    return hre.network.name as Network;
  }
);

subtask(
  "getDeployedContractABI",
  "Gets ABI of deployed contract in deployments directory"
)
  .addParam("contract", "Contract name", undefined, types.string)
  .setAction(async ({ contract }, hre) => {
    const contractJson = require(`../../deployments/${hre.network.name}/${contract}.json`);
    return JSON.stringify(contractJson.abi);
  });
