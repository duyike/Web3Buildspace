import React, { useEffect, useState } from "react";
import { ethers } from "ethers";
import "./App.css";
import abi from "./utils/WavePortal.json";

export default function App() {
  const [currentAccount, setCurrentAccount] = useState("");
  const [waves, setWaves] = useState([]);
  const contractAddress = "0x8Aaf10Ecad3d65a3D5535D70d7f4E9873319b1E1";
  const contractABI = abi.abi;

  const checkIfWalletConnnect = async () => {
    try {
      const { ethereum } = window;
      if (!ethereum) {
        console.log("Make sure you have metamask!");
      } else {
        console.log("We get ethereum", ethereum);
      }

      const accounts = await ethereum.request({ method: "eth_accounts" });
      if (accounts.length !== 0) {
        const account = accounts[0];
        console.log("Found an authorized account:", account);
        setCurrentAccount(account);
      } else {
        console.log("No authorized account found");
      }
    } catch (error) {
      console.log(error);
    }
  };

  const connectWallet = async () => {
    try {
      const { ethereum } = window;
      if (!ethereum) {
        console.log("Make sure you have metamask!");
        return;
      }

      const accounts = await ethereum.request({
        method: "eth_requestAccounts",
      });
      console.log("Connected", accounts[0]);
      setCurrentAccount(accounts[0]);
    } catch (error) {
      console.log(error);
    }
  };

  const wave = async () => {
    try {
      if (!currentAccount) {
        alert("Please connect your wallet at first!");
        return;
      }

      const wavePortalContract = getWaveContract();
      if (!wavePortalContract) {
        return;
      }

      let count = await wavePortalContract.getTotalWaves();
      console.log("Retrieved total wave count...", count.toNumber());

      const waveTxn = await wavePortalContract.wave("Hello👋", {
        gasLimit: 300000,
      });
      console.log("Mining...", waveTxn.hash);

      await waveTxn.wait();
      console.log("Mined: ", waveTxn.hash);

      count = await wavePortalContract.getTotalWaves();
      console.log("Retrieved total wave count...", count.toNumber());
    } catch (error) {
      console.log(error);
    }
  };

  const getAllWaves = async () => {
    try {
      const wavePortalContract = getWaveContract();
      if (!wavePortalContract) {
        return;
      }

      let allWaves = [];
      await wavePortalContract.getAllWaves().then((_waves) => {
        _waves.forEach((_wave) => {
          allWaves.push({
            address: _wave.waver,
            timestamp: new Date(_wave.timestamp * 1000),
            message: _wave.message,
          });
        });
      });
      setWaves(allWaves);
    } catch (error) {
      console.log(error);
    }
  };

  const getWaveContract = () => {
    const { ethereum } = window;
    if (!ethereum) {
      console.log("Make sure you have metamask!");
      return;
    }
    const provider = new ethers.providers.Web3Provider(ethereum);
    const signer = provider.getSigner();
    return new ethers.Contract(contractAddress, contractABI, signer);
  };

  const onNewWave = (from, timestamp, messgae) => {
    console.log("onNewWave", from, timestamp, messgae);
    setWaves((previousWave) => [
      ...previousWave,
      {
        address: from,
        timestamp: new Date(timestamp * 1000),
        message: messgae,
      },
    ]);
  };

  const listenNewWaveEvent = () => {
    let waveContract = getWaveContract();
    if (waveContract) {
      waveContract.on("NewWave", onNewWave);
    }
  };

  const cleanUp = () => {
    let waveContract = getWaveContract();
    if (waveContract) {
      waveContract.off("NewWave", onNewWave);
    }
  };

  useEffect(() => {
    checkIfWalletConnnect();
    getAllWaves();
    listenNewWaveEvent();
    return cleanUp;
  }, []);

  return (
    <div className="mainContainer">
      <div className="dataContainer">
        <div className="header">👋 Hey there!</div>

        <div className="bio">
          I am yike and I worked on web 3.0 so that's pretty cool right? Connect
          your Ethereum wallet (use Rinkeby Test Netork) and wave at me!
        </div>

        <button className="waveButton" onClick={wave}>
          Wave at Me
        </button>

        {!currentAccount && (
          <button className="waveButton" onClick={connectWallet}>
            Connect Wallet
          </button>
        )}

        {waves.map((_wave, index) => {
          return (
            <div
              key={index}
              style={{
                backgroundColor: "OldLace",
                marginTop: "16px",
                padding: "8px",
              }}
            >
              <div>Address: {_wave.address}</div>
              <div>Time: {_wave.timestamp.toString()}</div>
              <div>Message: {_wave.message}</div>
            </div>
          );
        })}
      </div>
    </div>
  );
}
