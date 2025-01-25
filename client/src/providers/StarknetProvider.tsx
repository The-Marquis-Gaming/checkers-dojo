'use client'

import { StarknetConfig,starkscan } from "@starknet-react/core";
import { PropsWithChildren } from "react";
import { sepolia} from "@starknet-react/chains";


import {ControllerConnector} from "@cartridge/connector";
import { Connector } from "@starknet-react/core";
import { RpcProvider } from "starknet";
import manifest from "../../../dojo-starter/manifest_slot_1.json";
import { getContractByName } from "@dojoengine/core";



const checkersContract = getContractByName(manifest, "checkers_marq", "actions")?.address;
export const connector = new ControllerConnector({
  policies: [
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
  rpc: "https://api.cartridge.gg/x/checkers-scaffold-1/katana",
}) as never as Connector;

function provider() {
  return new RpcProvider({
    nodeUrl: "https://api.cartridge.gg/x/checkers-scaffold-1/katana",
  });
}

export function StarknetProvider({ children }: PropsWithChildren) {
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
