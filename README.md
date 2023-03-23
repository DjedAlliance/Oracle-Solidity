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

* Milkomeda-C1 Testnet:
    * Oracle Address: 0x47a7d67e89E5714456b9af39703C1dc62203002A

* Milkomeda-C1:
    * Oracle Address: 0xc531410f61FA22e19048D406EDE3361b3de5c386

### How to read data from this Oracle from a Smart Contract

The following sample contract shows how to read data from the oracle.
Note that it is necessary to accept the terms of service first.

```
pragma solidity ^0.8.0;

import "./IOracle.sol";

contract SampleContract {
    IOracle public oracle;

    event DataRead(string message, uint256 data);
 
    constructor(address oracleAddress) {
        oracle = IOracle(oracleAddress);
        oracle.acceptTermsOfService();
    }

    function doSomething() {
        uint256 data = oracle.readData();
        emit DataRead("The value read from the oracle was:", data);
    }
}
```

### How to read data from this Oracle from a Web App

To read data from the the oracle using web3.js, the following can de done:

```
import oracleArtifact from "../artifacts/Oracle.json";

const oracle = new web3.eth.Contract(oracleArtifact.abi, oracleAddress, {
    from: authorizedAddress
});
```

The address `authorizedAddress` can be any address that has already called the oracle's `acceptTermsOfService` function. Because the oracle's `readData` function is a view function, this address does not need to belong to you. You do not need to possess the private key of this address.

Then the data can be read by calling:

```
const data = await web3Promise(oracle, "readData");
```