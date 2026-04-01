"use client";

import { useReadContract, useReadContracts, useAccount } from "wagmi";
import {
  VAULT_ABI,
  VAULT_ADDRESS,
  STREAM_NFT_ABI,
  STREAM_NFT_ADDRESS,
} from "@/lib/contracts";

export interface StreamData {
  streamId: bigint;
  sender: `0x${string}`;
  recipient: `0x${string}`;
  asset: `0x${string}`;
  ratePerSecond: bigint;
  startTime: bigint;
  stopTime: bigint;
  lastClaimTime: bigint;
  totalDeposited: bigint;
  totalClaimed: bigint;
  status: number;
  yieldEnabled: boolean;
}

export function useStreamCount() {
  const { address } = useAccount();
  return useReadContract({
    address: STREAM_NFT_ADDRESS as `0x${string}`,
    abi: STREAM_NFT_ABI,
    functionName: "balanceOf",
    args: address ? [address] : undefined,
    query: { enabled: !!address },
  });
}

export function useStreamIds(count: number) {
  const { address } = useAccount();

  const contracts = Array.from({ length: count }, (_, i) => ({
    address: STREAM_NFT_ADDRESS as `0x${string}`,
    abi: STREAM_NFT_ABI,
    functionName: "tokenOfOwnerByIndex" as const,
    args: [address!, BigInt(i)] as const,
  }));

  return useReadContracts({
    contracts: address ? contracts : [],
    query: { enabled: !!address && count > 0 },
  });
}

export function useStreamData(streamId: bigint | undefined) {
  return useReadContract({
    address: VAULT_ADDRESS as `0x${string}`,
    abi: VAULT_ABI,
    functionName: "getStream",
    args: streamId !== undefined ? [streamId] : undefined,
    query: { enabled: streamId !== undefined },
  });
}

export function useClaimableBalance(streamId: bigint | undefined) {
  return useReadContract({
    address: VAULT_ADDRESS as `0x${string}`,
    abi: VAULT_ABI,
    functionName: "claimableBalance",
    args: streamId !== undefined ? [streamId] : undefined,
    query: {
      enabled: streamId !== undefined,
      refetchInterval: 5000, // Refresh every 5 seconds
    },
  });
}
