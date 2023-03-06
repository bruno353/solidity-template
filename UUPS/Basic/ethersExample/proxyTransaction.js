var { ethers } = require('ethers')
const implementationABI = require('./implementation.json');

//**UTILS:**


const web3Provider = new ethers.providers.JsonRpcProvider("https://opt-goerli.g.alchemy.com/v2/d5EutXN-ONUVG_KPQmhE-yPeTTvEi5jI");
const walletEther = new ethers.Wallet("a7ec59c41ec3608dece33851a7d805bf22cd33da3e22e438bfe033349eb04011");
const connectedWallet = walletEther.connect(web3Provider);
const newcontract = new ethers.Contract("0xEA888785aea5b4f37aFf1c2b7531C3EeD326e3e9", implementationABI, web3Provider);



//abis:


async function main () {

  const contractSigner = await newcontract.connect(connectedWallet);
  const transaction = await contractSigner.increment();

  console.log(transaction)

}

main()
