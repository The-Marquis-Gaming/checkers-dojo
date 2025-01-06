import { useState, useEffect } from "react";
import { useNavigate } from "react-router-dom";
import { SDK } from "@dojoengine/sdk";
import { schema } from "../bindings.ts";
import { useDojo } from "../hooks/useDojo.tsx";
import { useAccount } from "@starknet-react/core";
import { Account } from "starknet";
import ControllerButton from "../connector/ControllerButton";
import CreateBurner from "../connector/CreateBurner";

import LoadingRoom from "../assets/LoadingCreate.png";
import InitGameBackground from "../assets/InitGameBackground.png";
import Return from "../assets/Return.png";
import JoinGameRectangule from "../assets/JoinGameRectangule.png";
import ConfirmJoin from "../assets/ConfirmJoin.png";

function JoinRoom({}: { sdk: SDK<typeof schema> }) {
  const {
    setup: { setupWorld },
    account: { account: burner },
  } = useDojo();
  const { account } = useAccount();
  const navigate = useNavigate();
  const [error, setError] = useState<string | null>(null);
  const [isProcessing, setIsProcessing] = useState(false);

  const activeAccount = account || burner;

  useEffect(() => {
    if (!activeAccount?.address) {
      navigate("/");
    }
  }, [activeAccount, navigate]);

  const joinRoom = async () => {
    setIsProcessing(true);
    setError(null);

    try {
      if (!activeAccount?.address) {
        throw new Error("Account not connected");
      }

      await (await setupWorld.actions).joinLobby(activeAccount as Account, 0);
      localStorage.setItem("playerAddress", activeAccount.address);
      navigate("/creategame");
    } catch (error) {
      console.error("Error joining room:", error);
      setError(error instanceof Error ? error.message : "Failed to join room");
    } finally {
      setIsProcessing(false);
    }
  };

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
          window.location.href = "/";
        }}
        style={{
          position: "absolute",
          top: "20px",
          left: "20px",
          background: "none",
          border: "none",
          cursor: "pointer",
          zIndex: 2,
        }}
      >
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
        }}
      >
        <CreateBurner />
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
        }}
      >
        JOIN ROOM
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
        }}
      >
        <img
          src={LoadingRoom}
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
          bottom: "590px",
          left: "31%",
          transform: "translateX(-50%)",
          color: "white",
          fontSize: "24px",
          fontWeight: "bold",
          zIndex: 5,
        }}
      >
        Room ID
      </div>

      <div
        style={{
          position: "absolute",
          bottom: "450px",
          left: "50%",
          transform: "translateX(-50%)",
          width: "840px",
          height: "132px",
          backgroundImage: `url(${JoinGameRectangule})`,
          backgroundSize: "cover",
          display: "flex",
          alignItems: "center",
          justifyContent: "center",
          color: "white",
          fontSize: "24px",
          fontWeight: "bold",
          zIndex: 5,
        }}
      >
        0
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
          }}
        >
          {error}
        </div>
      )}

      <button
        onClick={joinRoom}
        disabled={isProcessing || !activeAccount?.address}
        style={{
          position: "absolute",
          bottom: "180px",
          left: "50%",
          transform: "translateX(-50%)",
          backgroundImage: `url(${ConfirmJoin})`,
          backgroundSize: "cover",
          width: "700px",
          height: "96px",
          color: "white",
          fontSize: "24px",
          fontWeight: "bold",
          cursor:
            isProcessing || !activeAccount?.address ? "not-allowed" : "pointer",
          border: "none",
          zIndex: 5,
          opacity: isProcessing || !activeAccount?.address ? 0.7 : 1,
        }}
      >
        {isProcessing ? "Processing..." : "Confirm"}
      </button>
    </div>
  );
}

export default JoinRoom;
