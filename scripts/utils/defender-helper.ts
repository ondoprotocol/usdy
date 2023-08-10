require("dotenv").config();
import { AdminClient, CreateProposalRequest } from "defender-admin-client";
import { Network } from "defender-base-client";

const getEnvVar = (value: string | undefined): string => {
  if (value === undefined) {
    throw new Error(value + " is undefined");
  }
  return value;
};
const getClient = async (): Promise<AdminClient> => {
  const apiKey: string = getEnvVar(process.env.ADMIN_API_KEY);
  const apiSecret: string = getEnvVar(process.env.ADMIN_API_SECRET);
  const client = new AdminClient({ apiKey: apiKey, apiSecret: apiSecret });
  return client;
};

export const addContract = async (
  network: Network,
  contract: Address,
  name: string,
  abi: string
) => {
  const client = await getClient();
  await client.addContract({
    network: network,
    address: contract,
    name: name,
    abi: abi,
  });
};

export const listContracts = async () => {
  const client = await getClient();
  const contracts = await client.listContracts();
  console.log(contracts);
};

export const deleteContract = async (name: string) => {
  const client = await getClient();
  await client.deleteContract(name);
};

export const proposeGrantRole = async (request: AccessControlRequest) => {
  const client = await getClient();
  await client.proposeGrantRole(
    request.params,
    request.contract,
    request.role,
    request.account
  );
};

export const proposeRevokeRole = async (request: AccessControlRequest) => {
  const client = await getClient();
  await client.proposeRevokeRole(
    request.params,
    request.contract,
    request.role,
    request.account
  );
};

export const proposeDeploy = async (request: ProposeTokenDeployRequest) => {
  await proposeFunctionCall({
    contract: request.contract,
    params: request.params,
    functionName: request.functionName,
    functionInterface: [
      { type: "string", name: "name" },
      { type: "string", name: "ticker" },
    ],
    functionInputs: [request.name, request.ticker],
  });
};

export const proposeDeployWithRegistry = async (
  request: ProposeTokenDeployWithRegistryRequest
) => {
  await proposeFunctionCall({
    contract: request.contract,
    params: request.params,
    functionName: request.functionName,
    functionInterface: [
      { type: "string", name: "name" },
      { type: "string", name: "ticker" },
      { type: "address", name: "registry" },
      { type: "uint256", name: "kycRequirementGroup" },
    ],
    functionInputs: [
      request.name,
      request.ticker,
      request.registry,
      request.kycRequirementGroup,
    ],
  });
};

export const proposeKYCAddressUpdate = async (
  request: ProposeKYCAddressUpdateRequest
) => {
  await proposeFunctionCall({
    contract: request.contract,
    params: request.params,
    functionName: request.functionName,
    functionInterface: [
      { type: "uint256", name: "kycRequirementGroup" },
      { type: "address[]", name: "addresses" },
    ],
    functionInputs: [request.kycRequirementGroup, request.addresses],
  });
};

export const ProposeAssignRoleToKYCGroup = async (
  request: ProposeAssignRoleToKYCGroupRequest
) => {
  await proposeFunctionCall({
    contract: request.contract,
    params: request.params,
    functionName: request.functionName,
    functionInterface: [
      { type: "uint256", name: "kycRequirementGroup" },
      { type: "bytes32", name: "role" },
    ],
    functionInputs: [request.kycRequirementGroup, request.role],
  });
};

export const proposeFunctionCall = async (
  request: ProposeFunctionCallRequest
) => {
  const client = await getClient();
  await client.createProposal({
    contract: request.contract,
    title: `${request.params.title}`,
    description: `${request.params.description}`,
    functionInterface: {
      name: request.functionName,
      inputs: request.functionInterface,
    },
    functionInputs: request.functionInputs,
    via: request.params.via,
    viaType: request.params.viaType,
    type: "custom",
  });
};

type Address = string;

export type BaseProposalRequestParams = {
  title?: string;
  description?: string;
  via: Address;
  viaType: CreateProposalRequest["viaType"];
};

export type ProposeFunctionCallRequest = {
  contract: CreateProposalRequest["contract"];
  params: BaseProposalRequestParams;
  functionName: string;
  functionInterface: any[];
  functionInputs: any[];
};

export type AccessControlRequest = {
  params: BaseProposalRequestParams;
  contract: CreateProposalRequest["contract"];
  role: string;
  account: Address;
};

export type ProposeTokenDeployRequest = {
  params: BaseProposalRequestParams;
  contract: CreateProposalRequest["contract"];
  name: string;
  ticker: string;
  functionName: string;
};

export type ProposeTokenDeployWithRegistryRequest = {
  params: BaseProposalRequestParams;
  contract: CreateProposalRequest["contract"];
  name: string;
  ticker: string;
  registry: Address;
  kycRequirementGroup: string;
  functionName: string;
};

export type ProposeAssignRoleToKYCGroupRequest = {
  params: BaseProposalRequestParams;
  contract: CreateProposalRequest["contract"];
  kycRequirementGroup: string;
  role: string;
  functionName: string;
};

export type ProposeKYCAddressUpdateRequest = {
  params: BaseProposalRequestParams;
  contract: CreateProposalRequest["contract"];
  addresses: Address[];
  kycRequirementGroup: string;
  functionName: string;
};
