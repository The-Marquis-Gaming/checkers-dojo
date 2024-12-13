import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import CreateBurner from "../connector/CreateBurner";
import { SDK } from "@dojoengine/sdk";
import { schema } from "../bindings.ts";
import ControllerButton from '../connector/ControllerButton';
// import { useDojo } from "../hooks/useDojo";

import LoadingCreate from "../assets/LoadingCreate.png";
import ChoicePlayer from "../assets/ChoicePlayer.png";
import ButtonCreate from "../assets/ButtonCreate.png";

import InitGameBackground from "../assets/InitGameBackground.png";
import Return from "../assets/Return.png";
import Player1 from "../assets/Player1_0.png";
import Player2 from "../assets/Player2_0.png";
import Player3 from "../assets/Player3_0.png";
import Player4 from "../assets/Player4_0.png";
import { useAccount } from '@starknet-react/core';
//TODO:VER DE QUE HACER CON ESTA PAG

function CreateGame({ }: { sdk: SDK<typeof schema> }) {
  // const { account } = useDojo();
  const account = useAccount();
  // const { createLobby } = useSystemCalls();
  const navigate = useNavigate();
  const [selectedPlayer, setSelectedPlayer] = useState<number | null>(null);

  const handleCreateRoom = async () => {
    try {
      if (account) {
       
        navigate('/checkers');
      } else {
        console.warn("Cuenta no conectada");
      }
    } catch (error) {
      console.error("Error al crear el juego:", error);
    }
  };

  const handlePlayerSelect = (playerIndex: number) => {
    setSelectedPlayer(playerIndex);
  };

  const playerImages = [Player1, Player2, Player3, Player4];

  return (
    <div
      style={{
        backgroundImage: `url(${InitGameBackground})`,
        backgroundSize: "cover",
        backgroundPosition: "center",
        height: "100vh",
        position: "relative",
        overflow: "hidden",
      }}
    >
      {/* Filtro de fondo oscuro */}
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

      {/* Botón de "Return" */}
      <button
        onClick={() => {
          window.location.href = '/joinroom'; 
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

      {/* Sección superior derecha con CreateBurner y ControllerButton */}
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
        <ControllerButton />
        <CreateBurner />
      </div>

      {/* Texto "Join Room" sobre la barra de carga */}
      <div
        style={{
          position: 'absolute',
          top: '150px',
          left: '16%',
          transform: 'translateX(-50%)',
          color: 'white',
          fontSize: '32px',
          fontWeight: 'bold',
          zIndex: 5,
        }}
      >
        JOIN ROOM
      </div>

      {/* Barra de carga */}
      <div
        style={{
          position: 'absolute',
          top: '200px',
          left: '50%',
          transform: 'translateX(-50%)',
          width: '1500px',
          height: '10px',
          zIndex: 5,
        }}
      >
        <img
          src={LoadingCreate}
          alt="Cargando"
          style={{
            width: '100%',
            height: '100%',
          }}
        />
      </div>

      {/* ChoicePlayer */}
      <div
        style={{
          position: 'absolute',
          top: '390px',
          left: '46%',
          transform: 'translateX(-50%)',
          display: 'flex',
          flexDirection: 'column',
          alignItems: 'center',
          zIndex: 5,
        }}
      >
        <span
          style={{
            color: 'white',
            fontSize: '24px',
            fontWeight: 'bold',
            marginBottom: '-40px',
          }}
        >
          CHOICE AVATAR
        </span>
        <img
          src={ChoicePlayer}
          alt="Choice Player"
          style={{
            width: '300px',
            height: '40px',
          }}
        />
      </div>

      {/* Selección de jugadores */}
      <div
        style={{
          position: 'absolute',
          top: '450px',
          left: '50%',
          transform: 'translateX(-50%)',
          display: 'flex',
          gap: '20px',
          zIndex: 2,
        }}
      >
        {playerImages.map((playerImage, index) => (
          <div
            key={index}
            onClick={() => handlePlayerSelect(index)}
            style={{
              width: '100px',
              height: '100px',
              borderRadius: '10px',
              border: `3px solid ${selectedPlayer === index ? '#EE7921' : '#520066'
                }`,
              backgroundImage: `url(${playerImage})`,
              backgroundSize: 'cover',
              cursor: 'pointer',
            }}
          />
        ))}
      </div>

      {/* Botón de "Create Game" */}
      <button
        onClick={handleCreateRoom}
        style={{
          position: 'absolute',
          bottom: '200px',
          left: '50%',
          transform: 'translateX(-50%)',
          backgroundImage: `url(${ButtonCreate})`,
          backgroundSize: 'cover',
          color: 'white',
          padding: '46px 279px',
          borderRadius: '5px',
          fontWeight: 'bold',
          cursor: 'pointer',
          border: 'none',
          zIndex: 2,
        }}
      >
      </button>
    </div>
  );
}

export default CreateGame;