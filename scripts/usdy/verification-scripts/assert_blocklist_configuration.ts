import { assertAgainstBlockchain } from "../../utils/helpers";
import { task } from "hardhat/config";

import usdy_config from "./config";

task(
  "check-blocklist",
  "Checks if blocklist has been properly initialized"
).setAction(async ({}, hre) => {
  console.log("hre.network.name ", hre.network.name);
  const ethers = hre.ethers;
  const jsonData = JSON.parse(JSON.stringify(usdy_config.blocklist));
  const blocklistStorage = jsonData["storage"];

  const blocklistContract = await ethers.getContractAt(
    "Blocklist",
    jsonData.blocklistAddress
  );

  // Assert the storage values for the contract
  for (const name in blocklistStorage) {
    await assertAgainstBlockchain(blocklistContract, name, blocklistStorage);
  }
});
