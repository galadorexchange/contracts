import hre, { ethers } from "hardhat"
import { getChainId } from "../utils"

async function main() {
    // ==== Read Configuration ====
    const [deployer] = await hre.ethers.getSigners()
    const chainId = await getChainId(hre)
    const category = "misc"

    let deployments = {} as any 

    const Multicall2 = await ethers.getContractFactory("Multicall2")
    const multicall2 = await Multicall2.deploy()
    deployments["Multicall2"] = multicall2.address

    const Multicall3 = await ethers.getContractFactory("Multicall3")
    const multicall3 = await Multicall3.deploy()
    deployments["Multicall3"] = multicall3.address

    const SwapV2Multicall = await ethers.getContractFactory("SwapV2Multicall")
    const swapV2Multicall = await SwapV2Multicall.deploy()
    deployments["SwapV2Multicall"] = swapV2Multicall.address

    console.log(deployments)
}

main()
    .then(() => {
        process.exit(0)
    })
    .catch((error) => {
        console.error(error)
        process.exitCode = 1
    })
