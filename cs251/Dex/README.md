Stanford University, CS251 Project 4: Building a DEX
Authors: Simon Tao (BS'22, MS'23), Mathew Hogan (BS'22), under the guidance of Professor Dan Boneh.

## Setup

1. Install and use LTS version Node.js (Recommend using nvm)
2. Install dependencies:

```shell
npm install --save-dev hardhat
npm install --save-dev @nomiclabs/hardhat-ethers ethers
npm install --save-dev @openzeppelin/contracts
```

## Development

1. Run local node: `npm run local-node`
2. Deploy all contracts on the local node: `npm run deploy-local`
   1. Deploy token contract on the local node: `npm run deploy-token-local`
   2. Deploy exchange contract on the local node: `npm run deploy-exchange-local`
3. Copy the address of the token contract and exchange contract to the `token_address` and `exchange_address` variables in `exchange.sol`.
