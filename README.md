# Ada code to verify the bitcoin blockchain

This repository contains some Ada data structures and code to explore and
check properties of the bitcoin blockchain. Only Merkle trees and block
hashing is currently implemented, no transactions yet.

## Requirements

* You need the GNAT compiler to build the code.
* Right now, you need a running bitcoin-core server on your machine, which has
  downloaded at least part of the blockchain, so that the program can retrieve
  the data using `bitcoin-cli`.

## How to build

Run `gprbuild -P bitcoin.gpr` to build the project.

## How to run the program

Run `./obj/main` on the command line. The program currently relies on
`bitcoin-cli` to retrieve the blockchain data.




