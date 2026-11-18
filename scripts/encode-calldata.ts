/**
 * encode-calldata.ts
 * ------------------------------------------------------------------
 * 用 viem 编码本练习需要的三笔调用 calldata：
 *   1) ERC20.transfer(to, amount)        —— 从 Safe 转出自建代币
 *   2) Bank.transferOwner(newOwner)      —— EOA 移交管理员给 Safe
 *   3) Bank.withdraw()                   —— Safe 提案提取合约全部 ETH
 *
 * 在 Safe 网页发起「自定义交易 / Custom data」提案时，
 * 需要把 to 与 data 分别填进提案表单，本脚本就是生成这两项。
 *
 * 运行：
 *   npm run encode
 *
 * 环境变量（见 .env.example）：RECIPIENT、AMOUNT_ETHER、SAFE_ADDR、BANK_ADDR
 */
import 'dotenv/config';
import {
  encodeFunctionData,
  keccak256,
  toBytes,
  parseEther,
  type Address,
} from 'viem';

const ERC20_ABI = [
  {
    type: 'function',
    name: 'transfer',
    stateMutability: 'nonpayable',
    inputs: [
      { name: 'to', type: 'address' },
      { name: 'amount', type: 'uint256' },
    ],
    outputs: [{ type: 'bool' }],
  },
] as const;

const BANK_ABI = [
  {
    type: 'function',
    name: 'withdraw',
    stateMutability: 'nonpayable',
    inputs: [],
    outputs: [],
  },
  {
    type: 'function',
    name: 'transferOwner',
    stateMutability: 'nonpayable',
    inputs: [{ name: 'newOwner', type: 'address' }],
    outputs: [],
  },
] as const;

/** 函数选择器 = keccak256("函数签名") 前 4 字节 */
function selector(sig: string): string {
  return keccak256(toBytes(sig)).slice(0, 10);
}

function main() {
  const recipient = (process.env.RECIPIENT || '') as Address;
  const amountEther = process.env.AMOUNT_ETHER || '100';
  const safeAddr = (process.env.SAFE_ADDR || '') as Address;
  const bankAddr = (process.env.BANK_ADDR || '') as Address;

  console.log('=== 函数选择器（keccak256 前 4 字节）===');
  console.log('transfer(address,uint256)  ->', selector('transfer(address,uint256)'));
  console.log('transferOwner(address)     ->', selector('transferOwner(address)'));
  console.log('withdraw()                 ->', selector('withdraw()'));
  console.log();

  // 1) ERC20.transfer：to=收款地址，amount=枚数（18 位小数）
  const transferCalldata = encodeFunctionData({
    abi: ERC20_ABI,
    functionName: 'transfer',
    args: [recipient, parseEther(amountEther)],
  });
  console.log('=== 1) ERC20.transfer 提案 ===');
  console.log('to   :', '<你的 MyToken 合约地址>');
  console.log('data :', transferCalldata);
  console.log();

  // 2) transferOwner：由 EOA 在移交阶段调用（也可作为 Safe 提案演练）
  const transferOwnerCalldata = encodeFunctionData({
    abi: BANK_ABI,
    functionName: 'transferOwner',
    args: [safeAddr],
  });
  console.log('=== 2) Bank.transferOwner 移交管理员 ===');
  console.log('to   :', bankAddr);
  console.log('data :', transferOwnerCalldata);
  console.log();

  // 3) withdraw()：无参数，calldata 就是选择器本身
  const withdrawCalldata = encodeFunctionData({
    abi: BANK_ABI,
    functionName: 'withdraw',
    args: [],
  });
  console.log('=== 3) Bank.withdraw() 提案（从 Safe 发起）===');
  console.log('to   :', bankAddr);
  console.log('data :', withdrawCalldata);
  console.log('value: 0（withdraw 不向合约转账，只把合约 ETH 打给 owner=Safe）');
}

main();
