// scripts/check-balance.js

async function main() {
    // Retrieve the deployer's account
    const [deployer] = await ethers.getSigners();
  
    // Fetch the balance
    const balance = await ethers.provider.getBalance(deployer.address);
  
    // Log the balance in ether
    console.log(`Account: ${deployer.address}`);
    console.log(`Balance: ${ethers.utils.formatEther(balance)} ETH`);
  }
  
  // Run the script and handle errors
  main()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error);
      process.exit(1);
    });
  