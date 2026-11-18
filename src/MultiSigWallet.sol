// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * @title MultiSigWallet
 * @notice 自研简易 2-of-N 多签：创建时确定 owners 与 threshold；
 *         owner submit 提案 → 其他 owner confirm → 达 threshold 后任何人 execute。
 *         仅用于 Sepolia 测试学习，未做生产级安全加固。
 */
contract MultiSigWallet {
    address[] public owners;
    mapping(address => bool) public isOwner;
    uint256 public threshold;

    struct Transaction {
        address to;
        uint256 value;
        bytes data;
        bool executed;
        uint256 confirmations;
    }

    Transaction[] public transactions;
    mapping(uint256 => mapping(address => bool)) public confirmed;

    event Deposit(address indexed sender, uint256 amount);
    event Submit(uint256 indexed txId);
    event Confirm(uint256 indexed txId, address indexed owner);
    event Execute(uint256 indexed txId);

    modifier onlyOwner() {
        require(isOwner[msg.sender], "not owner");
        _;
    }

    constructor(address[] memory _owners, uint256 _threshold) {
        require(_threshold > 0 && _threshold <= _owners.length, "bad threshold");
        for (uint256 i = 0; i < _owners.length; i++) {
            require(!isOwner[_owners[i]], "duplicate owner");
            isOwner[_owners[i]] = true;
            owners.push(_owners[i]);
        }
        threshold = _threshold;
    }

    receive() external payable {
        emit Deposit(msg.sender, msg.value);
    }

    function submit(address to, uint256 value, bytes calldata data) external onlyOwner returns (uint256 txId) {
        txId = transactions.length;
        transactions.push(Transaction(to, value, data, false, 0));
        emit Submit(txId);
    }

    function confirm(uint256 txId) external onlyOwner {
        Transaction storage txn = transactions[txId];
        require(!txn.executed, "already executed");
        require(!confirmed[txId][msg.sender], "already confirmed");
        confirmed[txId][msg.sender] = true;
        txn.confirmations++;
        emit Confirm(txId, msg.sender);
    }

    function execute(uint256 txId) external {
        Transaction storage txn = transactions[txId];
        require(!txn.executed, "already executed");
        require(txn.confirmations >= threshold, "below threshold");
        txn.executed = true;
        (bool ok,) = txn.to.call{value: txn.value}(txn.data);
        require(ok, "call failed");
        emit Execute(txId);
    }

    function getOwners() external view returns (address[] memory) {
        return owners;
    }

    function getTransactionCount() external view returns (uint256) {
        return transactions.length;
    }
}
