import { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { SDK } from "@dojoengine/sdk";
import { schema } from "../bindings.ts";
import ControllerButton from '../connector/ControllerButton';
import { useAccount } from '@starknet-react/core';

import LoadingCreate from "../assets/LoadingCreate.png";
import ChoicePlayer from "../assets/ChoicePlayer.png";
import ButtonCreate from "../assets/ButtonCreate.png";
import InitGameBackground from "../assets/InitGameBackground.png";
import Return from "../assets/Return.png";
import Player1 from "../assets/Player1_0.png";
import Player2 from "../assets/Player2_0.png";
import Player3 from "../assets/Player3_0.png";
import Player4 from "../assets/Player4_0.png";
import { useDojo } from '../hooks/useDojo.tsx';

function CreateGame({ }: { sdk: SDK<typeof schema> }) {
  const { account: burner } = useDojo();
  const {account} = useAccount();
  const navigate = useNavigate();
  const [selectedPlayer, setSelectedPlayer] = useState<number | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [isProcessing, setIsProcessing] = useState(false);

  const activeAccount = account || burner.account;

  useEffect(() => {
    if (!activeAccount.address) {
      navigate('/');
    }
  }, [activeAccount, navigate]);

  const handlePlayerSelect = (playerIndex: number) => {
    setSelectedPlayer(playerIndex);
    setError(null);
  };

  const handleCreateRoom = async () => {
    setIsProcessing(true);
    setError(null);

    try {
      if (!activeAccount.address) {
        throw new Error('Account not connected');
      }

      if (selectedPlayer === null) {
        throw new Error('Please select a player avatar');
      }

      localStorage.setItem('selectedPlayer', selectedPlayer.toString());
      localStorage.setItem('playerAddress', activeAccount.address);

      navigate('/checkers');
    } catch (error) {
      console.error("Error creating game:", error);
      setError(error instanceof Error ? error.message : 'Failed to create game');
    } finally {
      setIsProcessing(false);
    }
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
      }}>
      <div
        style={{
          position: "absolute",
          top: 0,
          left: 0,
          right: 0,
          bottom: 0,
          backgroundColor: "rgba(0, 0, 0, 0.5)",
          zIndex: 0,
        }}
      />

      <button
        onClick={() => {
          window.location.href = "/joinroom";
        }}
        style={{
          position: "absolute",
          top: "20px",
          left: "20px",
          background: "none",
          border: "none",
          cursor: "pointer",
          zIndex: 2,
        }}>
        <img
          src={Return}
          alt="Return"
          style={{
            width: "50px",
            height: "50px",
          }}
        />
      </button>

      <div
        style={{
          position: "absolute",
          top: "20px",
          right: "20px",
          display: "flex",
          gap: "20px",
          zIndex: 2,
        }}>
        <ControllerButton />
      </div>

      <div
        style={{
          position: "absolute",
          top: "150px",
          left: "16%",
          transform: "translateX(-50%)",
          color: "white",
          fontSize: "32px",
          fontWeight: "bold",
          zIndex: 5,
        }}>
        CREATE GAME
      </div>

      <div
        style={{
          position: "absolute",
          top: "200px",
          left: "50%",
          transform: "translateX(-50%)",
          width: "1500px",
          height: "10px",
          zIndex: 5,
        }}>
        <img
          src={LoadingCreate}
          alt="Loading"
          style={{
            width: "100%",
            height: "100%",
          }}
        />
      </div>

      <div
        style={{
          position: "absolute",
          top: "390px",
          left: "46%",
          transform: "translateX(-50%)",
          display: "flex",
          flexDirection: "column",
          alignItems: "center",
          zIndex: 5,
        }}>
        <span
          style={{
            color: "white",
            fontSize: "24px",
            fontWeight: "bold",
            marginBottom: "-40px",
          }}>
          CHOICE AVATAR
        </span>
        <img
          src={ChoicePlayer}
          alt="Choice Player"
          style={{
            width: "300px",
            height: "40px",
          }}
        />
      </div>

      <div
        style={{
          position: "absolute",
          top: "450px",
          left: "50%",
          transform: "translateX(-50%)",
          display: "flex",
          gap: "20px",
          zIndex: 2,
        }}>
        {playerImages.map((playerImage, index) => (
          <div
            key={index}
            onClick={() => handlePlayerSelect(index)}
            style={{
              width: "100px",
              height: "100px",
              borderRadius: "10px",
              border: `3px solid ${
                selectedPlayer === index ? "#EE7921" : "#520066"
              }`,
              backgroundImage: `url(${playerImage})`,
              backgroundSize: "cover",
              cursor: "pointer",
            }}
          />
        ))}
      </div>

      {error && (
        <div
          style={{
            position: "absolute",
            bottom: "300px",
            left: "50%",
            transform: "translateX(-50%)",
            color: "#ff4444",
            fontSize: "18px",
            zIndex: 5,
          }}>
          {error}
        </div>
      )}

      <button
        onClick={handleCreateRoom}
        disabled={isProcessing || selectedPlayer === null}
        style={{
          position: "absolute",
          bottom: "200px",
          left: "50%",
          transform: "translateX(-50%)",
          backgroundImage: `url(${ButtonCreate})`,
          backgroundSize: "cover",
          color: "white",
          padding: "46px 279px",
          borderRadius: "5px",
          fontWeight: "bold",
          cursor: isProcessing || selectedPlayer === null ? "not-allowed" : "pointer",
          border: "none",
          zIndex: 2,
          opacity: isProcessing || selectedPlayer === null ? 0.7 : 1,
        }}>
      </button>
    </div>
  );
}

export default CreateGame;