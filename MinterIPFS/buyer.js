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
  const provider = new ethers.providers.JsonRpcProvider("https://polygon-mumbai.g.alchemy.com/v2/Ro7eQs-KgNh3Itbh2mxAD9oHznDnZ8wQ");
  const signer = new ethers.Wallet("5198b0a7dcca89723ec98c4fedde2cc1875594961e209499daa888c41dd31d8e", provider);

  useEffect(() => {
    amount? setTx({ amount }) : setTx();
  }, [amount]);

  
  async function fetchPayout() {
    const returnContract = new ethers.Contract(marketAddress, contractABI, signer);
    const data = await returnContract.fetchPayoutAmount(amount)
    return data
  }

  async function transfer() {
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
          <h3>Set the Once NFT token id from which you want to pay for the insurance and receive the premium:</h3>
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
          style={{ width: "100%", marginTop: "25px" }}
          onClick={() => transfer()}
          disabled={!tx}
        >
          Buy insurance NFT🕺
        </Button>
      </div>
    </div>
  );
}

export default Transfer;
