# Flashloan Arbitrage V3

This project is a flashloan arbitrage contract built on the Sepolia testnet. It uses the Aave V3 Pool Addresses Provider and the Uniswap V3 Quoter to find the best fee tier for a flashloan and then execute an arbitrage opportunity.

## Getting Started

### Prerequisites

- Node.js (v14 or later)
- npm
- Python 3
- MetaMask browser extension

## Installation

1. Clone the repository:
   ```
   git clone https://github.com/joshfisidi/etherwiz.git
   cd etherwiz
   ```

2. Install the required npm packages:
   ```
   npm install
   ```

3. Create a `.env` file in the root directory and add the following environment variables:
   ```
   SEPOLIA_RPC_URL=your_sepolia_rpc_url
   PRIVATE_KEY=your_private_key
   ETHERSCAN_API_KEY=your_etherscan_api_key
   AAVE_V3_POOL_ADDRESSES_PROVIDER_SEPOLIA=0x012bAC54348C0E635dCAc9D5FB99f06F24136C9A
   MOCK_WETH_ADDRESS=your_mock_weth_address
   MOCK_DAI_ADDRESS=your_mock_dai_address
   UNISWAP_V3_ROUTER_ADDRESS=your_uniswap_v3_router_address
   SUSHISWAP_ROUTER_ADDRESS=your_sushiswap_router_address
   UNISWAP_V3_QUOTER_ADDRESS=your_uniswap_v3_quoter_address
   ```

   Replace the placeholder values with your actual credentials and contract addresses.

## Compilation and Deployment

1. Compile the smart contracts:
   ```
   npx hardhat compile
   ```

2. Deploy the FlashloanArbitrageV3 contract to Sepolia testnet:
   ```
   npx hardhat run scripts/deploy.js --network sepolia
   ```

3. After deployment, update the `contractAddress` in `scripts/interact.js` with the deployed contract address.

## Interacting with the Contract

To interact with the deployed contract:


## Running the UI Locally

1. Make sure you have Python 3 installed on your system.

2. Navigate to the project directory in your terminal.

3. Start a Python HTTP server:
   ```
   python -m http.server 8000
   ```

4. Open your web browser and go to `http://localhost:8000`

5. You should now see the ETHERWIZ interface. Use the "Connect Wallet" button to connect your MetaMask wallet, and then you can deploy the Flashloan contract using the UI.

## Project Structure

- `contracts/`: Contains the Solidity smart contracts
- `scripts/`: Contains deployment and interaction scripts
- `index.html`: The main HTML file for the UI
- `app.js`: Contains the frontend JavaScript code
- `hardhat.config.js`: Hardhat configuration file

## Important Notes

- This project is designed to work on the Sepolia testnet. Make sure your MetaMask is connected to Sepolia.
- Ensure you have sufficient Sepolia ETH in your wallet for gas fees.
- The contract interactions are for educational purposes. Always exercise caution when working with real assets.

## License

This project is licensed under the ISC License.
