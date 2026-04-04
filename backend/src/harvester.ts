import { createPublicClient, createWalletClient, http, parseAbi } from "viem";
import { privateKeyToAccount } from "viem/accounts";
import { config } from "dotenv";

config({ path: "../.env" });

// ─── Config ──────────────────────────────────────────────────────────
const RPC_URL = process.env.CONFLUX_ESPACE_TESTNET_RPC ?? "https://evmtestnet.confluxrpc.com";
const PRIVATE_KEY = process.env.PRIVATE_KEY as `0x${string}`;
const VAULT_ADDRESS = process.env.NEXT_PUBLIC_VAULT_ADDRESS as `0x${string}`;
const AXCNH_ADDRESS = process.env.AXCNH_ADDRESS as `0x${string}`;
const USDT0_ADDRESS = process.env.USDT0_ADDRESS as `0x${string}`;
const HARVEST_INTERVAL = Number(process.env.HARVEST_INTERVAL_SECONDS ?? 3600) * 1000;

// ─── ABI ─────────────────────────────────────────────────────────────
const VAULT_ABI = parseAbi([
  "function harvestYield(address asset) external",
  "function totalIdleInYield(address asset) external view returns (uint256)",
  "event YieldHarvested(uint256 indexed streamId, uint256 yieldAmount, uint256 recipientShare, uint256 protocolShare)",
]);

// ─── Clients ─────────────────────────────────────────────────────────
const chain = {
  id: Number(process.env.CHAIN_ID ?? 71),
  name: "Conflux eSpace Testnet",
  nativeCurrency: { name: "CFX", symbol: "CFX", decimals: 18 },
  rpcUrls: { default: { http: [RPC_URL] } },
} as const;

const publicClient = createPublicClient({
  chain,
  transport: http(RPC_URL),
});

const account = privateKeyToAccount(PRIVATE_KEY);
const walletClient = createWalletClient({
  account,
  chain,
  transport: http(RPC_URL),
});

// ─── Harvest Loop ────────────────────────────────────────────────────
async function harvestAsset(asset: `0x${string}`, name: string) {
  try {
    // Check if there's idle balance in yield
    const idle = await publicClient.readContract({
      address: VAULT_ADDRESS,
      abi: VAULT_ABI,
      functionName: "totalIdleInYield",
      args: [asset],
    });

    if (idle === 0n) {
      console.log(`[${name}] No idle balance in yield, skipping`);
      return;
    }

    console.log(`[${name}] Idle in yield: ${idle.toString()}`);

    // Call harvestYield
    const hash = await walletClient.writeContract({
      address: VAULT_ADDRESS,
      abi: VAULT_ABI,
      functionName: "harvestYield",
      args: [asset],
    });

    console.log(`[${name}] Harvest tx sent: ${hash}`);

    const receipt = await publicClient.waitForTransactionReceipt({ hash });
    console.log(
      `[${name}] Harvest confirmed in block ${receipt.blockNumber}, status: ${receipt.status}`
    );
  } catch (err) {
    console.error(`[${name}] Harvest failed:`, err);
  }
}

async function runHarvestCycle() {
  const timestamp = new Date().toISOString();
  console.log(`\n--- Harvest cycle at ${timestamp} ---`);

  const assets: [string, `0x${string}`][] = [];

  if (AXCNH_ADDRESS && AXCNH_ADDRESS !== "0x0000000000000000000000000000000000000000") {
    assets.push(["AxCNH", AXCNH_ADDRESS]);
  }
  if (USDT0_ADDRESS && USDT0_ADDRESS !== "0x0000000000000000000000000000000000000000") {
    assets.push(["USDT0", USDT0_ADDRESS]);
  }

  if (assets.length === 0) {
    console.log("No assets configured for harvesting");
    return;
  }

  for (const [name, address] of assets) {
    await harvestAsset(address, name);
  }
}

// ─── Main ────────────────────────────────────────────────────────────
async function main() {
  console.log("FlowCNH Yield Harvester");
  console.log("=======================");
  console.log(`RPC: ${RPC_URL}`);
  console.log(`Vault: ${VAULT_ADDRESS}`);
  console.log(`Harvester: ${account.address}`);
  console.log(`Interval: ${HARVEST_INTERVAL / 1000}s`);
  console.log();

  // Run immediately
  await runHarvestCycle();

  // Then run on interval
  setInterval(runHarvestCycle, HARVEST_INTERVAL);
}

main().catch((err) => {
  console.error("Fatal error:", err);
  process.exit(1);
});
