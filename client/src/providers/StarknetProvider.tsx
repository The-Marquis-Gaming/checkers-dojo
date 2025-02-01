'use client'

import {StarknetConfig, starkscan} from "@starknet-react/core";
import {PropsWithChildren} from "react";
import {sepolia} from "@starknet-react/chains";
import {ControllerConnector} from "@cartridge/connector";
import {Connector} from "@starknet-react/core";
import {constants, RpcProvider} from "starknet";
import manifest from "../../../dojo-starter/manifest_slot_1.json";
import {getContractByName} from "@dojoengine/core";
import {SessionPolicies} from "@cartridge/controller";


const checkersContract = getContractByName(manifest, "checkers_marq", "actions")?.address;

const policies: SessionPolicies = {
    contracts: {
        [checkersContract]: {
            methods: [
                {name: "move_piece", entrypoint: "move_piece"},
                {name: "create_lobby", entrypoint: "create_lobby"},
                {name: "join_lobby", entrypoint: "join_lobby"},
                {name: "spawn", entrypoint: "spawn"},
                {name: "can_choose_piece", entrypoint: "can_choose_piece"},
                {name: "get_session_id", entrypoint: "get_session_id"},
            ],
        },
    }
}

export const connector = new ControllerConnector({
    policies,
    chains: [
        {
            rpcUrl: "https://api.cartridge.gg/x/starknet/sepolia",
        },
    ],
    defaultChainId: constants.StarknetChainId.SN_SEPOLIA,
}) as never as Connector;

function provider() {
    return new RpcProvider({
        nodeUrl: "https://api.cartridge.gg/x/checkers-scaffold-1/katana",
    });
}

export function StarknetProvider({children}: PropsWithChildren) {
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
