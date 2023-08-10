import { assert } from "console";
import {
  ADMIN_SLOT,
  ROLLBACK_SLOT,
  IMPLEMENTATION_SLOT,
  BEACON_SLOT,
} from "../../utils/constants";
import {
  assertAgainstBlockchain,
  assertRoleMembers,
  addressFromStorageSlot,
} from "../../utils/helpers";
import usdy_config from "./config";
import { task } from "hardhat/config";
import { FAILURE_CROSS } from "../../utils/shell";

task(
  "check-usdy",
  "Checks if USDY contract has been properly initialized"
).setAction(async ({}, hre) => {
  console.log("hre.network.name ", hre.network.name);
  const ethers = hre.ethers;
  const jsonData = JSON.parse(JSON.stringify(usdy_config.usdy));
  const usdyProxyData = jsonData["usdyProxy"];

  // Assert Proxy Admin slots
  assert(
    (await addressFromStorageSlot(jsonData["usdyProxyAddress"], ADMIN_SLOT)) ==
      usdyProxyData.proxyAdmin,
    FAILURE_CROSS + "proxy admin mismatch"
  );

  assert(
    (await addressFromStorageSlot(
      jsonData["usdyProxyAddress"],
      ROLLBACK_SLOT
    )) == usdyProxyData.rollback,
    FAILURE_CROSS + "proxy rollback mismatch"
  );

  assert(
    (await addressFromStorageSlot(jsonData["usdyProxyAddress"], BEACON_SLOT)) ==
      usdyProxyData.beacon,
    FAILURE_CROSS + "proxy beacon mismatch"
  );

  assert(
    (await addressFromStorageSlot(
      jsonData["usdyProxyAddress"],
      IMPLEMENTATION_SLOT
    )) == usdyProxyData.implementation,
    FAILURE_CROSS + "proxy impl mismatch"
  );

  // Assert USDY Proxy Admin
  const usdyProxyAdminContract = await ethers.getContractAt(
    "ProxyAdmin",
    usdyProxyData.proxyAdmin
  );

  assert(
    (await usdyProxyAdminContract.getProxyAdmin(jsonData.usdyProxyAddress)) ==
      usdyProxyAdminContract.address,
    "getProxyAdmin failed on the proxy admin contract"
  );

  assert(
    (await usdyProxyAdminContract.getProxyImplementation(
      jsonData.usdyProxyAddress
    )) == usdyProxyData.implementation,
    "getProxyImplementation failed on the proxy admin contract"
  );

  assert(
    (await usdyProxyAdminContract.owner()) == jsonData["usdyProxyAdmin"].owner,
    "Proxy admin owner check failed on the proxy admin contract"
  );

  const usdyProxyContract = await ethers.getContractAt(
    "USDY",
    jsonData.usdyProxyAddress
  );

  // Assert Role Members
  const usdyRoleMembers = jsonData["usdyProxyRoleMembers"];
  await assertRoleMembers(
    usdyProxyContract,
    usdyProxyData.DEFAULT_ADMIN_ROLE,
    usdyRoleMembers.defaultAdminRoleMembers
  );

  await assertRoleMembers(
    usdyProxyContract,
    usdyProxyData.BURNER_ROLE,
    usdyRoleMembers.burnerRoleMembers
  );

  await assertRoleMembers(
    usdyProxyContract,
    usdyProxyData.LIST_CONFIGURER_ROLE,
    usdyRoleMembers.listConfigurerRoleMembers
  );

  await assertRoleMembers(
    usdyProxyContract,
    usdyProxyData.MINTER_ROLE,
    usdyRoleMembers.minterRoleMembers
  );

  await assertRoleMembers(
    usdyProxyContract,
    usdyProxyData.PAUSER_ROLE,
    usdyRoleMembers.pauserRoleMembers
  );

  // Assert the storage values for the proxy contract that pertain to
  // implementation contract
  for (const name in usdyProxyData.implementationStorage) {
    await assertAgainstBlockchain(
      usdyProxyContract,
      name,
      usdyProxyData.implementationStorage
    );
  }
});
