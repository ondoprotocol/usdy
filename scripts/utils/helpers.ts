import { assert } from "console";
import { Contract } from "ethers";
import { FAILURE_CROSS } from "./shell";

export async function assertAgainstBlockchain(
  contract: Contract,
  name: string,
  data: any
) {
  // console.log((await contract[name].apply()).toString());
  assert(
    (await contract[name].apply()) == data[name],
    FAILURE_CROSS + ` ${name} check failed`
  );
}

export async function assertRoleMembers(
  contract: Contract,
  roleBytes: string,
  memberArray: string[]
) {
  assert(
    (await contract.getRoleMemberCount(roleBytes)) == memberArray.length,
    FAILURE_CROSS + `${roleBytes} role check failed`
  );
  for (let i = 0; i < memberArray.length; ++i) {
    assert(memberArray[i] == (await contract.getRoleMember(roleBytes, i)));
  }
}

export async function addressFromStorageSlot(
  contractAddress: string,
  slot: string
): Promise<string> {
  const word = (
    await ethers.provider.getStorageAt(contractAddress, slot)
  ).toString();
  // In EVM, a word is 32 bytes (256 bits), so we ensure the first 12 bytes
  // are all zero.
  assert(
    word.slice(0, 26) == "0x000000000000000000000000",
    "Can't extract address, bits found in beginning of word"
  );
  return ethers.utils.getAddress("0x" + word.toString().slice(26));
}
