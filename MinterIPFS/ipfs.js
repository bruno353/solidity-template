/**
 * @fileoverview IPFS integration module for NFT minting
 * @description Handles file uploads to IPFS and metadata creation for NFTs
 */
const axios = require('axios');
const FormData = require('form-data');
const fs = require('fs');
const path = require('path');
const logger = require('./utils/logger');

// Constants
const PINATA_API_URL = 'https://api.pinata.cloud/pinning/pinFileToIPFS';
const PINATA_METADATA_URL = 'https://api.pinata.cloud/pinning/pinJSONToIPFS';
const MAX_RETRY_ATTEMPTS = 3;
const RETRY_DELAY_MS = 2000;

/**
 * Uploads a file to IPFS using Pinata service
 * @param {string} filePath - Path to the file to upload
 * @param {Object} options - Upload options
 * @param {string} options.pinataApiKey - Pinata API key
 * @param {string} options.pinataSecretApiKey - Pinata secret API key
 * @returns {Promise<string>} - CID of the uploaded file
 */
async function uploadFileToIPFS(filePath, options) {
  logger.debug("[uploadFileToIPFS] Starting file upload to IPFS");
  
  try {
    const { pinataApiKey, pinataSecretApiKey } = options;
    
    if (!pinataApiKey || !pinataSecretApiKey) {
      throw new Error('Missing Pinata API credentials');
    }
    
    const formData = new FormData();
    const fileStream = fs.createReadStream(filePath);
    const fileName = path.basename(filePath);
    
    formData.append('file', fileStream, { filename: fileName });
    
    const response = await axios.post(PINATA_API_URL, formData, {
      maxBodyLength: Infinity,
      headers: {
        'Content-Type': `multipart/form-data; boundary=${formData._boundary}`,
        pinata_api_key: pinataApiKey,
        pinata_secret_api_key: pinataSecretApiKey
      }
    });
    
    if (response.status !== 200) {
      throw new Error(`Upload failed with status: ${response.status}`);
    }
    
    logger.debug(`[uploadFileToIPFS] File uploaded successfully with CID: ${response.data.IpfsHash}`);
    return response.data.IpfsHash;
  } catch (error) {
    logger.error(`[uploadFileToIPFS] Error uploading file: ${error.message}`);
    throw error;
  }
}

/**
 * Creates and uploads NFT metadata to IPFS
 * @param {Object} metadata - NFT metadata
 * @param {string} metadata.name - Name of the NFT
 * @param {string} metadata.description - Description of the NFT
 * @param {string} metadata.imageCid - CID of the NFT image on IPFS
 * @param {Object} options - Upload options
 * @param {string} options.pinataApiKey - Pinata API key
 * @param {string} options.pinataSecretApiKey - Pinata secret API key
 * @returns {Promise<string>} - CID of the uploaded metadata
 */
async function uploadMetadataToIPFS(metadata, options) {
  logger.debug("[uploadMetadataToIPFS] Creating and uploading NFT metadata");
  
  try {
    const { pinataApiKey, pinataSecretApiKey } = options;
    
    if (!pinataApiKey || !pinataSecretApiKey) {
      throw new Error('Missing Pinata API credentials');
    }
    
    const { name, description, imageCid, attributes = [] } = metadata;
    
    const metadataObject = {
      name,
      description,
      image: `ipfs://${imageCid}`,
      attributes
    };
    
    const response = await axios.post(PINATA_METADATA_URL, metadataObject, {
      headers: {
        pinata_api_key: pinataApiKey,
        pinata_secret_api_key: pinataSecretApiKey
      }
    });
    
    if (response.status !== 200) {
      throw new Error(`Metadata upload failed with status: ${response.status}`);
    }
    
    logger.debug(`[uploadMetadataToIPFS] Metadata uploaded successfully with CID: ${response.data.IpfsHash}`);
    return response.data.IpfsHash;
  } catch (error) {
    logger.error(`[uploadMetadataToIPFS] Error uploading metadata: ${error.message}`);
    throw error;
  }
}

/**
 * Uploads an asset with retry mechanism
 * @param {Function} uploadFunction - The upload function to retry
 * @param {Array} args - Arguments for the upload function
 * @returns {Promise<string>} - CID of the uploaded asset
 */
async function uploadWithRetry(uploadFunction, ...args) {
  logger.debug("[uploadWithRetry] Attempting upload with retry mechanism");
  
  let lastError;
  
  for (let attempt = 1; attempt <= MAX_RETRY_ATTEMPTS; attempt++) {
    try {
      return await uploadFunction(...args);
    } catch (error) {
      lastError = error;
      logger.warning(`[uploadWithRetry] Attempt ${attempt} failed: ${error.message}`);
      
      if (attempt < MAX_RETRY_ATTEMPTS) {
        logger.debug(`[uploadWithRetry] Retrying in ${RETRY_DELAY_MS / 1000} seconds...`);
        await new Promise(resolve => setTimeout(resolve, RETRY_DELAY_MS));
      }
    }
  }
  
  logger.error(`[uploadWithRetry] All ${MAX_RETRY_ATTEMPTS} attempts failed`);
  throw lastError;
}

/**
 * Validates IPFS CID format
 * @param {string} cid - IPFS CID to validate
 * @returns {boolean} - Whether the CID is valid
 */
function isValidCid(cid) {
  if (!cid || typeof cid !== 'string') {
    return false;
  }
  
  // Basic CID v0 or v1 format check
  const cidPattern = /^(Qm[1-9A-Za-z]{44}|b[a-zA-Z0-9]{58})$/;
  return cidPattern.test(cid);
}

module.exports = {
  uploadFileToIPFS,
  uploadMetadataToIPFS,
  uploadWithRetry,
  isValidCid
};
