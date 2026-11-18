// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {IBank} from "../src/Bank.sol";

/**
 * @title TransferOwnerScript
 * @notice 由当前 owner（部署者 EOA）把银行合约管理员移交给 Safe 多签。
 *         必须在 Safe 创建完成、且多签地址已知之后运行。
 *
 * 环境变量：
 *   PRIVATE_KEY  当前 owner 的私钥
 *   BANK_ADDR    Bank/BigBank 合约地址
 *   SAFE_ADDR    Safe 多签地址
 *
 * 用法：
 *   forge script script/TransferOwner.s.sol --rpc-url $RPC_URL --broadcast
 */
contract TransferOwnerScript is Script {
    function run() public {
        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        address bank = vm.envAddress("BANK_ADDR");
        address safe = vm.envAddress("SAFE_ADDR");

        vm.startBroadcast(privateKey);
        IBank(bank).transferOwner(safe);
        console.log("new owner:", IBank(bank).owner());
        vm.stopBroadcast();
    }
}
