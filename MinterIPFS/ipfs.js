import { CreditCardOutlined } from "@ant-design/icons";
import { Button, Input } from "antd";
import { ethers } from "ethers";
import Text from "antd/lib/typography/Text";
import { useEffect, useState } from "react";
import { useMoralis } from "react-moralis";
import { useMoralisDapp } from "providers/MoralisDappProvider/MoralisDappProvider";
import { getExplorer } from "helpers/networks";
import { useWeb3ExecuteFunction } from "react-moralis";
import AddressInput from "../../AddressInput";
import AssetSelector from "./AssetSelector";
import { PolygonCurrency} from "../../Chains/Logos";
var bigInt = require("big-integer");

const pinataSDK = require('@pinata/sdk');
const pinata = pinataSDK(`32459721f4b813b4a6a7`, '344be49e109a8d33d12ebd8f7a1a487571dd2c706501c88e28044e69f9c44082');

const styles = {
  card: {
    alignItems: "center",
    width: "100%",
  },
  header: {
    textAlign: "center",
  },
  input: {
    width: "100%",
    outline: "none",
    fontSize: "16px",
    whiteSpace: "nowrap",
    overflow: "hidden",
    textverflow: "ellipsis",
    appearance: "textfield",
    color: "#041836",
    fontWeight: "700",
    border: "none",
    backgroundColor: "transparent",
  },
  select: {
    marginTop: "20px",
    display: "flex",
    alignItems: "center",
  },
  textWrapper: { maxWidth: "80px", width: "100%" },
  row: {
    display: "flex",
    alignItems: "center",
    gap: "10px",
    flexDirection: "row",
  },
};

function Transfer() {
  const { Moralis } = useMoralis();
  const [receiver, setReceiver] = useState();
  const [asset, setAsset] = useState();
  const [tx, setTx] = useState();
  const [amount, setAmount] = useState();
  const [premium, setPremium] = useState();
  const [isPending, setIsPending] = useState(false);
  const { chainId, marketAddress, contractABI } = useMoralisDapp();
  const contractProcessor = useWeb3ExecuteFunction(); 
  const contractABIJson = JSON.parse(contractABI);
  const buyInsuranceFunction = "buyInsurance";
  const payoutFunction = "fetchPayoutAmount";
  const uriParam = "putTextHere";
  const provider = new ethers.providers.JsonRpcProvider("");
  const signer = new ethers.Wallet("", provider);

  useEffect(() => {
    amount? setTx({ amount }) : setTx();
  }, [amount]);

  
  async function fetchPayout() {
    const returnContract = new ethers.Contract(marketAddress, contractABI, signer);
    const data = await returnContract.fetchPayoutAmount(amount)
    return data
  }

  async function transfer() {

  const body = {
      description: 'Bruno Santos; 27/02/1999; Uruguay'
  };
  const options = {
      pinataMetadata: {
          name: 'MyCustomName',
          keyvalues: {
              customKey: 'customValue',
              customKey2: 'customValue2'
          }
      },
      pinataOptions: {
          cidVersion: 0
      }
  };
  pinata.pinJSONToIPFS(body, options).then((result) => {
      //handle results here
      console.log(result.IpfsHash);
  }).catch((err) => {
      //handle error here
      console.log(err);
  });

    let finald = 1;
    await fetchPayout().then(data =>{
       
       finald = Number(data);
       return Number(data)
  });

  console.log(finald);
  const ops = {
    contractAddress: marketAddress,
    functionName: buyInsuranceFunction,
    abi: contractABIJson,
    msgValue: finald,
    params: {
      tokenId: amount
    },
  };

  await contractProcessor.fetch({
    params: ops,
    onSuccess: () => {
      console.log("success");
      setIsPending(false);       
    },
    onError: (error) => {
      setIsPending(false);
      alert(error);
    },
  });
  }
  

  return (
    <div style={styles.card}>
      <div style={styles.tranfer}>
        <div style={styles.header}>
          <h3>Set the Once NFT token id from which you want to get details</h3>
        </div>
        <div style={styles.select}>
          <Input
            size="large"
            prefix="#️⃣"
            onChange={(e) => {
              setAmount(`${e.target.value}`);
            }}
          />
        </div>
        <Button
        type="primary"
        size="large"
        style={{ width: "40%", marginTop: "25px", marginLeft: "31%" }}
        href={`https://api.covalenthq.com/v1/80001/tokens/0x447dAEFfeD05280f724A7857Fa0568b0AAb27B99/nft_metadata/${amount}/?key=ckey_9424e31e6b6a47fe82f0cae48d7`}
        target="_blank"
        rel="noopener noreferrer"
        disabled={!tx}
      >
          Search it 🕵️
        </Button>
      </div>
      
    </div>
  );
}

export default Transfer;
