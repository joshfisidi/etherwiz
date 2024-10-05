let web3;
let contract;
const addressProvider = "0x012bAC54348C0E635dCAc9D5FB99f06F24136C9A"; // Aave V3 PoolAddressesProvider for Sepolia

const connectWalletButton = document.getElementById('connectWallet');
const deployContractButton = document.getElementById('deployContract');
const statusText = document.getElementById('status');

connectWalletButton.addEventListener('click', connectWallet);
deployContractButton.addEventListener('click', deployContract);

async function connectWallet() {
    if (typeof window.ethereum !== 'undefined') {
        try {
            await window.ethereum.request({ method: 'eth_requestAccounts' });
            web3 = new Web3(window.ethereum);
            statusText.textContent = 'Wallet connected!';
            connectWalletButton.textContent = 'Wallet Connected';
            connectWalletButton.classList.remove('bg-blue-500', 'hover:bg-blue-600');
            connectWalletButton.classList.add('bg-gray-500', 'cursor-not-allowed');
            connectWalletButton.disabled = true;
            deployContractButton.disabled = false;
            deployContractButton.classList.remove('opacity-50', 'cursor-not-allowed');
        } catch (error) {
            console.error(error);
            statusText.textContent = 'Failed to connect wallet.';
        }
    } else {
        statusText.textContent = 'Please install MetaMask!';
    }
}

async function deployContract() {
    if (!web3) {
        statusText.textContent = 'Please connect your wallet first.';
        return;
    }

    deployContractButton.textContent = 'Deploying...';
    deployContractButton.disabled = true;
    deployContractButton.classList.add('opacity-50', 'cursor-not-allowed');

    const accounts = await web3.eth.getAccounts();
    const flashloanABI = []; // Add your Flashloan contract ABI here
    const flashloanBytecode = ''; // Add your Flashloan contract bytecode here

    statusText.textContent = 'Deploying contract...';

    try {
        const FlashloanContract = new web3.eth.Contract(flashloanABI);
        const deployTx = FlashloanContract.deploy({
            data: flashloanBytecode,
            arguments: [addressProvider]
        });

        const deployedContract = await deployTx.send({
            from: accounts[0],
            gas: await deployTx.estimateGas()
        });

        statusText.textContent = `Contract deployed at: ${deployedContract.options.address}`;
    } catch (error) {
        console.error(error);
        statusText.textContent = 'Failed to deploy contract.';
    }

    // After deployment (success or failure), reset the button
    deployContractButton.textContent = 'Deploy Flashloan Contract';
    deployContractButton.disabled = false;
    deployContractButton.classList.remove('opacity-50', 'cursor-not-allowed');
}