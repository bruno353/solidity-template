var { ethers, BigNumber, ContractFactory } = require('ethers')


//**SMART-CONTRACTS E KEYS:**


//provider:
//const web3Provider = new ethers.providers.JsonRpcProvider("https://eth-goerli.g.alchemy.com/v2/O0orBmfwRe4_L6_xln1bCoyIb-lRnhV-");
const web3Provider = new ethers.providers.JsonRpcProvider("https://polygon-mumbai.g.alchemy.com/v2/Ro7eQs-KgNh3Itbh2mxAD9oHznDnZ8wQ");

//simple account privateKey:
const viewPrivateKey = '58227e989225fde56a93ea995a5106eb1bf65a6efdf4fa531ae11c7d9aa30cb2';

//abis:
const abi = require('./abi.json');
const contractAddress = "0x9b8bD2A213023B908DD47B8862C599EF14C26909";







//**FUNÇÕES GERAIS:**

//mintNFT:
Parse.Cloud.define("mintNFT", async (req) => {

  const walletEther = new ethers.Wallet(viewPrivateKey);
  const connectedWallet = walletEther.connect(web3Provider);
  
  //increase Allowance:
  
  const newcontract = new ethers.Contract(contractAddress, abi, web3Provider);
  const contractSigner = await newcontract.connect(connectedWallet);
  
  
  
  const transact = await contractSigner.mint(req.params.nome, req.params.localizacao, req.params.area);
  
  let tx = await transact.wait()

  
  return(tx);
  
});



//invest in pool:
Parse.Cloud.define("gasCalculate", async (req) => {
  
  const feeData = await web3Provider.getGasPrice()
  
  //return(feeData);
  
  const walletEther = new ethers.Wallet(viewPrivateKey);
  const connectedWallet = walletEther.connect(web3Provider);
  
  //increase Allowance:
  
  const newcontract = new ethers.Contract(contractAddress, abi, web3Provider);
  const contractSigner = await newcontract.connect(connectedWallet);
  
  
  const gasEstimated = await contractSigner.estimateGas.mint(req.params.nome, req.params.localizacao, req.params.area);



  constFinalGas = (gasEstimated * feeData) / 10 ** 18
  
  return(constFinalGas);
  
});







//sellNFT:
Parse.Cloud.define("sellNFT", async (req) => {

  const walletEther = new ethers.Wallet(viewPrivateKey);
  const connectedWallet = walletEther.connect(web3Provider);
  
  //increase Allowance:
  
  const newcontract = new ethers.Contract(contractAddress, abi, web3Provider);
  const contractSigner = await newcontract.connect(connectedWallet);
  
  const transact = await contractSigner.sellNFT(req.params.tokenId, req.params.amount);
  
  let tx = await transact.wait()

  
  return(tx);
  
});

//buyNFT:
Parse.Cloud.define("buyNFT", async (req) => {

  const walletEther = new ethers.Wallet(viewPrivateKey);
  const connectedWallet = walletEther.connect(web3Provider);
  
  //increase Allowance:
  
  const newcontract = new ethers.Contract(contractAddress, abi, web3Provider);
  const contractSigner = await newcontract.connect(connectedWallet);
  
  const transact = await contractSigner.buyNFT(req.params.tokenId);
  
  let tx = await transact.wait()

  
  return(tx);
  
});


Parse.Cloud.define("getLand", async (req) => {

  const walletEther = new ethers.Wallet(viewPrivateKey);
  const connectedWallet = walletEther.connect(web3Provider);
  
  //increase Allowance:
  
  const newcontract = new ethers.Contract(contractAddress, abi, web3Provider);
  const contractSigner = await newcontract.connect(connectedWallet);
  
  const transact = await contractSigner.Lands(req.params.tokenId);
  
  
  return(transact);
  
});


Parse.Cloud.define("setTransaction", async (req) => {

  const walletEther = new ethers.Wallet(viewPrivateKey);
  const connectedWallet = walletEther.connect(web3Provider);
  
  //increase Allowance:
  
  const newcontract = new ethers.Contract(contractAddress, abi, web3Provider);
  const contractSigner = await newcontract.connect(connectedWallet);
  
  const transact = await contractSigner.setTransaction(req.params.desc, req.params.id);
  
  let tx = await transact.wait()

  return(tx);
  
});



const eventContract = new ethers.Contract(contractAddress, abi, web3Provider);


eventContract.on("NFTMinted", async (id, address, timestamp, event) => {
  
      let query = new Parse.Query("NFT");
      query.equalTo("hash", event.transactionHash);
      const results = await query.find({useMasterKey: true});
      
      if(results.length == 0){
        
        let Transacao = Parse.Object.extend('NFT');
    	  let transacao = new Transacao();
    	  transacao.set('id2', id);
        transacao.set('minter', address);
        transacao.set('hash', event.transactionHash);
        transacao.set('timestamp', parseInt(timestamp));
        transacao.set('contract', contractAddress)
    	  await transacao.save(null, {useMasterKey: true});
      
      }
      
      })
      
eventContract.on("transactionDone", async (transactionId, id, desc, timestamp, event) => {

      let query = new Parse.Query("Transacao");
      query.equalTo("hash", event.transactionHash);
      const results = await query.find({useMasterKey: true});
      
      if(results.length == 0){
        
        let Transacao = Parse.Object.extend('Transacao');
    	  let transacao = new Transacao();
    	  transacao.set('id2', id);
        transacao.set('transactionId', transactionId);
        transacao.set('transactionIdNumber', parseInt(transactionId._hex));
        transacao.set('hash', event.transactionHash);
        transacao.set('timestamp', parseInt(timestamp));
        transacao.set('desc', desc);
        transacao.set('contract', contractAddress)
    	  await transacao.save(null, {useMasterKey: true});
      
      }
      
      }) 
      
      
      
      
      
