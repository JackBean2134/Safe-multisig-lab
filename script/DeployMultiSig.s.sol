// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {MultiSigWallet} from "../src/MultiSigWallet.sol";

/**
 * @title DeployMultiSigScript
 * @notice 部署自研 MultiSigWallet：owners = [部署者(OwnerA), OWNER_B, OWNER_C]，阈值取 THRESHOLD（默认 2）。
 *
 * 环境变量：
 *   PRIVATE_KEY  OwnerA（部署者）私钥
 *   OWNER_B      OwnerB 地址
 *   OWNER_C      OwnerC 地址
 *   THRESHOLD    可选，默认 2
 *
 * 用法：
 *   set -a; source .env; set +a; export ETH_RPC_URL=$RPC_URL
 *   forge script script/DeployMultiSig.s.sol --rpc-url $RPC_URL --broadcast
 *
 * 兜底（若 forge script 报 contract creation code storage out of gas）：
 *   forge create src/MultiSigWallet.sol:MultiSigWallet --private-key $PRIVATE_KEY \
 *     --gas-limit 6000000 --broadcast \
 *     --constructor-args "$(cast abi-encode 'f(address[],uint256)' $OWNER_A $OWNER_B $OWNER_C 2)"
 *   注意：--constructor-args 必须放命令最后；数组参数用 cast abi-encode 编码。
 */
contract DeployMultiSigScript is Script {
    function run() public {
        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        address ownerB = vm.envAddress("OWNER_B");
        address ownerC = vm.envAddress("OWNER_C");
        uint256 threshold = vm.envOr("THRESHOLD", uint256(2));
        address deployer = vm.addr(privateKey);

        vm.startBroadcast(privateKey);

        address[] memory owners = new address[](3);
        owners[0] = deployer;
        owners[1] = ownerB;
        owners[2] = ownerC;

        MultiSigWallet wallet = new MultiSigWallet(owners, threshold);
        console.log("MultiSigWallet(address):", address(wallet));

        vm.stopBroadcast();
    }
}
