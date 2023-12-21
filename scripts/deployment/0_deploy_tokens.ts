import hre, { ethers } from "hardhat"
import { bn, getChainId } from "../utils"

async function main() {
    // ==== Read Configuration ====
    const [deployer] = await hre.ethers.getSigners()
    const chainId = await getChainId(hre)
    const category = "tokens"

    const initialSupply = format(420000000)

    const MockERC20 = await ethers.getContractFactory("MockERC20")
    const RestrictedERC20 = await ethers.getContractFactory("RestrictedERC20")
    const WETH9 = await ethers.getContractFactory("WETH9")

    const weth = await WETH9.deploy()

    // const usdc = await RestrictedERC20.deploy("USD Coin", "USDC", initialSupply)
    // const usdt = await RestrictedERC20.deploy("USD Tether", "USDT", initialSupply)
    // // const dai = await RestrictedERC20.deploy("DAI", "DAI", initialSupply)
    // const gldr = await RestrictedERC20.deploy("Galador Token", "GLDR", initialSupply)
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
