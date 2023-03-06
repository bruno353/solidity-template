/** selecionar qual versão do solidity você vai usar para o compilador saber:
 nesse caso será o solidity entre 0.7 e 0.9*/
pragma solidity >=0.6.0 <0.9.0;

import "./SimpleStorage.sol";

contract StorageFactory{
    //criando uma struct SimpleStorage:
    SimpleStorage[] public simpleStoragearray;


    //função para criar um contrato SimpleStorage.sol:
    function criar_teste_contrato() public {

        //criando um objeto SimpleStorage
        SimpleStorage simpleStorage = new SimpleStorage();
        simpleStoragearray.push(simpleStorage);

    }
}
