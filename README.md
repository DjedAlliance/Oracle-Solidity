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