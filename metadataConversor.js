//https://docs.metaplex.com/programs/token-metadata/token-standard
var fashionData = require("./fashion_frame_88.json")


async function main() {

const entries = Object.entries(fashionData);
let num = entries[0][0];
let myObj = fashionData[`${num}`].traits["0"]
let lObj = []
for(let i in myObj){
    lObj.push({
        "trait_type": i,
        "value": myObj[`${i}`]
    })
}

let fObj = {}
fObj.name = "Fashion Frame";
fObj.symbol = "Fashion Frame";
fObj.description = "Fashion";
fObj.image = "fashion.png";
fObj.attributes = lObj

console.log(fObj)

}

main()
