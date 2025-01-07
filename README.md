## Foundry

**Foundry is a blazing fast, portable and modular toolkit for Ethereum application development written in Rust.**

Foundry consists of:

-   **Forge**: Ethereum testing framework (like Truffle, Hardhat and DappTools).
-   **Cast**: Swiss army knife for interacting with EVM smart contracts, sending transactions and getting chain data.
-   **Anvil**: Local Ethereum node, akin to Ganache, Hardhat Network.
-   **Chisel**: Fast, utilitarian, and verbose solidity REPL.

## Documentation

https://book.getfoundry.sh/

## Usage

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```

### Format

```shell
$ forge fmt
```

### Gas Snapshots

```shell
$ forge snapshot
```

### Anvil

```shell
$ anvil
```

### Deploy

```shell
$ forge script script/Counter.s.sol:CounterScript --rpc-url <your_rpc_url> --private-key <your_private_key>
```

### Cast

```shell
$ cast <subcommand>
```

### Help

```shell
$ forge --help
$ anvil --help
$ cast --help
```

## Quickstart

Install Foundry

```shell
$ curl -L https://foundry.paradigm.xyz | bash
```

Build project

```shell
$ forge build
```

Test project

```shell
$ forge test
```

### Tools Used
- Cursor IDE w/ Chat LLM
    - Prompts used, with codebase context
        -  Based on the escrow.sol contract, write a basic test. Use the OpenZeppelin ERC20 contract. 
    - Revisions 
        - LLM generated a good starting point and basic tests such as testing ETH escrow, settlement, and cancellation. A couple 'revert' tests were created as well
        - I added tests for ERC 20 escrow, fuzz tests, and setting up a proper setup function to limit any tests passing due to default values.
            - ex. sender starts with higher balance than recipient, escrow amounts are higher than recipient's balance, etc.
- OpenZeppelin ERC20
    - Leveraged OpenZepplin ERC20 contract for safe ERC20 escrow
- Foundry
    - Incorporated fuzz features in Foundry to test the contract with random values
    - Utilized Foundry's debugging tools to step through code, when running into test failures
    

## Notes

Some notes taken during development, which shaped design decisions.

- allowing contract to support several escrow accounts
- using escrow account map instead of array, to save gas cost/optimize for efficiency
    - also allows to fetch accounts by a key, and can use a semantically meaningful key
    - dynamically sized array is less gas efficient 
        - Source: https://www.alchemy.com/overviews/solidity-mapping#what-is-the-difference-between-solidity-arrays-and-mappings
            - Iterating through escrow accounts is likely an uncommon operation, as senders/receipients are managing their own escrow accounts. 
            - Off-chain DB can be used to power a frontend, which can be used to fetch escrow accounts by a key.
            - Using a mapping over a dynamically sized array is preferred here for gas optimization.
- using uni v2 as a reference for 'best practices'
    - using a factory pattern to create pairs
        - likely unnecessary for escrow, as they are short lived contracts, and increase cost of creating escrow accounts
