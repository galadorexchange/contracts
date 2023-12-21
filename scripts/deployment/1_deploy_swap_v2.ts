import hre, { ethers } from "hardhat"
import { config as dotEnvConfig } from "dotenv"
import { bn, getChainId, ZERO_ADDRESS } from "../utils"
dotEnvConfig()

async function main() {
    // ==== Read Configuration ====
    const [deployer] = await hre.ethers.getSigners()
    const chainId = await getChainId(hre)
    const category = "swapV2"

    const OWNER = process.env.OWNER_ADDR // not the deployer

    let deployments = {} as any

    let galadorFactory: any
    let galadorRouter02: any

    const creationCode =
        require("../../../apps/web/src/artifacts/contracts/swapV2/GaladorPair.sol/GaladorPair.json").bytecode

    const GaladorFactory = await ethers.getContractFactory("GaladorFactory")
    galadorFactory = await GaladorFactory.deploy(OWNER)
    deployments["GaladorFactory"] = galadorFactory.address

    const GaladorRouter02 = await ethers.getContractFactory("GaladorRouter02")
    galadorRouter02 = await GaladorRouter02.deploy(
        deployments.GaladorFactory,
        deployments.tokens.wETH,
    )
    deployments["GaladorRouter02"] = galadorRouter02.address

    ///////

    galadorFactory = await ethers.getContractAt("GaladorFactory", deployments.GaladorFactory)

    const pairs = [
        ["wETH", "USDC", format(0.08 * 10000), format(1 * 10000)],
        ["wETH", "USDT", format(0.08 * 10000), format(1 * 10000)],
        ["wETH", "DAI", format(0.4 * 10000), format(1 * 10000)],
        ["wETH", "GLDR", format(0.4 * 10000), format(1 * 10000)],
        ["GLDR", "USDT", format(200000), format(200000)],
        ["GLDR", "USDC", format(200000), format(200000)],
    ]

    let i = 0
    for (const pair of pairs) {
        console.debug(">>>", pair[0], "/", pair[1])
        await galadorFactory.createPair(deployments.tokens[pair[0]], deployments.tokens[pair[1]])
        await wait()
    }
}

let count = 1
async function wait() {
    console.debug(`>>> [${count}] Waiting...`)
    count += 1
    return new Promise((resolve) => setTimeout(resolve, 2500))
}

function format(x: number, decimals: number = 18) {
    return bn(`${x}e${decimals}`).toString()
}

main()
    .then(() => {
        process.exit(0)
    })
    .catch((error) => {
        console.error(error)
        process.exitCode = 1
    })
