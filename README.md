## Instructions

Install dependencies

```
git clone easyAuction
cd easyAuction
yarn
yarn build
```

Running tests:

```
yarn test
```

Run migration:

```
yarn deploy --network $NETWORK
```

Verify on etherscan:

```
npx hardhat verify --network $NETWORK DEPLOYED_CONTRACT_ADDRESS
```

Deployed contract on Rinkeby:
https://rinkeby.etherscan.io/address/0xEb3Caa20ac5540834DDF2D32B8D741c3B32630a4