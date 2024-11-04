import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import CreateBurner from "../connector/CreateBurner"; 
// import useDojoConnect from "../hooks/useDojoConnect"; 
import InitGameBackground from "../assets/InitGameBackground.png"; 
import { SDK, createDojoStore } from "@dojoengine/sdk"; 
import Witch from "../assets/Witch.png";
import CreateGame from "../assets/CreateGame.png";
import CreateGame4 from "../assets/CreateGame4.png";
import CreateGame2 from "../assets/CreateGame2.png";
import CreateGame3 from "../assets/CreateGame3.png";
import JoinGame2 from "../assets/JoinGame2.png"; 
import JoinGame from "../assets/JoinGame.png";
import ControllerButton from '../connector/ControllerButton';
import Title from '../assets/Title.png';
import { schema } from "../bindings.ts";
import { useSystemCalls } from "../hooks/useSystemCalls.ts";
import { useDojo } from "../hooks/useDojo.tsx";

export const useDojoStore = createDojoStore<typeof schema>();

function InitGame({ sdk }: { sdk: SDK<typeof schema> }) {

	const {
        account,
        //setup: { setupWorld },
    } = useDojo();

	// const state = useDojoStore((state) => state);
    // const entities = useDojoStore((state) => state.entities);
const { spawn } = useSystemCalls();
  const navigate = useNavigate();

  // Estado para controlar el brillo y zoom de las imágenes
  const [hoveredImage, setHoveredImage] = useState<null | 'create5' | 'join'>(null);

  // Lógica para manejar la conexión de la wallet y crear el juego
  const handleCreateGame = async () => {
    try {
      if (account) {
        await spawn(); 
        console.log("Juego creado con éxito.");
        navigate('/checkers'); 
      } else {
        console.warn("Cuenta no conectada");
      }
    } catch (error) {
      console.error("Error al crear el juego:", error);
    }
  };

  const handleMouseEnterCreate5 = () => {
    setHoveredImage('create5');
  };

  const handleMouseLeaveCreate5 = () => {
    setHoveredImage(null);
  };

  const handleMouseEnterJoin = () => {
    setHoveredImage('join');
  };

  const handleMouseLeaveJoin = () => {
    setHoveredImage(null);
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
      {/* Capa oscura superpuesta solo sobre la imagen de fondo */}
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
      
      {/* Título */}
      <img
        src={Title}
        alt="Título"
        style={{
          zIndex: 2,
          marginTop: '60px',
          width: 'auto',
          height: '100px', // Ajusta la altura según sea necesario
        }}
      />

      {/* Parte de conexión con los botones */}
      <div style={{ 
        zIndex: 2, 
        marginTop: '20px', 
        display: 'flex', 
        justifyContent: 'center', // Centra horizontalmente
        width: '100%', 
      }}>
        <CreateBurner />
        <ControllerButton />
      </div>

      {/* Imágenes adicionales centradas con efecto hover */}
      <img
        src={CreateGame4}
        alt="Crear Juego 1"
        onClick={handleCreateGame}
        style={{
          position: 'absolute',
          top: '45%',
          left: '30%',
          transform: 'translate(-50%, -50%)',
          width: '60px',
          height: 'auto',
          zIndex: 2,
          cursor: 'pointer',
          filter: 'brightness(1)',
        }}
      />
      <img
        src={CreateGame}
        alt="Crear Juego"
        onClick={handleCreateGame}
        style={{
          position: 'absolute',
          top: '45%',
          left: '50%',
          transform: 'translate(-50%, -50%) scale(' + (hoveredImage === 'create5' ? '1.1' : '1') + ')', // Efecto de zoom
          width: '400px',
          height: 'auto',
          zIndex: 2,
          cursor: 'pointer',
          filter: hoveredImage === 'create5' ? 'brightness(1.2)' : 'brightness(1)', // Aumenta brillo en hover
        }}
      />
      <img
        src={CreateGame2}
        alt="Crear Juego 2"
        onClick={handleCreateGame}
        style={{
          position: 'absolute',
          top: '45%',
          left: '50%',
          transform: 'translate(-50%, -50%)',
          width: '700px',
          height: 'auto',
          zIndex: 2,
          cursor: 'pointer',
          filter: 'brightness(1)',
        }}
      />
      <img
        src={CreateGame3}
        alt="Crear Juego 3"
        onClick={handleCreateGame}
        style={{
          position: 'absolute',
          top: '45%',
          left: '30%',
          transform: 'translate(-50%, -50%)',
          width: '300px',
          height: 'auto',
          zIndex: 2,
          cursor: 'pointer',
          filter: 'brightness(0.5)',
        }}
      />
      
      {/* Imagen de Crear Juego 5 */}
      <img
        src={JoinGame2}
        alt="Crear Juego 5"
        onMouseEnter={handleMouseEnterCreate5}
        onMouseLeave={handleMouseLeaveCreate5}
        onClick={handleCreateGame}
        style={{
          position: 'absolute',
          top: '70%',
          left: '30%',
          transform: 'translate(-48%, -50%) scale(' + (hoveredImage === 'create5' || hoveredImage === 'join' ? '1.1' : '1') + ')', // Efecto de zoom
          width: '300px',
          height: 'auto',
          zIndex: 99,
          cursor: 'pointer',
          filter: hoveredImage === 'create5' || hoveredImage === 'join' ? 'brightness(1.2)' : 'brightness(0.5)', // Oscuro si no está en hover
          transition: 'transform 0.2s',
        }}
      />
      
      {/* Imagen de la bruja centrada */}
      <img
        src={Witch}
        alt="Bruja"
        style={{
          position: 'absolute',
          top: '50%',
          left: '70%',
          transform: 'translate(-50%, -50%)',
          width: '450px',
          height: 'auto',
          zIndex: 2,
        }}
      />

      {/* Imagen de Unirse al juego */}
      <img
        src={JoinGame}
        alt="Unirse al juego"
        onMouseEnter={handleMouseEnterJoin}
        onMouseLeave={handleMouseLeaveJoin}
        style={{
          position: 'absolute',
          top: '70%',
          left: '50%',
          transform: 'translate(-50%, -50%) scale(' + (hoveredImage === 'create5' || hoveredImage === 'join' ? '1.1' : '1') + ')', // Efecto de zoom
          width: '950px',
          height: 'auto',
          zIndex: 2,
          cursor: 'pointer',
          filter: hoveredImage === 'create5' || hoveredImage === 'join' ? 'brightness(1.2)' : 'brightness(1)', // Ilumina si está en hover
          transition: 'transform 0.2s',
        }}
        onClick={() => {
          // Aquí puedes definir la lógica para "Unirse al juego" si es necesario
        }}
      />
    </div>
  );
};

export default InitGame;
