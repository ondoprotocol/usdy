const { spawn } = require("child_process");
import chalk from "chalk";

export const SUCCESS_CHECK = chalk.green("✔") + " ";
export const FAILURE_CROSS = chalk.red("✘") + " ";

export async function verify(network: string) {
  await execute(
    `yarn hardhat --network ${network} etherscan-verify --license BUSL-1.1`
  );
}

export async function deploy(tags: string, network: string) {
  await execute(`yarn hardhat deploy --tags ${tags} --network ${network}`);
}

export const sleep = (ms: number) =>
  new Promise((resolve) => setTimeout(resolve, ms));

function execute(command: string) {
  return new Promise<void>((resolve, reject) => {
    const onExit = (error: any) => {
      if (error) {
        return reject(error);
      }
      resolve();
    };
    spawn(command, {
      // Spawn process based on given command
      stdio: "inherit", // New process will be attached to parent terminal process
      shell: true,
    }).on("exit", onExit);
  });
}
