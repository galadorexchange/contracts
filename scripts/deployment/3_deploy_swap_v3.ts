import hre, { artifacts, ethers, upgrades } from "hardhat"
import {
    ZERO_ADDRESS,
    deploy,
    getChainId,
    encodePriceSqrt,
    wait,
    format,
} from "../utils"

async function main() {
    // ==== Read Configuration ====
    const [deployer] = await hre.ethers.getSigners()
    const chainId = await getChainId(hre)
    const category = "swapV3"

    const DEPLOY = true

    let deployments = {} as any

    const creationCode =
        require("../../../apps/web/src/artifacts/contracts/swapV3/core/GaladorV3Pool.sol/GaladorV3Pool.json").bytecode
    const CODE_HASH = ethers.utils.keccak256(creationCode)


    if (DEPLOY) {
        /*
              ____   ____
             / / /  / ___|___  _ __ ___
            / / /  | |   / _ \| '__/ _ \
           / / /   | |__| (_) | | |  __/
          /_/_/     \____\___/|_|  \___|
        */
        deployments["GaladorV3PoolDeployer"] = await deploy("GaladorV3PoolDeployer")

        deployments["GaladorV3Factory"] = await deploy("GaladorV3Factory", [
            deployments.GaladorV3PoolDeployer,
        ])

        // Set Factory address
        const poolDeployer = await ethers.getContractAt(
            "GaladorV3PoolDeployer",
            deployments.GaladorV3PoolDeployer,
        )
        await poolDeployer.setFactoryAddress(deployments.GaladorV3Factory)

        /*
              ____  ____           _       _                     
             / / / |  _ \ ___ _ __(_)_ __ | |__   ___ _ __ _   _ 
            / / /  | |_) / _ \ '__| | '_ \| '_ \ / _ \ '__| | | |
           / / /   |  __/  __/ |  | | |_) | | | |  __/ |  | |_| |
          /_/_/    |_|   \___|_|  |_| .__/|_| |_|\___|_|   \__, |
                                    |_|                    |___/ 
        */
        deployments["SwapRouter"] = await deploy("SwapRouter", [
            deployments.GaladorV3PoolDeployer,
            deployments.GaladorV3Factory,
            deployments.tokens.wETH,
            CODE_HASH,
        ])
        
        deployments["NonfungibleTokenPositionDescriptorOffChain"] = await deploy("NonfungibleTokenPositionDescriptorOffChain")

        const nonfungibleTokenPositionDescriptorOffChain = await ethers.getContractAt(
            "NonfungibleTokenPositionDescriptorOffChain",
            deployments.NonfungibleTokenPositionDescriptorOffChain,
        )
        await nonfungibleTokenPositionDescriptorOffChain.initialize("")

        deployments["NonfungiblePositionManager"] = await deploy("NonfungiblePositionManager", [
            deployments.GaladorV3PoolDeployer,
            deployments.GaladorV3Factory,
            deployments.tokens.wETH,
            deployments.NonfungibleTokenPositionDescriptorOffChain,
            CODE_HASH,
        ])

        deployments["GaladorInterfaceMulticall"] = await deploy("GaladorInterfaceMulticall")

        deployments["V3Migrator"] = await deploy("V3Migrator", [
            deployments.GaladorV3PoolDeployer,
            deployments.GaladorV3Factory,
            deployments.tokens.wETH,
            deployments.NonfungiblePositionManager,
            CODE_HASH,
        ])

        deployments["TickLens"] = await deploy("TickLens")

        deployments["QuoterV2Periphery"] = await deploy(
            "contracts/swapV3/periphery/lens/QuoterV2.sol:QuoterV2",
            [
                deployments.GaladorV3PoolDeployer,
                deployments.GaladorV3Factory,
                deployments.tokens.wETH,
                CODE_HASH,
            ],
        )

        /*
              ____  ____             _            
             / / / |  _ \ ___  _   _| |_ ___ _ __ 
            / / /  | |_) / _ \| | | | __/ _ \ '__|
           / / /   |  _ < (_) | |_| | ||  __/ |   
          /_/_/    |_| \_\___/ \__,_|\__\___|_|   
        */
        deployments["SmartRouterHelper"] = await deploy("SmartRouterHelper")

        deployments["SmartRouter"] = await deploy(
            "SmartRouter",
            [
                deployments.swapV2.GaladorFactory,
                deployments.swapV3.GaladorV3PoolDeployer,
                deployments.swapV3.GaladorV3Factory,
                deployments.NonfungiblePositionManager,
                ZERO_ADDRESS,
                ZERO_ADDRESS,
                deployments.tokens.wETH,
                CODE_HASH,
            ],
            {
                SmartRouterHelper: deployments["SmartRouterHelper"],
            },
        )

        deployments["MixedRouteQuoterV1"] = await deploy(
            "MixedRouteQuoterV1",
            [
                deployments.GaladorV3PoolDeployer,
                deployments.GaladorV3Factory,
                deployments.swapV2.GaladorFactory,
                ZERO_ADDRESS,
                deployments.tokens.wETH,
                CODE_HASH,
            ],
            {
                SmartRouterHelper: deployments["SmartRouterHelper"],
            },
        )

        deployments["QuoterV2"] = await deploy(
            "contracts/swapV3/router/lens/QuoterV2.sol:QuoterV2",
            [
                deployments.GaladorV3PoolDeployer,
                deployments.GaladorV3Factory,
                deployments.tokens.wETH,
                CODE_HASH,
            ],
            {
                SmartRouterHelper: deployments["SmartRouterHelper"],
            },
        )

        deployments["TokenValidator"] = await deploy(
            "TokenValidator",
            [deployments.swapV2.GaladorFactory, deployments.NonfungiblePositionManager],
            {
                SmartRouterHelper: deployments["SmartRouterHelper"],
            },
        )
    }
}

main()
    .then(() => {
        process.exit(0)
    })
    .catch((error) => {
        console.error(error)
        process.exitCode = 1
    })
