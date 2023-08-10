import { task } from "hardhat/config";
import {
  assertAgainstBlockchain,
  assertRoleMembers,
} from "../../utils/helpers";

import usdy_config from "./config";

task(
  "check-usdy-pricer",
  "Checks if USDY pricer is configured correctly"
).setAction(async ({}, hre) => {
  console.log("hre.network.name ", hre.network.name);
  const jsonData = JSON.parse(JSON.stringify(usdy_config.usdy_pricer));
  const usdyPricerStorage = jsonData["storage"];
  const usdyPricerContract = await hre.ethers.getContractAt(
    "Pricer",
    jsonData.usdyPricerAddress
  );

  // Assert role members
  const usdyPricerRoleMembers = jsonData["usdyPricerRoleMembers"];
  await assertRoleMembers(
    usdyPricerContract,
    usdyPricerStorage.DEFAULT_ADMIN_ROLE,
    usdyPricerRoleMembers.defaultAdminRoleMembers
  );
  await assertRoleMembers(
    usdyPricerContract,
    usdyPricerStorage.PRICE_UPDATE_ROLE,
    usdyPricerRoleMembers.priceUpdateRoleMembers
  );

  // Check data
  for (const name in usdyPricerStorage) {
    await assertAgainstBlockchain(usdyPricerContract, name, usdyPricerStorage);
  }
});
