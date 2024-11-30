import React, { useEffect, useState } from "react";
import Cartridge from "../assets/Cartridge.png";
import { useAccount, useConnect, useDisconnect } from "@starknet-react/core";

const ControllerButton: React.FC = () => {

  const { connect, connectors } = useConnect();
  const { disconnect } = useDisconnect();
  const { address } = useAccount();

  const connector = connectors[0];
  const [userName, setUserName] = useState<string>();
  const [isConnected, setIsConnected] = useState(false);

  useEffect(() => {
    if (!address) return;
    (connector as any).username()?.then((name: string) => {
      setUserName(name), setIsConnected(true);
    });
    console.log(userName, "USERnAaaME", address, "addres");
  }, [address, connector]);

  const [isMenuOpen, setIsMenuOpen] = useState(false);

  const toggleMenu = () => {
    setIsMenuOpen(!isMenuOpen);
  };

  // Recortar la dirección de la cuenta para una visualización más clara
  const slicedAddress = address
    ? `${address.slice(0, 6)}...${address.slice(-4)}`
    : "Conectar";

  return (
    <div className="relative">
      {/* Botón principal */}
      <button
        onClick={
          isConnected ? toggleMenu : () => connect({ connector })
        }
        className="flex items-center rounded-md overflow-hidden font-bold cursor-pointer pl-2"
        style={{
          background: "linear-gradient(to right, #EE7921 40%, #520066 40%)",
          color: "white",
          width: "220px",
          height: "45px",
          borderRadius: "8px",
          boxShadow: "0px 4px 8px rgba(0, 0, 0, 0.1)",
        }}>
        <img
          src={Cartridge}
          alt="User Icon"
          className="h-8 w-8 rounded-full"
          style={{
            marginRight: "45px",
            marginLeft: "15px",
          }}
        />
        <span
          className="flex-grow text-center"
          style={{
            lineHeight: "45px",
            fontWeight: "bold",
          }}>
          {isConnected ? userName || "Conectado" : "Conectar"}
        </span>
        <span
          className={`transform transition-transform duration-300 ${
            isMenuOpen ? "rotate-180" : ""
          }`}
          style={{ marginRight: "10px" }}>
          ▼
        </span>
      </button>

      {/* Menú desplegable */}
      {isMenuOpen && isConnected && (
        <div
          className="absolute mt-2 p-4 rounded-md shadow-lg"
          style={{
            backgroundColor: "#2C2F33",
            border: "1px solid #520066",
            color: "white",
            width: "220px",
          }}>
          <div className="flex justify-between items-center mb-2">
            <p className="text-sm">
              <strong>Usuario:</strong>{" "}
              <span style={{ fontWeight: "normal" }}>
                {userName || "Sin nombre"}
              </span>
            </p>
          </div>

          <div className="flex items-center justify-between mb-2">
            <p className="text-sm font-semibold">
              <strong>Dirección:</strong>{" "}
              <span style={{ fontWeight: "normal" }}>
                {slicedAddress || "Sin nombre"}
              </span>
            </p>
            <button
              onClick={() => navigator.clipboard.writeText(address || "")}
              className="ml-2 text-white hover:text-gray-400 transition duration-300"
              title="Copiar Dirección">
              <svg
                xmlns="http://www.w3.org/2000/svg"
                className="h-4 w-4"
                fill="none"
                viewBox="0 0 24 24"
                stroke="currentColor">
                <path
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  strokeWidth="2"
                  d="M8 16H6a2 2 0 01-2-2V6a2 2 0 012-2h8a2 2 0 012 2v2m4 4v6a2 2 0 01-2 2h-8a2 2 0 01-2-2v-6a2 2 0 012-2h8a2 2 0 012 2z"
                />
              </svg>
            </button>
          </div>

          <button
            onClick={() => {disconnect(), setIsConnected(false),toggleMenu()}}
            className="w-full bg-[#520066] hover:bg-[#6A0080] text-white font-bold py-2 rounded-md transition duration-300 ease-in-out">
            Desconectar
          </button>
        </div>
      )}
    </div>
  );
};

export default ControllerButton;
