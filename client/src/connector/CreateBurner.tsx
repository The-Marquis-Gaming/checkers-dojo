import React, { useState, useEffect } from "react";
import { useDojo } from "../hooks/useDojo.tsx";
import ConnectWallet from "../assets/ConnectWallet.png";

const CreateBurner: React.FC = () => {
  const { account } = useDojo();
  const [isDropdownOpen, setIsDropdownOpen] = useState(false);
  const [burnerList, setBurnerList] = useState<string[]>([]);

  useEffect(() => {
    if (account) {
      updateBurnerList();
    }
  }, [account]);

  const updateBurnerList = () => {
    if (account?.list) {
      setBurnerList(account.list().map(acc => acc.address));
    }
  };

  const handleCreateBurner = async () => {
    try {
      if (account?.create) {
        await account.create();
        updateBurnerList();
      }
    } catch (error) {
      console.error("Error creating burner:", error);
    }
  };

  const handleToggleDropdown = () => {
    setIsDropdownOpen(!isDropdownOpen);
  };

  const handleSelectAccount = (address: string) => {
    if (account?.select) {
      account.select(address);
      updateBurnerList();
      setIsDropdownOpen(false);
    }
  };

  const handleClearBurners = async () => {
    try {
      if (account?.clear) {
        await account.clear();
        account.select("");
        updateBurnerList();
        setIsDropdownOpen(false);
      }
    } catch (error) {
      console.error("Error clearing burners:", error);
    }
  };

  const slicedAddress = account?.account?.address
    ? `${account.account.address.slice(0, 5)}...${account.account.address.slice(-4)}`
    : "Connect Wallet";

  return (
    <div>
      <button
        onClick={handleToggleDropdown}
        className="flex items-center rounded-md overflow-hidden font-bold cursor-pointer pl-2"
        style={{
          background: "linear-gradient(to right, #EE7921 40%, #520066 40%)", // Gradient with orange and purple
          color: "white",
          width: "240px",
          height: "40px",
        }}
      >
        <img
          src={ConnectWallet}
          alt="Wallet Icon"
          className="h-6 w-6"
          style={{
            marginLeft: "30px",
          }}
        />
        <span
          className="flex-grow text-right" // Text aligned to the right
          style={{
            lineHeight: "40px",
            marginRight: "5px",
          }}
        >
          {slicedAddress}
        </span>
        <span
          className={`ml-2 transform transition-transform duration-300 ${
            isDropdownOpen ? "rotate-180" : ""
          }`}
          style={{
            color: "white",
            marginRight: "10px"
          }}
        >
          ▼
        </span>
      </button>

      {isDropdownOpen && (
        <div
          className="absolute mt-2 w-64 z-10 rounded-md shadow-lg"
          style={{
            backgroundColor: "#2C2F33", 
            border: "1px solid #520066", 
            color: "white",
          }}
        >
          <div className="p-4">
            <label
              htmlFor="signer-select"
              className="block text-sm font-medium mb-2"
              style={{ color: "#ffffff99" }}
            >
              Select Burner:
            </label>
            <select
              id="signer-select"
              className="w-full px-3 py-2 text-sm bg-white text-gray-800 rounded-md focus:outline-none"
              value={account?.account?.address || ""}
              onChange={(e) => handleSelectAccount(e.target.value)}
            >
              {burnerList.map((address, index) => (
                <option value={address} key={index} className="text-gray-800">
                  {address}
                </option>
              ))}
            </select>
          </div>
          <div className="p-2 space-y-2">
            <button
              className="w-full px-4 py-2 bg-[#520066] hover:bg-[#6A0080] text-white font-semibold text-sm rounded-md transition duration-300 ease-in-out flex items-center justify-center space-x-2"
              onClick={handleCreateBurner}
            >
              <span>Create New Burner</span>
            </button>
            <button
              className="w-full px-4 py-2 bg-[#520066] hover:bg-[#6A0080] text-white font-semibold text-sm rounded-md transition duration-300 ease-in-out flex items-center justify-center space-x-2"
              onClick={handleClearBurners}
            >
              <span>Clear Burners</span>
            </button>
          </div>
        </div>
      )}
    </div>
  );
};

export default CreateBurner;