require('dotenv').config();
const hre = require("hardhat");

async function main() {
    const [deployer] = await hre.ethers.getSigners();
  
    console.log("Deploying contracts with the account:", deployer.address);
  
    // Aave V3 PoolAddressesProvider address for Sepolia from .env
    const addressProvider = process.env.AAVE_V3_POOL_ADDRESSES_PROVIDER_SEPOLIA;
    
    if (!addressProvider) {
        throw new Error("AAVE_V3_POOL_ADDRESSES_PROVIDER_SEPOLIA is not set in .env file");
    }

    console.log("Using AddressProvider:", addressProvider);

    // Deploy FlashloanArbitrageV3 contract
    const FlashloanArbitrageV3 = await hre.ethers.getContractFactory("FlashloanArbitrageV3");
    const flashloan = await FlashloanArbitrageV3.deploy(
        process.env.AAVE_V3_POOL_ADDRESSES_PROVIDER_SEPOLIA,
        process.env.MOCK_WETH_ADDRESS,
        process.env.MOCK_DAI_ADDRESS,
        process.env.UNISWAP_V3_ROUTER_ADDRESS,
        process.env.SUSHISWAP_ROUTER_ADDRESS,
        process.env.UNISWAP_V3_QUOTER_ADDRESS
    );

    await flashloan.deployed();
    console.log("FlashloanArbitrageV3 deployed to:", flashloan.address);

    // Verify the contract on Etherscan
    if (process.env.ETHERSCAN_API_KEY) {
        console.log("Waiting for block confirmations...");
        await flashloan.deployTransaction.wait(6); // Wait for 6 block confirmations
        await hre.run("verify:verify", {
            address: flashloan.address,
            constructorArguments: [addressProvider],
        });
        console.log("Contract verified on Etherscan");
    }
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
