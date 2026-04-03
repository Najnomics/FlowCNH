import { NextResponse } from "next/server";
import { createPublicClient, http } from "viem";
import { confluxESpaceTestnet } from "@/lib/chain";
import { VAULT_ABI, VAULT_ADDRESS, STREAM_NFT_ABI, STREAM_NFT_ADDRESS } from "@/lib/contracts";

const client = createPublicClient({
  chain: confluxESpaceTestnet,
  transport: http(),
});

export async function GET(
  _request: Request,
  { params }: { params: { tokenId: string } }
) {
  const tokenId = BigInt(params.tokenId);

  try {
    const streamId = await client.readContract({
      address: STREAM_NFT_ADDRESS as `0x${string}`,
      abi: STREAM_NFT_ABI,
      functionName: "tokenIdToStreamId",
      args: [tokenId],
    });

    const stream = (await client.readContract({
      address: VAULT_ADDRESS as `0x${string}`,
      abi: VAULT_ABI,
      functionName: "getStream",
      args: [streamId],
    })) as any;

    const ratePerDay =
      Number((stream.ratePerSecond ?? stream[3]) * 86400n) / 1e18;
    const status = ["Active", "Paused", "Cancelled", "Completed"][
      Number(stream.status ?? stream[9])
    ];

    return NextResponse.json({
      name: `FlowCNH Stream #${streamId.toString()}`,
      description: `Real-time AxCNH payment stream. Rate: ${ratePerDay.toFixed(2)} AxCNH/day. Status: ${status}.`,
      image: `https://flow-cnh.vercel.app/api/og/${tokenId}`,
      external_url: `https://flow-cnh.vercel.app/dashboard`,
      attributes: [
        { trait_type: "Stream ID", value: streamId.toString() },
        { trait_type: "Status", value: status },
        { trait_type: "Rate (AxCNH/day)", value: ratePerDay.toFixed(4) },
        {
          trait_type: "Yield Enabled",
          value: (stream.yieldEnabled ?? stream[10]) ? "Yes" : "No",
        },
      ],
    });
  } catch {
    return NextResponse.json(
      { error: "Stream not found" },
      { status: 404 }
    );
  }
}
