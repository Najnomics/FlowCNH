import { getDefaultConfig } from "@rainbow-me/rainbowkit";
import { confluxESpaceTestnet, confluxESpace } from "./chain";

// WalletConnect Cloud project ID — get yours at https://cloud.walletconnect.com
const projectId =
  process.env.NEXT_PUBLIC_WALLETCONNECT_ID || "3a8170812b534d0ff9d794f19a901d64";

export const config = getDefaultConfig({
  appName: "FlowCNH",
  projectId,
  chains: [confluxESpaceTestnet, confluxESpace],
  ssr: true,
});
