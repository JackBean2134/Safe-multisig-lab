// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IBank {
    function deposit() external payable;
    function withdraw() external;
    function transferOwner(address newOwner) external;
    function owner() external view returns (address);
}

contract Bank is IBank {
    address public override owner;
    mapping(address => uint256) public balances;
    event Deposit(address indexed user, uint256 amount);
    event Withdraw(uint256 amount);
    event OwnerTransferred(address oldOwner, address newOwner);

    constructor() {
        owner = msg.sender;
    }

    receive() external payable {
        _deposit(msg.sender, msg.value);
    }

    function deposit() external payable override {
        _deposit(msg.sender, msg.value);
    }

    function _deposit(address user, uint256 amount) internal virtual {
        require(amount > 0, "amount >0");
        balances[user] += amount;
        emit Deposit(user, amount);
    }

    function withdraw() external override {
        require(msg.sender == owner, "only owner");
        uint256 bal = address(this).balance;
        require(bal > 0, "no balance");
        (bool ok,) = payable(owner).call{value: bal}("");
        require(ok, "transfer fail");
        emit Withdraw(bal);
    }

    function transferOwner(address newOwner) external override {
        require(msg.sender == owner, "only owner");
        require(newOwner != address(0), "zero addr");
        address old = owner;
        owner = newOwner;
        emit OwnerTransferred(old, newOwner);
    }
}

contract BigBank is Bank {
    modifier minDeposit(uint256 amount) {
        require(amount > 0.001 ether, "deposit >0.001 ether");
        _;
    }

    function _deposit(address user, uint256 amount) internal override minDeposit(amount) {
        super._deposit(user, amount);
    }
}

contract Admin {
    address public immutable owner;

    constructor() {
        owner = msg.sender;
    }
    receive() external payable {}

    function adminWithdraw(IBank bank) external {
        require(msg.sender == owner, "only Admin owner");
        bank.withdraw();
    }
}
