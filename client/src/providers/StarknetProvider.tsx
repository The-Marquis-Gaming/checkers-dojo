'use client'

import { StarknetConfig,starkscan } from "@starknet-react/core";
import { PropsWithChildren } from "react";
import { sepolia} from "@starknet-react/chains";


import {ControllerConnector} from "@cartridge/connector";
import { Connector } from "@starknet-react/core";
import { RpcProvider } from "starknet";
import manifest from "../../../dojo-starter/manifest_dev.json"
import { getContractByName } from "@dojoengine/core";
// Aquí definimos la dirección del contrato y otras políticas si es necesario
const ETH_TOKEN_ADDRESS =
  "0x049d36570d4e46f48e99674bd3fcc84644ddd6b96f7c741b1562b82f9e004dc7";

// Configuramos el conector

const checkersContract = getContractByName(manifest, "checkers_marq", "actions")?.address;
export const connector = new ControllerConnector({
  policies: [
    {
      target: ETH_TOKEN_ADDRESS,
      method: "approve",
      description: "Permite aprobación de transferencias.",
    },
    {
      target: ETH_TOKEN_ADDRESS,
      method: "transfer",
    },
    {
      target: checkersContract,
      method: "move_piece",
    },
    {
      target: checkersContract,
      method: "create_lobby",
    },
    {
      target: checkersContract,
      method: "join_lobby",
    },
    {
      target: checkersContract,
      method: "spawn",
    },
    {
      target: checkersContract,
      method: "can_choose_piece",
    },
    {
      target: checkersContract,
      method: "get_session_id",
    },
  ],
  rpc: "https://api.cartridge.gg/x/checkers-controller-1/katana",
}) as never as Connector;

function provider() {
  return new RpcProvider({
    nodeUrl: "https://api.cartridge.gg/x/checkers-controller-1/katana",
  });
}

export function StarknetProvider({ children }: PropsWithChildren) {
  console.log(checkersContract, "first contract");

  return (
    <StarknetConfig
      autoConnect
      chains={[sepolia]}
      connectors={[connector]}
      explorer={starkscan}
      provider={provider}>
      {children}
    </StarknetConfig>
  );
}
