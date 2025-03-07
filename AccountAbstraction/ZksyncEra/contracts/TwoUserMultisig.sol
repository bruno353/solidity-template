// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@matterlabs/zksync-contracts/l2/system-contracts/interfaces/IAccount.sol";
import "@matterlabs/zksync-contracts/l2/system-contracts/libraries/TransactionHelper.sol";

import "@openzeppelin/contracts/interfaces/IERC1271.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

import "@matterlabs/zksync-contracts/l2/system-contracts/Constants.sol";
import "@matterlabs/zksync-contracts/l2/system-contracts/libraries/SystemContractsCaller.sol";

/**
 * @title TwoUserMultisig
 * @notice Carteira multisig para dois usuários que implementa IAccount e IERC1271 para validação de assinaturas.
 */
contract TwoUserMultisig is IAccount, IERC1271 {
    using TransactionHelper for Transaction;

    // Endereços dos proprietários da conta.
    address public owner1;
    address public owner2;

    // Valor mágico EIP1271 para assinatura válida.
    bytes4 internal constant EIP1271_SUCCESS_RETURN_VALUE = 0x1626ba7e;

    /**
     * @notice Restrição para chamadas feitas apenas pelo bootloader.
     */
    modifier onlyBootloader() {
        require(
            msg.sender == BOOTLOADER_FORMAL_ADDRESS,
            "Only bootloader can call this function"
        );
        _;
    }

    /**
     * @notice Inicializa o contrato com os dois proprietários.
     * @param _owner1 Endereço do primeiro proprietário.
     * @param _owner2 Endereço do segundo proprietário.
     */
    constructor(address _owner1, address _owner2) {
        owner1 = _owner1;
        owner2 = _owner2;
    }

    /**
     * @notice Valida uma transação assinada pelos proprietários.
     * @param _suggestedSignedHash Hash sugerido para assinatura da transação.
     * @param _transaction Dados da transação.
     * @return magic Valor mágico indicando sucesso na validação.
     */
    function validateTransaction(
        bytes32, // parâmetro não utilizado
        bytes32 _suggestedSignedHash,
        Transaction calldata _transaction
    ) external payable override onlyBootloader returns (bytes4 magic) {
        return _validateTransaction(_suggestedSignedHash, _transaction);
    }

    /**
     * @notice Função interna para validação da transação.
     * @param _suggestedSignedHash Hash sugerido para a assinatura da transação.
     * @param _transaction Dados da transação.
     * @return magic Valor mágico indicando sucesso na validação.
     */
    function _validateTransaction(
        bytes32 _suggestedSignedHash,
        Transaction calldata _transaction
    ) internal returns (bytes4 magic) {
        // Incrementa o nonce da conta utilizando o contrato do sistema.
        SystemContractsCaller.systemCallWithPropagatedRevert(
            uint32(gasleft()),
            address(NONCE_HOLDER_SYSTEM_CONTRACT),
            0,
            abi.encodeCall(INonceHolder.incrementMinNonceIfEquals, (_transaction.nonce))
        );

        // Define o hash da transação: utiliza o sugerido se disponível ou calcula-o.
        bytes32 txHash = _suggestedSignedHash == bytes32(0)
            ? _transaction.encodeHash()
            : _suggestedSignedHash;

        // Verifica se há saldo suficiente para cobrir o fee e o valor da transação.
        uint256 totalRequiredBalance = _transaction.totalRequiredBalance();
        require(totalRequiredBalance <= address(this).balance, "Not enough balance for fee + value");

        // Valida a assinatura e retorna o valor mágico apropriado.
        if (isValidSignature(txHash, _transaction.signature) == EIP1271_SUCCESS_RETURN_VALUE) {
            magic = ACCOUNT_VALIDATION_SUCCESS_MAGIC;
        } else {
            magic = bytes4(0);
        }
    }

    /**
     * @notice Executa uma transação previamente validada.
     * @param _transaction Dados da transação.
     */
    function executeTransaction(
        bytes32, // parâmetro não utilizado
        bytes32, // parâmetro não utilizado
        Transaction calldata _transaction
    ) external payable override onlyBootloader {
        _executeTransaction(_transaction);
    }

    /**
     * @notice Função interna para execução da transação.
     * @param _transaction Dados da transação.
     */
    function _executeTransaction(Transaction calldata _transaction) internal {
        address to = address(uint160(_transaction.to));
        uint128 value = Utils.safeCastToU128(_transaction.value);
        bytes memory data = _transaction.data;

        // Se a transação for destinada ao contrato de deployer, utiliza chamada via systemCall.
        if (to == address(DEPLOYER_SYSTEM_CONTRACT)) {
            uint32 gasAvailable = Utils.safeCastToU32(gasleft());
            SystemContractsCaller.systemCallWithPropagatedRevert(gasAvailable, to, value, data);
        } else {
            bool success;
            assembly {
                success := call(gas(), to, value, add(data, 0x20), mload(data), 0, 0)
            }
            require(success, "Transaction execution failed");
        }
    }

    /**
     * @notice Executa uma transação enviada de fora da conta.
     * @param _transaction Dados da transação.
     */
    function executeTransactionFromOutside(Transaction calldata _transaction) external payable {
        _validateTransaction(bytes32(0), _transaction);
        _executeTransaction(_transaction);
    }

    /**
     * @notice Valida uma assinatura conforme o padrão EIP1271.
     * @param _hash Hash dos dados assinados.
     * @param _signature Dados da assinatura.
     * @return magic Valor mágico indicando a validade da assinatura.
     */
    function isValidSignature(bytes32 _hash, bytes memory _signature)
        public
        view
        override
        returns (bytes4 magic)
    {
        magic = EIP1271_SUCCESS_RETURN_VALUE;

        // Se o tamanho da assinatura não for 130 bytes, cria uma assinatura dummy para fins de estimativa de fee.
        if (_signature.length != 130) {
            _signature = new bytes(130);
            _signature[64] = bytes1(uint8(27));
            _signature[129] = bytes1(uint8(27));
        }

        (bytes memory signature1, bytes memory signature2) = extractECDSASignature(_signature);

        // Verifica se ambas as assinaturas estão em formato ECDSA válido.
        if (!checkValidECDSASignatureFormat(signature1) || !checkValidECDSASignatureFormat(signature2)) {
            magic = bytes4(0);
        }

        address recoveredAddr1 = ECDSA.recover(_hash, signature1);
        address recoveredAddr2 = ECDSA.recover(_hash, signature2);

        // Confirma que os endereços recuperados correspondem aos proprietários.
        if (recoveredAddr1 != owner1 || recoveredAddr2 != owner2) {
            magic = bytes4(0);
        }
    }

    /**
     * @notice Verifica se uma assinatura ECDSA está em formato válido e não é malleável.
     * @param _signature A assinatura ECDSA a ser verificada.
     * @return valid True se a assinatura for válida, false caso contrário.
     */
    function checkValidECDSASignatureFormat(bytes memory _signature) internal pure returns (bool valid) {
        if (_signature.length != 65) {
            return false;
        }

        uint8 v;
        bytes32 r;
        bytes32 s;
        // Carrega os parâmetros da assinatura.
        assembly {
            r := mload(add(_signature, 0x20))
            s := mload(add(_signature, 0x40))
            v := and(mload(add(_signature, 0x41)), 0xff)
        }
        if (v != 27 && v != 28) {
            return false;
        }

        // Verifica se o valor 's' está na metade inferior da ordem.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return false;
        }

        return true;
    }
    
    /**
     * @notice Extrai duas assinaturas ECDSA de uma assinatura concatenada.
     * @param _fullSignature Assinatura concatenada contendo duas assinaturas.
     * @return signature1 A primeira assinatura (65 bytes).
     * @return signature2 A segunda assinatura (65 bytes).
     */
    function extractECDSASignature(bytes memory _fullSignature)
        internal
        pure
        returns (bytes memory signature1, bytes memory signature2)
    {
        require(_fullSignature.length == 130, "Invalid signature length");

        signature1 = new bytes(65);
        signature2 = new bytes(65);

        // Extrai a primeira assinatura.
        assembly {
            let r := mload(add(_fullSignature, 0x20))
            let s := mload(add(_fullSignature, 0x40))
            let v := and(mload(add(_fullSignature, 0x41)), 0xff)

            mstore(add(signature1, 0x20), r)
            mstore(add(signature1, 0x40), s)
            mstore8(add(signature1, 0x60), v)
        }

        // Extrai a segunda assinatura.
        assembly {
            let r := mload(add(_fullSignature, 0x61))
            let s := mload(add(_fullSignature, 0x81))
            let v := and(mload(add(_fullSignature, 0x82)), 0xff)

            mstore(add(signature2, 0x20), r)
            mstore(add(signature2, 0x40), s)
            mstore8(add(signature2, 0x60), v)
        }
    }

    /**
     * @notice Efetua o pagamento da taxa para o bootloader.
     * @param _transaction Dados da transação.
     */
    function payForTransaction(
        bytes32, // parâmetro não utilizado
        bytes32, // parâmetro não utilizado
        Transaction calldata _transaction
    ) external payable override onlyBootloader {
        bool success = _transaction.payToTheBootloader();
        require(success, "Failed to pay the fee to the operator");
    }

    /**
     * @notice Prepara a transação para o paymaster.
     * @param _transaction Dados da transação.
     */
    function prepareForPaymaster(
        bytes32, // _txHash (não utilizado)
        bytes32, // _suggestedSignedHash (não utilizado)
        Transaction calldata _transaction
    ) external payable override onlyBootloader {
        _transaction.processPaymasterInput();
    }

    /**
     * @notice Função fallback que impede chamadas diretas do bootloader.
     */
    fallback() external {
        // Garante que o bootloader não chame a função fallback.
        assert(msg.sender != BOOTLOADER_FORMAL_ADDRESS);
    }

    /**
     * @notice Função receive para aceitar transferências ETH.
     */
    receive() external payable {}
}
