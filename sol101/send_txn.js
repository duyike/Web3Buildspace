import solana from "@solana/web3.js";
import { connection } from "./connection.js";
async function sendTxn() {
  const fromPrivateKey = process.env.PRIVATE_KEY_A;
  const fromKeypair = solana.Keypair.fromSecretKey(
    Uint8Array.from(Buffer.from(fromPrivateKey, "hex"))
  );
  const toPublicKey = new solana.PublicKey(process.env.PUBLIC_KEY_B);

  let transaction = new solana.Transaction().add(
    solana.SystemProgram.transfer({
      fromPubkey: fromKeypair.publicKey,
      toPubkey: toPublicKey,
      lamports: 0.1 * solana.LAMPORTS_PER_SOL,
    })
  );

  try {
    const txnSignature = await solana.sendAndConfirmTransaction(
      connection,
      transaction,
      [fromKeypair]
    );
    console.log(txnSignature);
  } catch (error) {
    console.error(error);
  }
}

sendTxn();
