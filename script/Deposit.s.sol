// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {IBank} from "../src/Bank.sol";

/**
 * @title DepositScript
 * @notice 便利脚本：由 EOA 给 BigBank 存一笔 ETH（仅练习用）。
 *         BigBank 要求单笔 >0.001 ETH。
 *
 * 环境变量：
 *   PRIVATE_KEY   存款 EOA 私钥
 *   BANK_ADDR     Bank/BigBank 合约地址
 *   DEPOSIT_WEI   存款金额（wei），如 0.002 ETH = 2000000000000000
 *
 * 用法：
 *   forge script script/Deposit.s.sol --rpc-url $RPC_URL --broadcast
 */
contract DepositScript is Script {
    function run() public {
        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        address bank = vm.envAddress("BANK_ADDR");
        uint256 amount = vm.envUint("DEPOSIT_WEI");

        vm.startBroadcast(privateKey);
        IBank(bank).deposit{value: amount}();
        console.log("deposited wei:", amount);
        vm.stopBroadcast();
    }
}
