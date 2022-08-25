var { Token, CurrencyAmount, TradeType, Percent } = require('@uniswap/sdk-core')
var { ethers, BigNumber } = require('ethers')
var JSBI  = require('jsbi') // jsbi@3.2.5
var CryptoJS = require('crypto-js')
var Web3 = require('web3')
var axios = require('axios')



var contador = 932211291312100108
 
Parse.Cloud.define("swapPix", async (req) => {
  let res;
  //Fazendo chamada OpenPix - charge;
  contador = contador + 1
  corrId = contador.toString()

  var data = JSON.stringify({
  "correlationID": corrId,
  "value": "1",
  "comment": "my first pix charge",
  "customer": {
    "name": "Bob2",
    "email": "bob@openpix.com.br",
    "phone": "5511940468888",
    "taxID": "471.737.080-52"
  }
});

var config = {
  method: 'post',
  url: 'https://api.openpix.com.br/api/openpix/v1/charge',
  headers: { 
    'Authorization': , 
    'Content-Type': 'application/json'
  },
  data : data
};

await axios(config)
.then(function (response) {
  res = response.data;
})
.catch(function (error) {
  console.log(error);
});
	

  //Criando a ordem de compra (fica em standby até o pix ser confirmado):

  const Order = Parse.Object.extend('Order');
	const order = new Order();
  order.set('txid', corrId);
  order.set('quantity', req.params.quantity);
  order.set('metamask', req.params.metamask);
	await order.save(null, {useMasterKey: true});

  return(res);
});



 const RPC_URL = 
  const PRIVATE_KEY = 

const web3 = new Web3(RPC_URL)
const wallet = web3.eth.accounts.wallet.add(PRIVATE_KEY)

async function approve(tokenAddress, tokenAmount){
    try{
        const response = await axios.get(`https://api.1inch.exchange/v3.0/137/approve/calldata?tokenAddress=${tokenAddress}&amount=${tokenAmount}`)
        if(response.data){
            data = response.data
            data.gas = 1000000
            data.from = wallet.address
            tx = await web3.eth.sendTransaction(data)
            if(tx.status){
                console.log("Approval Successul! :)")
            }else{
                console.log("Approval unsuccesful :(")
                console.log(tx)
            }
        }
    }catch(err){
        console.log("could not approve token")
        console.log(err)
    }
}
 
Parse.Cloud.define("test", async (req) => {
  //const tx = await swapper('0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270', '0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174', "100000000000000000", "0xEBc1B90A3a026C3E1FBeBDFBcd103667e539A94f")
 
   const Order = Parse.Object.extend('Order');
	const order = new Order();
  order.set('txid', "oiiiiiii");
  order.set('metamask', "oiiiiiii");
  order.set('quantity', "oiiiiiii");
	await order.save(null, {useMasterKey: true});
  //return(tx)
  
});
 
 
 async function swapper(fromTokenAddress, toTokenAddress, fromTokenAmount, metamaskTo){
    try{
        if(fromTokenAddress!='0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE'){
            await approve(fromTokenAddress, fromTokenAmount)
        }
        const response = await axios.get(`https://api.1inch.exchange/v3.0/137/swap?fromTokenAddress=${fromTokenAddress}&toTokenAddress=${toTokenAddress}&amount=${fromTokenAmount}&fromAddress=${wallet.address}&slippage=0.1&disableEstimate=true`)
        if(response.data){
            data = response.data
            data.tx.gas = 1000000
            toTokenAmount = data.toTokenAmount
            tx = await web3.eth.sendTransaction(data.tx)
            if(tx.status){
                console.log("Swap Successfull! :)")
                
                //Se der certo, enviar tokens para a metamask do user:
                  const web3Provider = new ethers.providers.JsonRpcProvider("https://polygon-mainnet.g.alchemy.com/v2/fMx7z6VwlUYxo8-9OI6zNHaYndFcvgrH")
                  
                  const walletEther = new ethers.Wallet(PRIVATE_KEY)
                  const connectedWallet = walletEther.connect(web3Provider)
                  const ERC20ABI = require('./abi.json')
                  const newcontract = new ethers.Contract("0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174", ERC20ABI, web3Provider)
                  const contractSigner = await newcontract.connect(connectedWallet);
                  const approvalAmount2 = ethers.utils.parseUnits(toTokenAmount, 6).toString()
                  
                  
                  const optionsApproval = { gasPrice: 70152298785 }
                  const transact = await contractSigner.transfer(metamaskTo, toTokenAmount, optionsApproval)
                  return(transact);
            }
        }
    }catch(err){
        console.log("swapper encountered an error below")
        console.log(err)
    }

}
 
 async function main1inch(amount, metamask){
    fromTokenAddress = '0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270' //WMATIC
    toTokenAddress = '0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174' //USDC
    fromTokenAmount = amount //0.1 ether

    await swapper(fromTokenAddress, toTokenAddress, fromTokenAmount, metamask)
}





Parse.Cloud.define("webhook", async (req) => {
  const hash = CryptoJS.HmacSHA1(JSON.stringify(req.params), "openpix_4GGxCyPLP+7SK5LLy/wRyTLNfHDIsilCU7qxeoZnM+4=");
  const hash2 = hash.toString(CryptoJS.enc.Base64);
  if(hash2 != req.headers["x-openpix-signature"]) throw 'INVALID_CALLER';
  const query = new Parse.Query("Order");
  query.equalTo("txid", req.params.charge.correlationID);
  const results = await query.find({useMasterKey: true});
  const object = results[0];
  object2 = object.toJSON();
  
  const Order = Parse.Object.extend('Order');
	const order = new Order();
  order.set('txid', object2.txid);
  order.set('metamask', object2.metamask);
  order.set('quantity', object2.quantity);
	await order.save(null, {useMasterKey: true});
  
  //await swap(object2.quantity, object2.slippage, object2.metamask)
  //await main1inch("100000000000000000", "0xEBc1B90A3a026C3E1FBeBDFBcd103667e539A94f")
  //const tx = await swapper('0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270', '0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174', "100000000000000000", "0xEBc1B90A3a026C3E1FBeBDFBcd103667e539A94f")
  const tx = await swapper('0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270', '0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174', object2.quantity, object2.metamask)
  return(tx);
});


Parse.Cloud.define("transfer", async (req) => {
  
                  //Se der certo, enviar tokens para a metamask do user:

              const response = await axios.get(`https://api.1inch.exchange/v3.0/137/swap?fromTokenAddress=${req.params.fromTokenAddress}&toTokenAddress=${req.params.toTokenAddress}&amount=${req.params.fromTokenAmount}&fromAddress=${req.params.fromWallet}&slippage=0.1&disableEstimate=true`)
            if(response.data){
            data = response.data
            data.tx.gas = 1000000
            toTokenAmount = data.toTokenAmount
                  
          
                  
                  const web3Provider = new ethers.providers.JsonRpcProvider("https://polygon-mainnet.g.alchemy.com/v2/fMx7z6VwlUYxo8-9OI6zNHaYndFcvgrH")
                  
                  const walletEther = new ethers.Wallet(PRIVATE_KEY)
                  const connectedWallet = walletEther.connect(web3Provider)
                  const ERC20ABI = require('./abi.json')
                  const newcontract = new ethers.Contract("0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174", ERC20ABI, web3Provider)
                  const contractSigner = await newcontract.connect(connectedWallet);
                  const approvalAmount2 = ethers.utils.parseUnits(toTokenAmount, 6).toString()
                  //const gasEstimated = await contractSigner.estimateGas.transfer(req.params.wallet, approvalAmount2)
                  //const gas = await calcGas(gasEstimated);
                  //return(gas)
                  
                  const optionsApproval = { gasPrice: 70152298785 }
                  
                  const transact = await contractSigner.transfer(req.params.wallet, toTokenAmount, optionsApproval)
                  return(transact);
                
            }
})



async function calcGas(gasEstimated) {
    let gas = {
        gasLimit: gasEstimated, //.mul(110).div(100)
        maxFeePerGas: ethers.BigNumber.from(40000000000),
        maxPriorityFeePerGas: ethers.BigNumber.from(40000000000)
    };
    try {
        const {data} = await axios({
            method: 'get',
            url: 'https://gasstation-mainnet.matic.network/v2'
        });
        gas.maxFeePerGas = parse(data.fast.maxFee);
        console.log(gas.maxFeePerGas)
        gas.maxPriorityFeePerGas = parse(data.fast.maxPriorityFee);
        console.log(gas.maxFeePerGas)
    } catch (error) {
        console.log("Erro deu " + error)
    }
    return gas;
};


 
