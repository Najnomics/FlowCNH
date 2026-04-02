"use client";

import { useMemo } from "react";
import { useAccount, useReadContracts, useReadContract } from "wagmi";
import { StreamCard } from "@/components/StreamCard";
import { VAULT_ABI, VAULT_ADDRESS } from "@/lib/contracts";
import { ConnectButton } from "@rainbow-me/rainbowkit";

export default function Dashboard() {
  const { address, isConnected } = useAccount();

  // 1. Read nextStreamId to know how many streams exist
  const { data: nextStreamId } = useReadContract({
    address: VAULT_ADDRESS as `0x${string}`,
    abi: VAULT_ABI,
    functionName: "nextStreamId",
    query: { enabled: isConnected },
  });

  const totalStreams = nextStreamId ? Number(nextStreamId) - 1 : 0; // IDs start at 1

  // 2. Fetch all stream data (for small testnet usage this is fine)
  const streamContracts = useMemo(
    () =>
      Array.from({ length: totalStreams }, (_, i) => ({
        address: VAULT_ADDRESS as `0x${string}`,
        abi: VAULT_ABI,
        functionName: "getStream" as const,
        args: [BigInt(i + 1)] as const,
      })),
    [totalStreams]
  );

  const { data: allStreamResults } = useReadContracts({
    contracts: streamContracts,
    query: {
      enabled: totalStreams > 0,
      refetchInterval: 5000,
    },
  });

  // 3. Filter to streams where current user is sender OR recipient
  const myStreams = useMemo(() => {
    if (!allStreamResults || !address) return [];

    const result: { streamId: bigint; stream: any; isEmployer: boolean }[] = [];

    for (let i = 0; i < allStreamResults.length; i++) {
      const r = allStreamResults[i];
      if (r.status !== "success") continue;

      const stream = r.result as any;
      const sender = (stream.sender ?? stream[0])?.toLowerCase();
      const recipient = (stream.recipient ?? stream[1])?.toLowerCase();
      const userAddr = address.toLowerCase();

      if (sender === userAddr || recipient === userAddr) {
        result.push({
          streamId: BigInt(i + 1),
          stream,
          isEmployer: sender === userAddr,
        });
      }
    }

    return result;
  }, [allStreamResults, address]);

  if (!isConnected) {
    return (
      <div className="flex flex-col items-center pt-24 text-center">
        <h1 className="mb-4 text-3xl font-bold">Dashboard</h1>
        <p className="mb-8 text-gray-400">
          Connect your wallet to view your streams
        </p>
        <ConnectButton />
      </div>
    );
  }

  const sentStreams = myStreams.filter((s) => s.isEmployer);
  const receivedStreams = myStreams.filter((s) => !s.isEmployer);

  return (
    <div>
      <div className="mb-8">
        <h1 className="text-3xl font-bold">Dashboard</h1>
        <p className="mt-1 text-gray-400">
          {myStreams.length > 0
            ? `${sentStreams.length} sent, ${receivedStreams.length} received`
            : "No streams yet"}
        </p>
      </div>

      {myStreams.length > 0 ? (
        <div className="space-y-10">
          {/* Streams you're sending (employer) */}
          {sentStreams.length > 0 && (
            <section>
              <h2 className="mb-4 text-lg font-semibold text-gray-300">
                Streams You&apos;re Sending
              </h2>
              <div className="grid gap-6 sm:grid-cols-2 lg:grid-cols-3">
                {sentStreams.map(({ streamId, stream }) => (
                  <StreamCard
                    key={streamId.toString()}
                    streamId={streamId}
                    stream={{
                      sender: stream.sender ?? stream[0],
                      recipient: stream.recipient ?? stream[1],
                      asset: stream.asset ?? stream[2],
                      ratePerSecond: stream.ratePerSecond ?? stream[3],
                      startTime: stream.startTime ?? stream[4],
                      stopTime: stream.stopTime ?? stream[5],
                      totalDeposited: stream.totalDeposited ?? stream[7],
                      totalClaimed: stream.totalClaimed ?? stream[8],
                      status: Number(stream.status ?? stream[9]),
                      yieldEnabled: stream.yieldEnabled ?? stream[10],
                    }}
                    isEmployer={true}
                  />
                ))}
              </div>
            </section>
          )}

          {/* Streams you're receiving (worker) */}
          {receivedStreams.length > 0 && (
            <section>
              <h2 className="mb-4 text-lg font-semibold text-gray-300">
                Streams You&apos;re Receiving
              </h2>
              <div className="grid gap-6 sm:grid-cols-2 lg:grid-cols-3">
                {receivedStreams.map(({ streamId, stream }) => (
                  <StreamCard
                    key={streamId.toString()}
                    streamId={streamId}
                    stream={{
                      sender: stream.sender ?? stream[0],
                      recipient: stream.recipient ?? stream[1],
                      asset: stream.asset ?? stream[2],
                      ratePerSecond: stream.ratePerSecond ?? stream[3],
                      startTime: stream.startTime ?? stream[4],
                      stopTime: stream.stopTime ?? stream[5],
                      totalDeposited: stream.totalDeposited ?? stream[7],
                      totalClaimed: stream.totalClaimed ?? stream[8],
                      status: Number(stream.status ?? stream[9]),
                      yieldEnabled: stream.yieldEnabled ?? stream[10],
                    }}
                    isEmployer={false}
                  />
                ))}
              </div>
            </section>
          )}
        </div>
      ) : (
        <div className="card flex flex-col items-center py-16 text-center">
          <div className="mb-4 text-5xl">&#128176;</div>
          <h2 className="mb-2 text-xl font-semibold">No streams yet</h2>
          <p className="mb-6 text-gray-400">
            Create a stream to start paying workers in real-time, or share your
            address with an employer.
          </p>
          <a href="/create" className="btn-primary">
            Create Your First Stream
          </a>
        </div>
      )}
    </div>
  );
}
