// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {MyToken} from "../src/MyToken.sol";
import {Bank, BigBank} from "../src/Bank.sol";

/**
 * @title DeployScript
 * @notice 部署 MyToken（自建 ERC20）和 Bank/BigBank，并把地址打印到终端。
 *
 * 用法（先复制 .env.example 为 .env 并填好）：
 *   forge script script/Deploy.s.sol --rpc-url $RPC_URL --broadcast --verify
 *
 * 环境变量：
 *   PRIVATE_KEY      部署者 EOA 私钥（0x 开头）
 *   RPC_URL          Sepolia RPC
 *   TOKEN_NAME       可选，默认 LabToken
 *   TOKEN_SYMBOL     可选，默认 LAB
 *   DEPLOY_BIGBANK  可选，默认 true；设为 false 则部署普通 Bank
 */
contract DeployScript is Script {
    function run() public {
        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        string memory tokenName = vm.envOr("TOKEN_NAME", string("LabToken"));
        string memory tokenSymbol = vm.envOr("TOKEN_SYMBOL", string("LAB"));
        bool deployBigBank = vm.envOr("DEPLOY_BIGBANK", true);

        vm.startBroadcast(privateKey);

        // 1) 自建 ERC20，初始 1,000,000 枚 mint 给部署者
        MyToken token = new MyToken(tokenName, tokenSymbol, 1_000_000e18);
        console.log("MyToken(address):", address(token));

        // 2) 部署银行合约：默认 BigBank（继承练习完整，存款须 >0.001 ETH）
        if (deployBigBank) {
            BigBank bank = new BigBank();
            console.log("BigBank(address):", address(bank));
        } else {
            Bank bank = new Bank();
            console.log("Bank(address):", address(bank));
        }

        vm.stopBroadcast();
    }
}
