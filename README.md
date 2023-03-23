# Oracle

A simple oracle with a minimal governance system. It allows multiple owners to post data and allows a majority of the current owners to add more owners or to remove owners.

## Setting Up

Install [Foundry](https://github.com/foundry-rs/foundry/blob/master/README.md). Then:

```
npm install
```


## Building and Testing

```
forge build
forge test
forge coverage
```

## Linting

Pre-configured `solhint` and `prettier-plugin-solidity`. Can be run by

```
npm run solhint
npm run prettier
```

## Using this Oracle

### Known Deployments of this Oracle

This oracle has been deployed to the following blockchains:

* Milkomeda-C1 Testnet:
    * Oracle Address: 0x47a7d67e89E5714456b9af39703C1dc62203002A
    * Data provided: latest price of 1 USD in ADA multiplied by 10^18
        * For example: the result `2875000000000000000` means that 1 USD costs 2.875 ADA.

* Milkomeda-C1:
    * Oracle Address: 0xc531410f61FA22e19048D406EDE3361b3de5c386
    * Data provided: latest price of 1 USD in ADA multiplied by 10^18

### How to read data from this Oracle from a Smart Contract

The following sample contract shows how to read data from the oracle.
Note that it is necessary to accept the terms of service first.

```
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IOracle {
    function readData() external view returns (uint256);
    function acceptTermsOfService() external;
}

contract SampleOracleDataConsumer {
    IOracle public oracle = IOracle(0xc531410f61FA22e19048D406EDE3361b3de5c386);
    // using the address of the oracle in Milkomeda-C1 as an example.
 
    constructor() {
        oracle.acceptTermsOfService();
    }

    function sampleFunctionUsingTheOracle() {
        data = oracle.readData();
        // then do something with the data...
    }
}
```

### How to read data from this Oracle from a Web App

To read data from the oracle using web3.js, do the following:

```
import oracleArtifact from "../artifacts/SimpleOracle.json";

const oracleAddress = "0xc531410f61FA22e19048D406EDE3361b3de5c386"; 
// using the address of the oracle in Milkomeda-C1 as an example.

const oracle = new web3.eth.Contract(
    oracleArtifact.abi, 
    oracleAddress, 
    {from: authorizedAddress}
);

const data = await web3Promise(oracle, "readData");
```

Ensure that [SimpleOracle.json](./abi/SimpleOracle.json) is in your web app's `../artifacts/` folder.

The address `authorizedAddress` can be any address that has already called the oracle's `acceptTermsOfService` function. Because the oracle's `readData` function is a view function, this address does not need to belong to you. You do not need to possess the private key of this address.