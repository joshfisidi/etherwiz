const { ethers } = require("hardhat");

async function main() {
    // Deployer's address
    const [deployer] = await ethers.getSigners();

    // Replace this with your deployed contract address
    const contractAddress = "0xYourDeployedContractAddress";

    // Get the deployed contract instance
    const FlashloanArbitrageV3 = await ethers.getContractFactory("FlashloanArbitrageV3");
    const arbitrageContract = FlashloanArbitrageV3.attach(contractAddress);

    console.log(`Interacting with contract at address: ${contractAddress}`);

    // Example of calling the arbitrage function from your deployed contract
    // Add any parameters if required by your function
    const tx = await arbitrageContract.executeArbitrage({
        gasLimit: 500000, // Set appropriate gas limit for the transaction
    });

    console.log("Transaction sent:", tx.hash);

    // Wait for the transaction to be mined
    const receipt = await tx.wait();
    console.log("Transaction mined in block:", receipt.blockNumber);
}

main().catch((error) => {
    console.error(error);
    process.exit(1);
});
