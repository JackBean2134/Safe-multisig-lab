/**
 * propose-withdraw.ts（可选进阶）
 * ------------------------------------------------------------------
 * 从已部署的 Safe 发起 Bank.withdraw() 提案：
 *   phase 1：owner A 构造提案并提交到 Safe 交易服务（propose）
 *   phase 2：owner B 签名确认（confirm）
 *   phase 3：任一 owner 收集签名后执行（execute）
 *
 * 网页版操作见《Safe 2-of-3 多签实操指南.md》第 5 步；本脚本演示 SDK 等价流程。
 *
 * 运行：
 *   npm run propose-withdraw
 *
 * 环境变量（见 scripts/.env.example）：
 *   RPC_URL、PRIVATE_KEY（owner A）、SAFE_ADDR、BANK_ADDR
 *   再准备 owner B 的私钥放在 OWNER_B_PRIVATE_KEY，用于第二签名
 */
import 'dotenv/config';
import Safe from '@safe-global/protocol-kit';
import SafeApiKit from '@safe-global/api-kit';
import type { Hex } from 'viem';

const RPC_URL = process.env.RPC_URL!;
const PRIVATE_KEY = process.env.PRIVATE_KEY!;
const SAFE_ADDR = process.env.SAFE_ADDR!;
const BANK_ADDR = process.env.BANK_ADDR!;
const OWNER_B_PRIVATE_KEY = process.env.OWNER_B_PRIVATE_KEY!;
const CHAIN_ID = BigInt(11155111); // Sepolia

async function main() {
  const apiKit = new SafeApiKit({ chainId: CHAIN_ID });

  // ---------- phase 1：owner A 发起提案 ----------
  const protocolKit = await Safe.init({
    provider: RPC_URL,
    signer: PRIVATE_KEY,
    safeAddress: SAFE_ADDR,
  });

  // withdraw() 无参数，data = 选择器 0x3ccfd60b；此处直接用 viem 编码等价物
  const withdrawData: Hex = '0x3ccfd60b';

  const safeTransaction = await protocolKit.createTransaction({
    transactions: [
      {
        to: BANK_ADDR as Hex,
        data: withdrawData,
        value: '0',
        operation: 0, // 0 = CALL
      },
    ],
  });

  const safeTxHash = await protocolKit.getTransactionHash(safeTransaction);
  const senderAddress =
    (await protocolKit.getSafeProvider().getSignerAddress()) ?? '';
  const senderSignature = await protocolKit.signHash(safeTxHash);

  await apiKit.proposeTransaction({
    safeAddress: SAFE_ADDR,
    safeTransactionData: safeTransaction.data,
    safeTxHash,
    senderAddress,
    senderSignature: senderSignature.data,
    origin: 'Safe 2-of-3 lab: withdraw proposal',
  });
  console.log('提案已提交, safeTxHash =', safeTxHash);

  // ---------- phase 2：owner B 确认 ----------
  const kitB = await Safe.init({
    provider: RPC_URL,
    signer: OWNER_B_PRIVATE_KEY,
    safeAddress: SAFE_ADDR,
  });
  const signatureB = await kitB.signHash(safeTxHash);
  await apiKit.confirmTransaction(safeTxHash, signatureB.data);
  console.log('owner B 已确认');

  // ---------- phase 3：执行（2 个签名已满足阈值） ----------
  const txFromService = await apiKit.getTransaction(safeTxHash);
  const isValid = await protocolKit.isValidTransaction(txFromService);
  console.log('isValidTransaction =', isValid);
  if (!isValid) throw new Error('交易校验失败，检查 nonce / 余额 / owner 权限');

  const executeResponse = await protocolKit.executeTransaction(txFromService);
  console.log('执行交易 hash:', executeResponse.hash);
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
