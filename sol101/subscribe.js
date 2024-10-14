import { connection } from "./connection.js";
import solana from "@solana/web3.js";

async function subscribe() {
  const toPublicKey = new solana.PublicKey(process.env.PUBLIC_KEY_B);
  const subscriptionId = await connection.onAccountChange(
    toPublicKey,
    (accountInfo) => {
      console.log(
        "Account Balance: ",
        accountInfo.lamports / solana.LAMPORTS_PER_SOL
      );
    }
  );
  console.log("Subscription ID: ", subscriptionId);
}

subscribe();
