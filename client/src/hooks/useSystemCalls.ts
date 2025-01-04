import { useAccount } from "@starknet-react/core";
import { useDojoStore } from "../components/Checker";
import { useDojo } from "./useDojo";
import { Account } from "starknet";

export const useSystemCalls = () => {
    const {
        setup: { setupWorld },
        account: { account: burner },
    } = useDojo();
    const { account } = useAccount();

    const getActiveAccount = () => {
        const activeAccount = account || burner;
        if (!activeAccount?.address) {
            throw new Error('No valid account found. Please connect your wallet or create a burner account.');
        }
        return activeAccount as Account;
    };

    const createLobby = async () => {
        try {
            const activeAccount = getActiveAccount();
            const createLobbyResult = await (await setupWorld.actions).createLobby(
                activeAccount
            );
            return createLobbyResult;
        } catch (error) {
            const errorMessage = error instanceof Error ? error.message : 'Unknown error occurred';
            throw new Error(`Failed to create lobby: ${errorMessage}`);
        }
    };

    const getSessionId = async () => {
        try {
            const activeAccount = getActiveAccount();
            const sessionId = await (await setupWorld.actions).getSessionId(activeAccount);
            console.log('Session ID:', sessionId);
            return sessionId;
        } catch (error) {
            const errorMessage = error instanceof Error ? error.message : 'Unknown error occurred';
            throw new Error(`Failed to get session ID: ${errorMessage}`);
        }
    };

    return {
        createLobby,
        getSessionId,
    };
};