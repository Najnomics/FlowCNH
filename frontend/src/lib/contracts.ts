export const ROUTER_ADDRESS =
  (process.env.NEXT_PUBLIC_ROUTER_ADDRESS as `0x${string}`) ??
  "0x0000000000000000000000000000000000000000";

export const STREAM_NFT_ADDRESS =
  (process.env.NEXT_PUBLIC_STREAM_NFT_ADDRESS as `0x${string}`) ??
  "0x0000000000000000000000000000000000000000";

export const VAULT_ADDRESS =
  (process.env.NEXT_PUBLIC_VAULT_ADDRESS as `0x${string}`) ??
  "0x0000000000000000000000000000000000000000";

// ABI fragments for the contracts we interact with from the frontend
export const ROUTER_ABI = [
  {
    type: "function",
    name: "createStream",
    inputs: [
      { name: "recipient", type: "address" },
      { name: "asset", type: "address" },
      { name: "ratePerSecond", type: "uint256" },
      { name: "duration", type: "uint256" },
      { name: "enableYield", type: "bool" },
    ],
    outputs: [
      { name: "streamId", type: "uint256" },
      { name: "tokenId", type: "uint256" },
    ],
    stateMutability: "nonpayable",
  },
  {
    type: "function",
    name: "createBatchStreams",
    inputs: [
      { name: "recipients", type: "address[]" },
      { name: "asset", type: "address" },
      { name: "ratesPerSecond", type: "uint256[]" },
      { name: "durations", type: "uint256[]" },
      { name: "enableYield", type: "bool" },
    ],
    outputs: [{ name: "streamIds", type: "uint256[]" }],
    stateMutability: "nonpayable",
  },
  {
    type: "function",
    name: "claimableBalance",
    inputs: [{ name: "streamId", type: "uint256" }],
    outputs: [{ name: "", type: "uint256" }],
    stateMutability: "view",
  },
  {
    type: "function",
    name: "getStream",
    inputs: [{ name: "streamId", type: "uint256" }],
    outputs: [
      {
        name: "",
        type: "tuple",
        components: [
          { name: "sender", type: "address" },
          { name: "recipient", type: "address" },
          { name: "asset", type: "address" },
          { name: "ratePerSecond", type: "uint256" },
          { name: "startTime", type: "uint256" },
          { name: "stopTime", type: "uint256" },
          { name: "lastClaimTime", type: "uint256" },
          { name: "totalDeposited", type: "uint256" },
          { name: "totalClaimed", type: "uint256" },
          { name: "status", type: "uint8" },
          { name: "yieldEnabled", type: "bool" },
        ],
      },
    ],
    stateMutability: "view",
  },
  {
    type: "function",
    name: "pauseStream",
    inputs: [{ name: "streamId", type: "uint256" }],
    outputs: [],
    stateMutability: "nonpayable",
  },
  {
    type: "function",
    name: "resumeStream",
    inputs: [{ name: "streamId", type: "uint256" }],
    outputs: [],
    stateMutability: "nonpayable",
  },
  {
    type: "function",
    name: "cancelStream",
    inputs: [{ name: "streamId", type: "uint256" }],
    outputs: [],
    stateMutability: "nonpayable",
  },
  {
    type: "event",
    name: "StreamOpened",
    inputs: [
      { name: "streamId", type: "uint256", indexed: true },
      { name: "tokenId", type: "uint256", indexed: true },
      { name: "sender", type: "address", indexed: true },
      { name: "recipient", type: "address", indexed: false },
      { name: "asset", type: "address", indexed: false },
      { name: "ratePerSecond", type: "uint256", indexed: false },
      { name: "duration", type: "uint256", indexed: false },
    ],
    anonymous: false,
  },
] as const;

export const VAULT_ABI = [
  {
    type: "function",
    name: "claim",
    inputs: [{ name: "streamId", type: "uint256" }],
    outputs: [],
    stateMutability: "nonpayable",
  },
  {
    type: "function",
    name: "claimableBalance",
    inputs: [{ name: "streamId", type: "uint256" }],
    outputs: [{ name: "", type: "uint256" }],
    stateMutability: "view",
  },
  {
    type: "function",
    name: "getStream",
    inputs: [{ name: "streamId", type: "uint256" }],
    outputs: [
      {
        name: "",
        type: "tuple",
        components: [
          { name: "sender", type: "address" },
          { name: "recipient", type: "address" },
          { name: "asset", type: "address" },
          { name: "ratePerSecond", type: "uint256" },
          { name: "startTime", type: "uint256" },
          { name: "stopTime", type: "uint256" },
          { name: "lastClaimTime", type: "uint256" },
          { name: "totalDeposited", type: "uint256" },
          { name: "totalClaimed", type: "uint256" },
          { name: "status", type: "uint8" },
          { name: "yieldEnabled", type: "bool" },
        ],
      },
    ],
    stateMutability: "view",
  },
  {
    type: "function",
    name: "nextStreamId",
    inputs: [],
    outputs: [{ name: "", type: "uint256" }],
    stateMutability: "view",
  },
] as const;

export const ERC20_ABI = [
  {
    type: "function",
    name: "approve",
    inputs: [
      { name: "spender", type: "address" },
      { name: "amount", type: "uint256" },
    ],
    outputs: [{ name: "", type: "bool" }],
    stateMutability: "nonpayable",
  },
  {
    type: "function",
    name: "balanceOf",
    inputs: [{ name: "account", type: "address" }],
    outputs: [{ name: "", type: "uint256" }],
    stateMutability: "view",
  },
  {
    type: "function",
    name: "allowance",
    inputs: [
      { name: "owner", type: "address" },
      { name: "spender", type: "address" },
    ],
    outputs: [{ name: "", type: "uint256" }],
    stateMutability: "view",
  },
  {
    type: "function",
    name: "symbol",
    inputs: [],
    outputs: [{ name: "", type: "string" }],
    stateMutability: "view",
  },
  {
    type: "function",
    name: "decimals",
    inputs: [],
    outputs: [{ name: "", type: "uint8" }],
    stateMutability: "view",
  },
] as const;

export const STREAM_NFT_ABI = [
  {
    type: "function",
    name: "balanceOf",
    inputs: [{ name: "owner", type: "address" }],
    outputs: [{ name: "", type: "uint256" }],
    stateMutability: "view",
  },
  {
    type: "function",
    name: "tokenOfOwnerByIndex",
    inputs: [
      { name: "owner", type: "address" },
      { name: "index", type: "uint256" },
    ],
    outputs: [{ name: "", type: "uint256" }],
    stateMutability: "view",
  },
  {
    type: "function",
    name: "tokenIdToStreamId",
    inputs: [{ name: "tokenId", type: "uint256" }],
    outputs: [{ name: "", type: "uint256" }],
    stateMutability: "view",
  },
] as const;
