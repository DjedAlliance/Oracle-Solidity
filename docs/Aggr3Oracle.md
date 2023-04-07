# Aggregator 3 Oracle

## Introduction

The Aggregator 3 Oracle (A3O) is a smart contract that allows to have a more resilient price than SimpleOracle.

## How it works

- Similarly to SimpleOracle, the Aggregator 3 Oracle is a smart contract that allows to have multiple oracles reporting the price of an asset.
- A3O takes into consideration the latest 3 prices reported by any allowed oracles (need to be by different addresses / owners).
- Although A3O only takes into consideration the latest 3 prices, it is possible to have more than 3 oracles reporting the price and switching between them.
- The price is the median of the 3 latest prices.
- The price is updated depending on the configuration of the poster, so it can be updated every block or every 10 blocks, etc.

## What is the practical difference with SimpleOracle?

- Resilience against a single oracle being compromised or hacked.
- Resilience against a single oracle being down or not reporting the price.