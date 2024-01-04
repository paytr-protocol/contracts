# Paytr protocol smart contracts

You can find all our smart contracts in this repository.
At the moment there's one main contact, `Paytr.sol`.

Looking to use the Paytr protocol for your project? Check out our documentation [here](https://paytr.gitbook.io/product-docs/).

## Forge test

All the tests are located in the test folder.
Install the necessary dependencies with `forge install`.

We recommend to fork Polygon Mumbai and unlock an account which holds a lot of USDC, by using this command:
`ganache --fork https://polygon-mumbai.infura.io/v3/YOURKEY --wallet.unlockedAccounts="0x9a06153141114AAd45bf28F35521a40c4952C6FF"`

Open a new terminal window and run `forge test`.