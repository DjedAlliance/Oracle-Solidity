# Aggregator 3 Oracle

The Aggregator 3 Oracle (A3O) is an oracle that is more resilient than SimpleOracle in case an owner gets compromised.

## How does it work? How does it differ from SimpleOracle?

- As in SimpleOracle, A3O lets multiple _owners_ write data (e.g. the price of an asset).
- Whereas SimpleOracle simply reports the latest data written by any owner, A30 reports the median of the latest 3 data points written by distinct owners.
- Although A3O only takes into consideration the latest 3 data points submitted by distinct owners, it is possible to have more than 3 owners writing data.
- Each owner is free to write data at any frequency (e.g. every block, every 10 blocks, ...).

## What does this entail in practice?

- In SimpleOracle it suffices for an attacker to compromise (e.g. hack) a single owner in order to be able to force the oracle to occasionaly report wrong data. In A3O, on the other hand, the attacker must compromise at least two owners to be able to force the oracle to report wrong data that is too different from correct data.
- The drawback associated with this increased resilience is a slight oracle delay. Whereas SimpleOracle updates the data that can be read from it as soon as any owner writes new data, in A3 it may be necessary to wait for two owners to write new data for the median to change.