/**
 * create-safe.ts（可选进阶）
 * ------------------------------------------------------------------
 * 用 Safe Protocol Kit v8 + Viem 程序化部署一个 2/3 Safe。
 * 网页版创建更简单，本脚本只用于理解 SDK 原理。
 *
 * 运行前在 scripts/.env 填好：RPC_URL、PRIVATE_KEY、OWNER_ADDRESSES、THRESHOLD=2
 *   npm run create-safe
 *
 * 注意：部署 Safe 的 gas 由发起私钥（signer）支付。
 */
import 'dotenv/config';
import Safe, { getSafeAddressFromDeploymentTx } from '@safe-global/protocol-kit';
import { createWalletClient, http, type Hex } from 'viem';
import { waitForTransactionReceipt } from 'viem/actions';
import { sepolia } from 'viem/chains';
import { privateKeyToAccount } from 'viem/accounts';

const RPC_URL = process.env.RPC_URL!;
const PRIVATE_KEY = process.env.PRIVATE_KEY!;
const OWNERS = (process.env.OWNER_ADDRESSES || '').split(',').map((s) => s.trim());
const THRESHOLD = Number(process.env.THRESHOLD || '2');

async function main() {
  if (!RPC_URL || !PRIVATE_KEY || OWNERS.length !== 3) {
    throw new Error('请先在 scripts/.env 填写 RPC_URL / PRIVATE_KEY / OWNER_ADDRESSES（3 个地址）');
  }

  const signerKey = (PRIVATE_KEY.startsWith('0x') ? PRIVATE_KEY : `0x${PRIVATE_KEY}`) as Hex;
  const account = privateKeyToAccount(signerKey);
  const walletClient = createWalletClient({
    account,
    chain: sepolia,
    transport: http(RPC_URL),
  });

  // predictedSafe：尚未部署的 Safe 配置（owners + threshold），地址可确定性预测
  const protocolKit = await Safe.init({
    provider: RPC_URL,
    signer: signerKey,
    predictedSafe: {
      safeAccountConfig: { owners: OWNERS, threshold: THRESHOLD },
      safeDeploymentConfig: { saltNonce: String(Date.now()) },
    },
  });

  // 拿到部署交易（to=ProxyFactory，data=初始化编码），用 viem 广播
  const deploymentTx = await protocolKit.createSafeDeploymentTransaction();
  console.log('部署交易已构造，正在广播……');
  const txHash = await walletClient.sendTransaction({
    to: deploymentTx.to as Hex,
    value: BigInt(deploymentTx.value ?? '0'),
    data: deploymentTx.data as Hex,
  });
  console.log('deployment tx hash:', txHash);

  const receipt = await waitForTransactionReceipt(walletClient, { hash: txHash });
  const safeVersion = await protocolKit.getContractVersion();
  const safeAddress = getSafeAddressFromDeploymentTx(receipt, safeVersion);
  console.log('Safe 地址:', safeAddress);
  console.log('Safe 网页链接: https://app.safe.global/sep:' + safeAddress);

  // 用部署后的地址重新连接，校验 owner / 阈值
  const connected = await protocolKit.connect({ safeAddress });
  console.log('isDeployed :', await connected.isSafeDeployed());
  console.log('owners     :', await connected.getOwners());
  console.log('threshold  :', await connected.getThreshold());
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
