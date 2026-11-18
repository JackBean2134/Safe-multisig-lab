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
│   └── Bank.sol           # 用户提供的 Bank / BigBank / Admin 源码（原样保留）
├── script/
│   ├── Deploy.s.sol       # 部署 MyToken + BigBank/Bank，打印地址
│   ├── TransferOwner.s.sol# EOA 把管理员移交给 Safe 多签
│   └── Deposit.s.sol      # EOA 给 BigBank 存 ETH（便利脚本）
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

先加载环境变量（WSL2 / zsh）：

```bash
set -a; source .env; set +a
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

## 5. 后续 EOA 侧操作（Safe 创建完成后）

```bash
# 把 BANK_ADDR、SAFE_ADDR 填进 .env，再执行：
forge script script/TransferOwner.s.sol --rpc-url $RPC_URL --broadcast

# （可选）EOA 先给 BigBank 存一笔 >0.001 ETH
forge script script/Deposit.s.sol --rpc-url $RPC_URL --broadcast
```

多签内发起的 ERC20 转账、`withdraw()` 提案都在 Safe 网页完成，步骤见《Safe 2-of-3 多签实操指南.md》。

## 常见问题

- **`failed to solve: ... openzeppelin`**：依赖没装，回到第 2 步 `forge install`。
- **`nonce too low` / `nonce too high`**：同一私钥有未确认交易或本地 nonce 滞后，等上一笔上链后重试，或换 RPC。
- **RPC 429 / 限流**：换一个公共 RPC（publicnode / Alchemy / Infura 轮换）。
- **私钥不要加引号、不要带 `0x` 以外空格**；`vm.envUint` 接受带 `0x` 的十六进制。
