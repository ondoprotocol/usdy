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
  "check-allowlist",
  "Checks if Allowlist contract has been properly initialized"
).setAction(async ({}, hre) => {
  console.log("hre.network.name ", hre.network.name);
  const ethers = hre.ethers;
  const jsonData = JSON.parse(JSON.stringify(usdy_config.allowlist));
  const allowlistProxyData = jsonData["allowlistProxy"];

  // Assert Proxy Admin slots
  assert(
    (await addressFromStorageSlot(
      jsonData["allowlistProxyAddress"],
      ADMIN_SLOT
    )) == allowlistProxyData.proxyAdmin,
    FAILURE_CROSS + "proxy admin mismatch"
  );

  assert(
    (await addressFromStorageSlot(
      jsonData["allowlistProxyAddress"],
      ROLLBACK_SLOT
    )) == allowlistProxyData.rollback,
    FAILURE_CROSS + "proxy rollback mismatch"
  );

  assert(
    (await addressFromStorageSlot(
      jsonData["allowlistProxyAddress"],
      BEACON_SLOT
    )) == allowlistProxyData.beacon,
    FAILURE_CROSS + "proxy beacon mismatch"
  );

  assert(
    (await addressFromStorageSlot(
      jsonData["allowlistProxyAddress"],
      IMPLEMENTATION_SLOT
    )) == allowlistProxyData.implementation,
    FAILURE_CROSS + "proxy impl mismatch"
  );

  // Assert Allowlist Proxy Admin
  const allowlistProxyAdminContract = await ethers.getContractAt(
    "ProxyAdmin",
    allowlistProxyData.proxyAdmin
  );

  assert(
    (await allowlistProxyAdminContract.getProxyAdmin(
      jsonData.allowlistProxyAddress
    )) == allowlistProxyAdminContract.address,
    "getProxyAdmin failed on the proxy admin contract"
  );

  assert(
    (await allowlistProxyAdminContract.getProxyImplementation(
      jsonData.allowlistProxyAddress
    )) == allowlistProxyData.implementation,
    "getProxyImplementation failed on the proxy admin contract"
  );

  assert(
    (await allowlistProxyAdminContract.owner()) ==
      jsonData["allowlistProxyAdmin"].owner,
    "Proxy admin owner check failed on the proxy admin contract"
  );

  const allowlistProxyContract = await ethers.getContractAt(
    "AllowlistUpgradeable",
    jsonData.allowlistProxyAddress
  );

  // Assert Role Members
  const allowlistRoleMembers = jsonData["allowlistRoleMembers"];
  await assertRoleMembers(
    allowlistProxyContract,
    allowlistProxyData.DEFAULT_ADMIN_ROLE,
    allowlistRoleMembers.defaultAdminRoleMembers
  );

  await assertRoleMembers(
    allowlistProxyContract,
    allowlistProxyData.ALLOWLIST_SETTER,
    allowlistRoleMembers.allowlistSetterRoleMembers
  );

  await assertRoleMembers(
    allowlistProxyContract,
    allowlistProxyData.ALLOWLIST_ADMIN,
    allowlistRoleMembers.allowlistAdminRoleMembers
  );

  // Assert the storage values for the proxy contract that pertain to
  // implementation contract
  for (const name in allowlistProxyData.implementationStorage) {
    await assertAgainstBlockchain(
      allowlistProxyContract,
      name,
      allowlistProxyData.implementationStorage
    );
  }
});
