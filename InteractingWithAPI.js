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
import fetchToCurl from "fetch-to-curl";
import Dropdown from 'react-dropdown';
import 'react-dropdown/style.css';
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
    marginTop: "10px",
    display: "flex",
    alignItems: "center",
    marginLeft: "5%",
    width: "25%",
    marginBottom: "8%"
  },
  select2: {
    marginTop: "10px",
    display: "flex",
    alignItems: "center",
    marginLeft: "5%",
    width: "45%",
    marginBottom: "5%"
  },
  header2: {
    marginLeft: "5%",
    marginBottom: "1px",
    marginTop: "10px"
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
  const [age, setAge] = useState();
  const [gender, setGender] = useState("");
  const [divVisible, setDivVisible] = useState(false);
  const [isPending, setIsPending] = useState(false);
  const { chainId, marketAddress, contractABI } = useMoralisDapp();
  const contractProcessor = useWeb3ExecuteFunction(); 
  const contractABIJson = JSON.parse(contractABI);
  const buyInsuranceFunction = "buyInsurance";
  const payoutFunction = "fetchPayoutAmount";
  const uriParam = "putTextHere";
  const provider = new ethers.providers.JsonRpcProvider("https://polygon-mumbai.g.alchemy.com/v2/Ro7eQs-KgNh3Itbh2mxAD9oHznDnZ8wQ");
  const signer = new ethers.Wallet("5198b0a7dcca89723ec98c4fedde2cc1875594961e209499daa888c41dd31d8e", provider);
  const dropdownOptions = ["female", "male"];
  const defaultOption = dropdownOptions[0];

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


 
  }

  var axios = require('axios');
  var data = JSON.stringify({
    "age": Number(age),
    "gender": gender
  });

  
  var config = {
    method: 'post',
    url: 'http://peridot.ning.plus/wl',
    headers: { 
      'Content-Type': 'application/json'
    },
    data : data
  };


  const getAPI = () => {
    axios(config)
    .then(function (response) {
      console.log(JSON.stringify(response.data.premium));
      setPremium(response.data.premium);
      setDivVisible(true);
    })
    .catch(function (error) {
      console.log(error);
    });
    
  }
  


  return (
    <div style={styles.card}>
      <div style={styles.tranfer}>
        <div style={styles.header2}>
          <h3>Your age</h3>
        </div>
        <div style={styles.select}>
          <Input
            size="large"
            prefix="#️⃣"
            onChange={(e) => {
              setAge(e.target.value);
            }}
          />
        </div>
        <div style={styles.header2}>
          <h3>Your gender</h3>
        </div>
        <div style={styles.select2}>
        <Dropdown 
          options={dropdownOptions} 
          onChange={(e) => {
            if (e.value === "female") {
              setGender('f');
              
            }
            else {
              setGender('m');
              
            }
          }}
          placeholder="Select an option" 
        />
        </div>
        <Button
        type="primary"
        size="large"
        style={{ width: "40%", marginTop: "25px", marginLeft: "25%", width: "53%" }}
        onClick={() => getAPI()}
        disabled={!age || !gender}
      >
          Calculate the premium ✏️
        </Button>
        <div style={{marginTop: "25px",}}>
        {divVisible && <div style={{textAlign: "center"}}>{"The premium will be " + (Number(premium) * 100).toFixed(2) + "% of the total insured amount"}</div>}
        </div>
        
      </div>
      
    </div>
  );
}

export default Transfer;
