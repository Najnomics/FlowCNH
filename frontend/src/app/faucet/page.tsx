"use client";

import {
  useAccount,
  useWriteContract,
  useWaitForTransactionReceipt,
  useReadContract,
} from "wagmi";
import { formatUnits, parseUnits } from "viem";
import { ERC20_ABI } from "@/lib/contracts";
import { ConnectButton } from "@rainbow-me/rainbowkit";

const AXCNH_TESTNET = (process.env.NEXT_PUBLIC_AXCNH_ADDRESS ??
  "0x0000000000000000000000000000000000000000") as `0x${string}`;

// MockERC20 has a public mint(address,uint256) function
const MOCK_MINT_ABI = [
  {
    type: "function",
    name: "mint",
    inputs: [
      { name: "to", type: "address" },
      { name: "amount", type: "uint256" },
    ],
    outputs: [],
    stateMutability: "nonpayable",
  },
] as const;

export default function Faucet() {
  const { isConnected, address } = useAccount();

  const { data: balance, refetch } = useReadContract({
    address: AXCNH_TESTNET,
    abi: ERC20_ABI,
    functionName: "balanceOf",
    args: address ? [address] : undefined,
    query: { enabled: !!address },
  });

  const { writeContract: mint, data: mintHash } = useWriteContract();
  const { isLoading: minting, isSuccess: minted } =
    useWaitForTransactionReceipt({ hash: mintHash });

  if (minted) {
    refetch();
  }

  if (!isConnected) {
    return (
      <div className="flex flex-col items-center pt-24 text-center">
        <h1 className="mb-4 text-3xl font-bold">Testnet Faucet</h1>
        <p className="mb-8 text-gray-400">
          Connect your wallet to get test AxCNH tokens
        </p>
        <ConnectButton />
      </div>
    );
  }

  return (
    <div className="mx-auto max-w-lg pt-8">
      <h1 className="mb-2 text-3xl font-bold">Testnet Faucet</h1>
      <p className="mb-8 text-gray-400">
        Mint test AxCNH tokens to try out FlowCNH payment streaming
      </p>

      <div className="card space-y-6">
        {/* Current balance */}
        <div className="rounded-lg bg-gray-800/50 p-4 text-center">
          <p className="text-xs text-gray-500">Your AxCNH Balance</p>
          <p className="mt-1 text-3xl font-bold">
            {balance !== undefined
              ? Number(formatUnits(balance as bigint, 18)).toLocaleString(
                  undefined,
                  { maximumFractionDigits: 2 }
                )
              : "..."}
          </p>
          <p className="text-sm text-gray-400">AxCNH (testnet)</p>
        </div>

        {/* Mint buttons */}
        <div className="space-y-3">
          {[
            { label: "1,000 AxCNH", amount: parseUnits("1000", 18) },
            { label: "10,000 AxCNH", amount: parseUnits("10000", 18) },
            { label: "100,000 AxCNH", amount: parseUnits("100000", 18) },
          ].map(({ label, amount }) => (
            <button
              key={label}
              className="btn-primary w-full py-3"
              disabled={minting}
              onClick={() =>
                mint({
                  address: AXCNH_TESTNET,
                  abi: MOCK_MINT_ABI,
                  functionName: "mint",
                  args: [address!, amount],
                  gas: 200_000n,
                })
              }
            >
              {minting ? "Minting..." : `Mint ${label}`}
            </button>
          ))}
        </div>

        {minted && (
          <div className="rounded-lg bg-accent-green/10 p-4 text-center text-accent-green">
            Tokens minted successfully!
          </div>
        )}

        {/* Info */}
        <div className="space-y-2 text-sm text-gray-500">
          <p>
            These are testnet tokens with no real value. They are used to
            demonstrate FlowCNH payment streaming on Conflux eSpace testnet.
          </p>
          <p>
            Token contract:{" "}
            <a
              href={`https://evmtestnet.confluxscan.io/address/${AXCNH_TESTNET}`}
              target="_blank"
              rel="noopener noreferrer"
              className="text-brand-500 hover:underline"
            >
              {AXCNH_TESTNET.slice(0, 8)}...{AXCNH_TESTNET.slice(-6)}
            </a>
          </p>
        </div>

        {/* Next step */}
        <a href="/create" className="btn-secondary block w-full py-3 text-center">
          Next: Create a Stream &rarr;
        </a>
      </div>
    </div>
  );
}
