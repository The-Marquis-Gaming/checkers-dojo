import { useAccount } from "@starknet-react/core";
import { useDojoStore } from "../components/Checker";
import { useDojo } from "./useDojo";
import { Account } from "starknet";

export const useSystemCalls = () => {

    const {
        setup: { setupWorld },
         account: { account: burner },
    } = useDojo();
    const {account} = useAccount();


    const createLobby = async () => {
      try {
          const activeAccount = account || burner;
          
          if (!activeAccount) {
              throw new Error('No valid account found');
          }
  
          const createLobby = await (await setupWorld.actions).createLobby(
              activeAccount as Account
          );
          return createLobby;
      } catch (error) {
          throw new Error(`createLobby failed: ${error}`);
      }
  };

    const getSessionId= async()=>{
      try{
        const activeAccount = account || burner;

        const id= await (await setupWorld.actions).getSessionId((activeAccount as Account));
        console.log(id,'id')
        return id
      } catch(err){
        throw new Error(`getSessionId failed: ${err}`);
      }
    }

    return {
      createLobby,
      getSessionId,
    };
};