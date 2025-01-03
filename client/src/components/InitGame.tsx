import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { SDK, createDojoStore } from "@dojoengine/sdk";
import { schema } from "../bindings.ts";
import { useSystemCalls } from "../hooks/useSystemCalls.ts";
import { useDojo } from "../hooks/useDojo.tsx";
import ControllerButton from '../connector/ControllerButton';
import CreateBurner from '../connector/CreateBurner.tsx';

import InitGameBackground from "../assets/InitGameBackground.png";
import CreateGame from "../assets/CreateGame.png";
import CreateGame2 from "../assets/CreateGame2.png";
import JoinGame from "../assets/JoinGame.png";
import JoinGame2 from "../assets/JoinGame2.png";
import Return from "../assets/Return.png";
import Title from '../assets/Title.png';
import { useAccount } from '@starknet-react/core';

export const useDojoStore = createDojoStore<typeof schema>();

function InitGame({ }: { sdk: SDK<typeof schema> }) {
  // const { account } = useDojo();
  const {account} = useAccount();
  const { getSessionId,createLobby } = useSystemCalls();
  const navigate = useNavigate();
  const [isHoveredCreate, setIsHoveredCreate] = useState(false);
  const [isHoveredJoin, setIsHoveredJoin] = useState(false);

  const handleCreateGame = async () => {
    try {
      if (account) {
      const lobby = await createLobby();
      const id = await getSessionId();
      console.log(lobby, "createLobby", id, "id");
        return id
      } else {
        console.warn("Account not connected");
      }
    } catch (error) {
      console.error("Error creating the game:", error);
    } finally {
      navigate("/joinroom");
    }
  };

  return (
    <div
      style={{
        backgroundImage: `url(${InitGameBackground})`,
        backgroundSize: "cover",
        backgroundPosition: "center",
        height: "100vh",
        display: "flex",
        flexDirection: "column",
        alignItems: "center",
        justifyContent: "flex-start",
        position: "relative",
        overflow: "hidden",
      }}
    >
      <div
        style={{
          position: 'absolute',
          top: 0,
          left: 0,
          right: 0,
          bottom: 0,
          backgroundColor: 'rgba(0, 0, 0, 0.5)',
          zIndex: 0,
        }}
      />

      <img
        src={Title}
        alt="Título"
        style={{
          zIndex: 2,
          marginTop: '60px',
          width: 'auto',
          height: '100px',
        }}
      />

      <button
        onClick={() => {
          window.location.href = 'http://localhost:3000';
        }}
        style={{
          position: 'absolute',
          top: '20px',
          left: '20px',
          background: 'none',
          border: 'none',
          cursor: 'pointer',
          zIndex: 2,
        }}
      >
        <img
          src={Return}
          alt="Return"
          style={{
            width: '50px',
            height: '50px',
          }}
        />
      </button>

      <div
        style={{
          position: 'absolute',
          top: '20px',
          right: '20px',
          display: 'flex',
          gap: '20px',
          zIndex: 2,
        }}
      >
        <CreateBurner/>
        <ControllerButton />
      </div>

      {/* Button to create game */}
      <img
        src={isHoveredCreate ? CreateGame2 : CreateGame}
        alt={account ? "Crear Juego" : "Conectar cuenta"}
        onClick={account ? handleCreateGame : undefined}
        onMouseEnter={() => setIsHoveredCreate(true)}
        onMouseLeave={() => setIsHoveredCreate(false)}
        style={{
          position: 'absolute',
          top: '40%',
          left: '50%',
          transform: `translate(-50%, -50%) scale(${isHoveredCreate ? 1.3 : 1})`, // Zoom hacia adelante
          width: '700px',
          height: 'auto',
          zIndex: 2,
          cursor: account ? 'pointer' : 'not-allowed',
          transition: 'transform 0.2s',
          opacity: account ? 1 : 0.5,
        }}
      />

      {/* Button to join game */}
      <img
        src={isHoveredJoin ? JoinGame2 : JoinGame}
        alt="join game"
        onMouseEnter={() => setIsHoveredJoin(true)}
        onMouseLeave={() => setIsHoveredJoin(false)}
        style={{
          position: 'absolute',
          top: '60%',
          left: '50%',
          transform: `translate(-50%, -50%) scale(${isHoveredJoin ? 1.3 : 1})`,
          width: '700px',
          height: 'auto',
          zIndex: 2,
          cursor: 'pointer',
          transition: 'transform 0.2s',
        }}
      />
    </div>
  );
}

export default InitGame;