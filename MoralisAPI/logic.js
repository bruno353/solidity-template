/**
 * @fileoverview NFT Minting Application with Moralis Integration
 * This module handles Web3 authentication, file uploading to IPFS, and NFT minting
 * @author AITR Team
 * @version 1.0.0
 */

// Configuration constants
const CONFIG = {
  moralisAppId: "", // Application ID from moralis.io
  moralisServerUrl: "", // Server URL from moralis.io
  nftContractAddress: "", // NFT Minting Contract Address
};

/**
 * Available deployed contracts:
 * - Ethereum Rinkeby: 0x0Fb6EF3505b9c52Ed39595433a21aF9B5FCc4431
 * - Polygon Mumbai: 0x351bbee7C6E9268A1BF741B098448477E08A0a53
 * - BSC Testnet: 0x88624DD1c725C6A95E223170fa99ddB22E1C6DDD
 */

// Initialize Moralis
Moralis.initialize(CONFIG.moralisAppId);
Moralis.serverURL = CONFIG.moralisServerUrl;

// Initialize Web3 with MetaMask provider
const web3 = new Web3(window.ethereum);

// DOM element references
const DOM = {
  loginForm: {
    submitButton: document.getElementById('submit'),
    username: document.getElementById('username'),
    email: document.getElementById('useremail'),
  },
  nftForm: {
    uploadButton: document.getElementById('upload'),
    fileInput: document.getElementById('file'),
    name: document.getElementById('name'),
    description: document.getElementById('description'),
  },
  result: document.getElementById('resultSpace'),
};

/**
 * Logger utility for consistent logging
 */
const logger = {
  debug: (message) => console.debug(message),
  info: (message) => console.info(message),
  error: (message) => console.error(message),
};

/**
 * Authenticates user with Web3 and saves their profile information
 * @async
 * @returns {Promise<void>}
 */
async function login() {
  try {
    logger.debug("[LOGIN] Initiating Moralis authentication");
    
    // Disable form inputs during authentication
    setFormState(DOM.loginForm, true);
    
    const user = await Moralis.Web3.authenticate();
    
    // Save user information
    user.set("name", DOM.loginForm.username.value);
    user.set("email", DOM.loginForm.email.value);
    await user.save();
    
    logger.info("[LOGIN] User authenticated successfully");
    
    // Enable NFT form inputs after successful authentication
    setFormState(DOM.nftForm, false);
  } catch (error) {
    logger.error(`[LOGIN] Authentication failed: ${error.message}`);
    alert(`Authentication failed: ${error.message}`);
    setFormState(DOM.loginForm, false);
  }
}

/**
 * Uploads file to IPFS, creates metadata, and mints the NFT
 * @async
 * @returns {Promise<void>}
 */
async function upload() {
  try {
    logger.debug("[UPLOAD] Starting NFT upload and minting process");
    
    // Validate input fields
    if (!validateNftForm()) {
      return;
    }
    
    // Disable form during processing
    setFormState(DOM.nftForm, true);
    
    // Upload image to IPFS
    const data = DOM.nftForm.fileInput.files[0];
    const imageFile = new Moralis.File(data.name, data);
    await imageFile.saveIPFS();
    const imageURI = imageFile.ipfs();
    
    logger.debug(`[UPLOAD] Image uploaded to IPFS: ${imageURI}`);
    
    // Create and upload metadata
    const metadata = {
      name: DOM.nftForm.name.value,
      description: DOM.nftForm.description.value,
      image: imageURI
    };
    
    const metadataFile = new Moralis.File(
      "metadata.json", 
      { base64: btoa(JSON.stringify(metadata)) }
    );
    
    await metadataFile.saveIPFS();
    const metadataURI = metadataFile.ipfs();
    
    logger.debug(`[UPLOAD] Metadata uploaded to IPFS: ${metadataURI}`);
    
    // Mint the token with the metadata URI
    const transactionHash = await mintToken(metadataURI);
    
    // Display transaction result
    displayTransactionResult(transactionHash);
    
    logger.info(`[UPLOAD] NFT minted successfully with transaction: ${transactionHash}`);
  } catch (error) {
    logger.error(`[UPLOAD] Upload failed: ${error.message}`);
    alert(`Upload failed: ${error.message}`);
    setFormState(DOM.nftForm, false);
  }
}

/**
 * Mints the NFT token by calling the smart contract
 * @async
 * @param {string} tokenURI - IPFS URI pointing to the NFT metadata
 * @returns {Promise<string>} Transaction hash
 */
async function mintToken(tokenURI) {
  logger.debug(`[MINT_TOKEN] Minting token with URI: ${tokenURI}`);
  
  // Encode the function call
  const encodedFunction = web3.eth.abi.encodeFunctionCall({
    name: "mintToken",
    type: "function",
    inputs: [{
      type: 'string',
      name: 'tokenURI'
    }]
  }, [tokenURI]);

  // Prepare transaction parameters
  const transactionParameters = {
    to: CONFIG.nftContractAddress,
    from: ethereum.selectedAddress,
    data: encodedFunction
  };
  
  // Send transaction to MetaMask
  const transactionHash = await ethereum.request({
    method: 'eth_sendTransaction',
    params: [transactionParameters]
  });
  
  return transactionHash;
}

/**
 * Displays the transaction result to the user
 * @param {string} transactionHash - The hash of the minting transaction
 */
function displayTransactionResult(transactionHash) {
  DOM.result.innerHTML = `
    <div class="alert alert-success" role="alert">
      <h4 class="alert-heading">Success!</h4>
      <p>Your NFT was minted successfully.</p>
      <hr>
      <p class="mb-0">Transaction Hash: <a href="https://etherscan.io/tx/${transactionHash}" target="_blank">${transactionHash}</a></p>
    </div>
  `;
}

/**
 * Sets the enabled/disabled state for a form's elements
 * @param {Object} formElements - Object containing form elements
 * @param {boolean} disabled - Whether to disable the elements
 */
function setFormState(formElements, disabled) {
  Object.values(formElements).forEach(element => {
    if (element && element.setAttribute) {
      if (disabled) {
        element.setAttribute("disabled", "true");
      } else {
        element.removeAttribute("disabled");
      }
    }
  });
}

/**
 * Validates the NFT form fields
 * @returns {boolean} True if all fields are valid
 */
function validateNftForm() {
  if (!DOM.nftForm.name.value) {
    alert("Please enter a name for your NFT");
    return false;
  }
  
  if (!DOM.nftForm.description.value) {
    alert("Please enter a description for your NFT");
    return false;
  }
  
  if (!DOM.nftForm.fileInput.files || !DOM.nftForm.fileInput.files[0]) {
    alert("Please select a file for your NFT");
    return false;
  }
  
  return true;
}

// Export functions for use in HTML
window.login = login;
window.upload = upload; 