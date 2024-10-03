async function main() {
    const [deployer] = await ethers.getSigners();
    const blockNumber = await ethers.provider.getBlockNumber();
    console.log("Current block number:", blockNumber);
  }
  
  main()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error);
      process.exit(1);
    });
  