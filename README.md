# safe-multisig-lab

在 **Sepolia 测试网**上完成「自建 ERC20 → 2/3 Safe 多签 → 代币存取 → 管理员移交 → 多签调用 Bank.withdraw()」全流程的 Foundry 项目骨架。

> 主流程以 Safe 网页版（app.safe.global）操作为主，本项目只负责**合约部署与 EOA 侧交易**；网页操作步骤见上级目录的《Safe 2-of-3 多签实操指南.md》。

## 目录结构

```
safe-multisig-lab/
├── foundry.toml
├── remappings.txt
├── .env.example
├── src/
│   ├── MyToken.sol        # 自建 ERC20（owner 可 mint）
│   ├── Bank.sol           # 用户提供的 Bank / BigBank / Admin 源码（原样保留）
│   └── MultiSigWallet.sol # 自研简易 2-of-3 多签（submit/confirm/execute）
├── script/
│   ├── Deploy.s.sol        # 部署 MyToken + BigBank/Bank，打印地址
│   ├── DeployMultiSig.s.sol# 部署自研 MultiSigWallet（owners/threshold 读 .env）
│   ├── TransferOwner.s.sol # EOA 把管理员移交给 Safe 多签
│   └── Deposit.s.sol       # EOA 给 BigBank 存 ETH（便利脚本）
└── scripts/              # 可选的 TypeScript / Viem 示例（见该目录 README）
```

## 1. 环境准备

- 已安装 Foundry（`forge`、`cast`、`anvil`）：未安装见教程附录；WSL2 内执行
  ```bash
  curl -L https://foundry.paradigm.xyz | bash
  export PATH="$PATH:$HOME/.foundry/bin"   # 具体路径按安装器提示
  foundryup
  ```
- 一个测试网 EOA（MetaMask 新建一个，只放测试币），并领取 Sepolia ETH（见教程水龙头清单）。

## 2. 安装依赖

本项目用 remappings 引用 OpenZeppelin 与 forge-std，首次拉取依赖：

```bash
cd safe-multisig-lab
forge install OpenZeppelin/openzeppelin-contracts
forge install foundry-rs/forge-std
```

国内拉取 git 慢/失败时，给 git 配代理后重试：

```bash
git config --global http.proxy  http://127.0.0.1:7890
git config --global https.proxy http://127.0.0.1:7890
# 或一次性：FOUNDRY_GIT_PROXY=http://127.0.0.1:7890 forge install ...
```

编译检查：

```bash
forge build
```

## 3. 配置 .env

```bash
cp .env.example .env
```

编辑 `.env`，至少填写：

- `PRIVATE_KEY`：测试网 EOA 私钥（0x 开头）
- `RPC_URL`：Sepolia 公共 RPC（`.env.example` 里列了备选）
- `ETHERSCAN_API_KEY`：可选，仅 `--verify` 时需要（从 sepolia.etherscan.io 申请）

## 4. 部署

先加载环境变量（每开一个新终端都要重新执行；`forge create` 认 `ETH_RPC_URL`）：

```bash
set -a; source .env; set +a
export ETH_RPC_URL=$RPC_URL
```

部署 MyToken 与 BigBank（默认）：

```bash
forge script script/Deploy.s.sol --rpc-url $RPC_URL --broadcast
```

终端会打印：

```
MyToken(address): 0x........
BigBank(address): 0x........
```

> 只想要普通 Bank：`.env` 里设 `DEPLOY_BIGBANK=false`。

### 兜底：out of gas / 连 localhost:8545

Sepolia 上 `forge script` 默认 gas 上限可能盖不住合约创建（代码存款费 200 gas/字节），报 `contract creation code storage out of gas`。改用 `forge create` 并显式抬高 gas（`--constructor-args` 必须放命令最后）：

```bash
forge create src/MyToken.sol:MyToken --private-key $PRIVATE_KEY \
  --gas-limit 8000000 --broadcast \
  --constructor-args "LabToken" "LAB" 1000000000000000000000000

forge create src/Bank.sol:BigBank --private-key $PRIVATE_KEY \
  --gas-limit 6000000 --broadcast
```

免费 RPC（publicnode）出现 `in-flight transaction limit reached for delegated accounts` 或 gas 估算失真时，换 Alchemy / Infura 带 key 的 RPC。

## 5. 后续 EOA 侧操作（Safe 创建完成后）

```bash
# 把 BANK_ADDR、SAFE_ADDR 填进 .env，再执行：
forge script script/TransferOwner.s.sol --rpc-url $RPC_URL --broadcast

# （可选）EOA 先给 BigBank 存一笔 >0.001 ETH
forge script script/Deposit.s.sol --rpc-url $RPC_URL --broadcast
```

多签内发起的 ERC20 转账、`withdraw()` 提案都在 Safe 网页完成，步骤见《Safe 2-of-3 多签实操指南.md》。

## 5.1 自研 MultiSigWallet 对照实验（可选）

`src/MultiSigWallet.sol` 是手写的最小 2-of-3 多签：`submit` 提案 → 两位 owner `confirm` → 任何人 `execute`。`.env` 已预填本次练习的三位 owner（OwnerA=`0xf7786E7e83B1f1436eab3D6512074Ad7Dee6922a`、OwnerB=`0x46D5D353259078Fe7FC3d201891D96f6634b6AC6`、OwnerC=`0x1DdA6Dc41606bC25f2AafCE38b33467bDAc0c8E6`，threshold=2）。

```bash
# 部署（owners/threshold 从 .env 读）
set -a; source .env; set +a; export ETH_RPC_URL=$RPC_URL
forge script script/DeployMultiSig.s.sol --rpc-url $RPC_URL --broadcast

# 兜底：forge create 显式 gas，数组构造参数用方括号逗号列表，--constructor-args 放最后
forge create src/MultiSigWallet.sol:MultiSigWallet --private-key $PRIVATE_KEY \
  --gas-limit 6000000 --broadcast \
  --constructor-args "[$OWNER_A, $OWNER_B, $OWNER_C]" 2
```

演示「转 1000 LAB 给 OwnerB」：先给多签充值，再由 OwnerA `submit`（`to` 填 **Token 合约地址**，`data` 用 `cast calldata "transfer(address,uint256)" $OWNER_B 1000000000000000000000`），OwnerB/OwnerC 各自 `confirm(0)`，最后 `execute(0)`。完整命令与验证见指南第 8 节。

## 常见问题

- **`failed to solve: ... openzeppelin`**：依赖没装，回到第 2 步 `forge install`。
- **`nonce too low` / `nonce too high`**：同一私钥有未确认交易或本地 nonce 滞后，等上一笔上链后重试，或换 RPC。
- **RPC 429 / 限流**：换一个公共 RPC（publicnode / Alchemy / Infura 轮换）。
- **`contract creation code storage out of gas`**：默认 gas 上限盖不住合约创建，改用 `forge create --gas-limit 8000000`（Token）/ `6000000`（BigBank），见第 4 节兜底。
- **`constructor argument count mismatch`**：`--constructor-args` 必须放在命令最后。
- **`connection refused` 连 localhost:8545**：新终端先 `set -a; source .env; set +a` 并 `export ETH_RPC_URL=$RPC_URL`。
- **`in-flight transaction limit reached for delegated accounts`**：免费 RPC 限频，换 Alchemy / Infura 带 key RPC。
- **私钥不要加引号、不要带 `0x` 以外空格**；`vm.envUint` 接受带 `0x` 的十六进制。
