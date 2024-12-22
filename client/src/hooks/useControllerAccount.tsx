"use client";

import { useEffect, useState } from "react";
import {ControllerConnector} from "@cartridge/connector";
import { ControllerOptions, ControllerAccounts } from "@cartridge/controller";

const ETH_TOKEN_ADDRESS = "0x049d36570d4e46f48e99674bd3fcc84644ddd6b96f7c741b1562b82f9e004dc7";

const useControllerAccount = () => {
  const [connector, setConnector] = useState<ControllerConnector | null>(null);
  const [userAccountController, setUserAccount] = useState<string | null>(null);
  const [userName, setUserName] = useState<string | null>(null);
  const [isConnected, setIsConnected] = useState(false);
  const [usernames, setUsernames] = useState<ControllerAccounts>({});

  useEffect(() => {
    const controllerOptions: ControllerOptions = {
      policies: [
        {
          target: ETH_TOKEN_ADDRESS,
          method: "approve",
          description: "Allow transactions in the game",
        },
        {
          target: ETH_TOKEN_ADDRESS,
          method: "transfer",
        },
      ],
      rpc: "https://starknet-sepolia.public.blastapi.io/rpc/v0_7",
      theme: "scaffold-stark",
      colorMode: "dark",
    };

    const controllerConnector = new ControllerConnector(controllerOptions);
    setConnector(controllerConnector);
  }, []);

  const handleConnect = async () => {
    if (!connector) return;

    try {
      const account = await connector.controller.connect();
      if (account) {
        setUserAccount(account.address);
        setIsConnected(true);

        const name = await connector.controller.username();
        setUserName(name || null);
      }
    } catch (error) {
      console.error("Connection error:", error);
    }
  };

  const handleDisconnect = async () => {
    if (!connector) return;

    try {
      await connector.controller.disconnect();
      setUserAccount(null);
      setUserName(null);
      setIsConnected(false);
      console.log("Disconnected successfully.");
    } catch (error) {
      console.error("Disconnection error:", error);
    }
  };

  // New function to fetch multiple usernames
  const fetchUsernames = async (addresses: string[]) => {
    if (!connector) return;

    try {
      const usernames = await connector.controller.fetchControllers(addresses);
      setUsernames(usernames);
    } catch (error) {
      console.error("Error fetching usernames:", error);
    }
  };

  return {
    userAccountController,
    userName,
    isConnected,
    handleConnect,
    handleDisconnect,
    fetchUsernames,
    usernames,
  };
};

export default useControllerAccount;
