import { sleep } from "./shell";
import { ethers, network } from "hardhat";
import { BigNumber, BigNumberish } from "ethers";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/dist/src/signers";
import fetch from "node-fetch";
import { USDC_MAINNET } from "../../deploy/mainnet_constants";
import { ERC20 } from "../../typechain";

async function getBlockNumber(nodeURL: string): Promise<boolean> {
  const getBlock = {
    jsonrpc: "2.0",
    method: "eth_blockNumber",
    params: [],
    id: 1,
  };
  try {
    const data = await fetch(nodeURL, {
      method: "POST",
      headers: { "content-type": "application/json" },
      body: JSON.stringify(getBlock),
    });
    const json = await data.json();
    console.log("Response: " + JSON.stringify(json));
    return true;
  } catch (error) {
    if (error instanceof Error) {
      console.log("Unable to query node, error:", error.message);
    }
    return false;
  }
}
export async function waitNSecondsUntilNodeUp(
  nodeURL: string,
  seconds: number
) {
  while (seconds) {
    console.log("Pinging eth node...");
    const nodeUp: boolean = await getBlockNumber(nodeURL);
    if (nodeUp) {
      return;
    }
    await sleep(1000);
    --seconds;
  }
  throw new Error("Unable to contact node in a timely manner.");
}

export const increaseBlockTimestamp = async (seconds: number, mine = false) => {
  await network.provider.send("evm_increaseTime", [Math.floor(seconds)]);
  if (mine) {
    await network.provider.send("evm_mine", []);
  }
};

export const getImpersonatedSigner = async (
  account: string
): Promise<SignerWithAddress> => {
  await network.provider.request({
    method: "hardhat_impersonateAccount",
    params: [account],
  });
  return ethers.getSigner(account);
};

export const setUSDCBalance = async (
  signer: SignerWithAddress,
  usdcWhale: SignerWithAddress,
  balance: BigNumberish
) => {
  const usdcContract: ERC20 = await ethers.getContractAt("ERC20", USDC_MAINNET);
  const originalBalance = await usdcContract.balanceOf(signer.address);
  // Do nothing if signer already has correct balance.
  if (originalBalance.eq(balance)) return;

  // If the signer has more USDC than balance param,
  // send the necessary amount to the whale address.
  if (originalBalance.gt(balance)) {
    await usdcContract
      .connect(signer)
      .transfer(usdcWhale.address, originalBalance.sub(balance));
    return;
  }
  // If the signer has less USDC than balance param, send the difference
  // to the signer from the "impersonated" whale.
  await usdcContract
    .connect(usdcWhale)
    .transfer(signer.address, BigNumber.from(balance).sub(originalBalance));
};
