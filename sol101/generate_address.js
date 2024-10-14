import { Keypair } from "@solana/web3.js";

function generateAddress() {
    const keypair = Keypair.generate();
    console.log("Keypair:", keypair);
    console.log("Private Key:", Buffer.from(keypair.secretKey).toString("hex"));
    console.log("Public Key:", keypair.publicKey.toString());
}

generateAddress();

