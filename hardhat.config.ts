import { config as dotEnvConfig } from "dotenv"
dotEnvConfig()

import "@typechain/hardhat"
import "@openzeppelin/hardhat-upgrades"
import "@nomiclabs/hardhat-ethers"
import "@nomiclabs/hardhat-etherscan"
import "hardhat-deploy"

const DEPLOYER_PRIVATE_KEY = process.env.DEPLOYER_KEY

const settings = {
    optimizer: {
        enabled: true,
        runs: 999999,
    },
}

module.exports = {
    defaultNetwork: "hardhat",
    networks: {
        hardhat: {
            chainId: 31337,
            allowUnlimitedContractSize: true,
            timeout: 1800000,
        },
        telos_testnet: {
            chainId: 0x29,
            url: "https://testnet.telos.net/evm	",
            accounts: [DEPLOYER_PRIVATE_KEY],
        },
        telos: {
            chainId: 0x28,
            url: "https://mainnet.telos.net/evm",
            accounts: [DEPLOYER_PRIVATE_KEY],
        },
    },
    namedAccounts: {
        deployer: {
            default: 0,
        },
    },
    solidity: {
        settings: {
            evmVersion: "istanbul",
            outputSelection: {
                "*": {
                    "": ["ast"],
                    "*": [
                        "evm.bytecode.object",
                        "evm.deployedBytecode.object",
                        "abi",
                        "evm.bytecode.sourceMap",
                        "evm.deployedBytecode.sourceMap",
                        "metadata",
                    ],
                },
            },
        },
        compilers: [
            "0.6.12",
            "0.8.0",
            "0.8.2",
            "0.8.7",
            "0.8.9",
            "0.8.10",
            "0.8.12",
            "0.7.6",
            "0.6.6",
            "0.5.16",
            "0.4.18",
        ].map((v) => {
            return {
                version: v,
                settings:
                    v === "0.7.6"
                        ? {
                              optimizer: {
                                  enabled: true,
                                  runs: 10,
                              },
                              metadata: {
                                  bytecodeHash: "none",
                              },
                          }
                        : v === "0.8.10"
                          ? {
                                optimizer: {
                                    enabled: true,
                                    runs: 999,
                                },
                            }
                          : settings,
            }
        }),
    },
    typechain: {
        outDir: "./typechain",
    },
    mocha: {
        timeout: 50000,
    },
}