import { useAccount } from "@starknet-react/core";
import { useDojoStore } from "../components/Checker";
import { useDojo } from "./useDojo";
import { Account } from "starknet";

export const useSystemCalls = () => {

    const {
        setup: { setupWorld },
        // account: { account },
    } = useDojo();
    const {account} = useAccount();


    const createLobby = async () =>{
        try {
          const createLobby = await(await setupWorld.actions).createLobby(
            (account as Account)
          );
          return createLobby;
        } catch (error) {
          throw new Error(`createLobby failed: ${error}`);
        } 
    }

    const getSessionId= async()=>{
      try{
        const id= await (await setupWorld.actions).getSessionId((account as Account));
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