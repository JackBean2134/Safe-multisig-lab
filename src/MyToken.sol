// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title MyToken
 * @notice 练习用自建 ERC20：部署者即 owner，owner 可随时 mint 给任意地址。
 *         仅用于 Sepolia 等测试网，不要上主网。
 */
contract MyToken is ERC20, Ownable {
    /// @dev 固定 18 位小数（与 ETH 一致，方便心算）
    uint8 private constant DECIMALS = 18;

    constructor(
        string memory name_,
        string memory symbol_,
        uint256 initialSupply_
    ) ERC20(name_, symbol_) Ownable(msg.sender) {
        _mint(msg.sender, initialSupply_);
    }

    /**
     * @notice 仅 owner 可铸造，可把测试币直接 mint 到 Safe 多签地址。
     */
    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }

    function decimals() public pure override returns (uint8) {
        return DECIMALS;
    }
}
