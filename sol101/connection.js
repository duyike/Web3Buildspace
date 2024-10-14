import { Connection } from "@solana/web3.js";
import { Helius } from "helius-sdk";

const connection = new Connection(
  "https://devnet.helius-rpc.com/?api-key=" + process.env.HELIUS_API_KEY,
  {
    wsEndpoint:
      "wss://devnet.helius-rpc.com/?api-key=" + process.env.HELIUS_API_KEY,
    commitment: "confirmed",
  }
);

const helius = new Helius(process.env.HELIUS_API_KEY);

export { connection, helius };
