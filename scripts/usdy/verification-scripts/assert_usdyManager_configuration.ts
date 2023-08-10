import {
  assertAgainstBlockchain,
  assertRoleMembers,
} from "../../utils/helpers";
import { task } from "hardhat/config";

import usdy_config from "./config";

task(
  "check-usdy-manager",
  "Checks if USDYManager has been properly initialized"
).setAction(async ({}, hre) => {
  console.log("hre.network.name ", hre.network.name);
  const ethers = hre.ethers;
  const jsonData = JSON.parse(JSON.stringify(usdy_config.usdyManager));
  const usdyManagerStorage = jsonData["storage"];

  const usdyManagerContract = await ethers.getContractAt(
    "USDYManager",
    jsonData.usdyManagerAddress
  );

  // Assert Role Members
  const usdyManagerRoleMembers = jsonData["usdyManagerRoleMembers"];
  await assertRoleMembers(
    usdyManagerContract,
    usdyManagerStorage.DEFAULT_ADMIN_ROLE,
    usdyManagerRoleMembers.defaultAdminRoleMembers
  );

  await assertRoleMembers(
    usdyManagerContract,
    usdyManagerStorage.MANAGER_ADMIN,
    usdyManagerRoleMembers.managerAdminRoleMembers
  );

  await assertRoleMembers(
    usdyManagerContract,
    usdyManagerStorage.PAUSER_ADMIN,
    usdyManagerRoleMembers.pauserAdminRoleMembers
  );

  await assertRoleMembers(
    usdyManagerContract,
    usdyManagerStorage.PRICE_ID_SETTER_ROLE,
    usdyManagerRoleMembers.priceIDSetterRoleMembers
  );

  await assertRoleMembers(
    usdyManagerContract,
    usdyManagerStorage.RELAYER_ROLE,
    usdyManagerRoleMembers.relayerRoleMembers
  );

  await assertRoleMembers(
    usdyManagerContract,
    usdyManagerStorage.TIMESTAMP_SETTER_ROLE,
    usdyManagerRoleMembers.timestampSetterRoleMembers
  );

  // Assert the storage values for the contract
  for (const name in usdyManagerStorage) {
    await assertAgainstBlockchain(
      usdyManagerContract,
      name,
      usdyManagerStorage
    );
  }
});
