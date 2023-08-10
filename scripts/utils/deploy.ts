import { DeployFunction } from "hardhat-deploy/types";
import { HardhatRuntimeEnvironment } from "hardhat/types";
import chalk from "chalk";
const inquire = require("inquirer");

export async function deployWithRetries(
  func: DeployFunction,
  hre: HardhatRuntimeEnvironment,
  contractName: string
) {
  let contractDeployed;
  let i = 0;
  try {
    await hre.ethers.getContract(contractName);
    console.log(chalk.greenBright(`${contractName} already deployed`));
    contractDeployed = true;
  } catch (error) {
    contractDeployed = false;
  }
  while (!contractDeployed && i < 3) {
    ++i;
    const shouldDeploy = await inquire.prompt({
      type: "confirm",
      message: `Should I deploy: ${contractName}?`,
      name: `deploy-confirm-${contractName}${i}`,
    });
    if (shouldDeploy) {
      try {
        await func(hre);
        break;
      } catch (error) {
        console.error(error);
      }
    } else {
      console.log(chalk.gray(`As you wish, skipping: ${contractName}`));
    }
  }
}
