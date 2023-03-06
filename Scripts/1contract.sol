/** selecionar qual versão do solidity você vai usar para o compilador saber:
 nesse caso será o solidity entre 0.7 e 0.9*/
pragma solidity >=0.6.0 <0.9.0;

//para criar um contrato: contract. é como se fosse uma classe no js:
//criando um contrato chamado SimpleStorage:
contract SimpleStorage{
	struct People{
		int256 numero;
		string nome;
		}
	People[] public pessoa;
	//fazer um mapping chamado "mapear" que ao digitar uma string retorne um int:
	mapping(string => int256) public mapear;
	function add_pessoa(string memory _nome, int256 _numero) public{
	pessoa.push(People({numero: _numero, nome: _nome}));
	//associando denro da função o mapping:
	mapear[_nome] = _numero;
}
}
