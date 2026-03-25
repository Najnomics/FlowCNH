# FlowCNH

> Real-time cross-border payment streaming powered by AxCNH — money that moves as fast as work happens.

---

## Overview

FlowCNH is a programmable payment streaming protocol built on Conflux eSpace, using AxCNH (the offshore yuan-pegged stablecoin by AnchorX) as the primary settlement asset. Employers fund a smart contract once; funds drip to worker wallets second-by-second in real time — no batch payroll runs, no wire delays, no intermediary banks. Idle unstreamed balances are automatically deployed into dForce Unitus lending markets to earn yield while waiting. Workers withdraw any time, gasslessly, via Conflux's native Fee Sponsorship mechanism.

FlowCNH is the first real-time payment streaming protocol on Conflux eSpace and the most direct on-chain realization of Conflux's PayFi vision — programmable money, real-time finance, and streaming payments, all on a single protocol.

---

## Hackathon

**Global Hackfest 2026** | 2026-03-23 – 2026-04-20

**Prize Targets:** Main Award ($1,500) + Best AxCNH Integration ($500)

---

## Team

- **Nosakhare Jesuorobo** — Lead Smart Contract Developer (GitHub: [@najnomics](https://github.com/najnomics), Discord: najnomics)
- Team Member 2 (GitHub: @username, Discord: username)
- Team Member 3 (GitHub: @username, Discord: username)
- Team Member 4 (GitHub: @username, Discord: username)
- Team Member 5 (GitHub: @username, Discord: username)

---

## Problem Statement

Cross-border payroll is broken for the workers who need it most. Today's system has three compounding failures:

**1. Time lag.** Traditional payroll runs in batches — weekly, biweekly, monthly. A worker who completes a task on Day 1 may not receive payment until Day 30. In emerging markets, this gap forces workers to take on debt to cover expenses while waiting for money they've already earned.

**2. Rail cost.** International wire transfers via SWIFT cost $25–$50 per transaction and take 2–5 business days. For a remote contractor earning $500/month, a single wire fee can consume 5–10% of their income. Stablecoin alternatives exist but require technical knowledge to onboard and use.

**3. Idle capital.** From the employer side, funds sitting in payroll accounts earn nothing. From the worker side, funds received in a lump sum are immediately exposed to spending pressure. Neither party benefits from the time value of money.

For the Asia corridor specifically — where Conflux's AxCNH stablecoin is positioned as the settlement layer for Belt and Road trade finance — there is no native payment streaming primitive. Payments are still manual, batch, and expensive.

---

## Solution

FlowCNH introduces three composable primitives that together eliminate all three failures:

**1. The Stream.** An employer calls `createStream(recipient, ratePerSecond, asset)` on the `FlowCNHRouter` contract. From that moment, the recipient's claimable balance increases every second — proportional to elapsed time multiplied by the configured rate. No batch runs. No delays. The work-payment relationship becomes real-time.

**2. The Yield Layer.** Any AxCNH held in an active stream contract that has not yet been claimed sits in a `StreamVault` that automatically supplies it to dForce Unitus lending markets. The yield accrues proportionally: 80% to the stream recipient (bonus on top of their payment rate), 20% to the FlowCNH protocol treasury. Money that would otherwise sit idle is always working.

**3. The Gasless Exit.** Workers withdraw by calling `claim()` — or clicking a button in the FlowCNH UI. All `claim()` calls are sponsored via Conflux's Fee Sponsorship mechanism using the `SponsorWhitelistControl` built-in contract. Workers never need to acquire CFX to receive their money. For workers in markets where acquiring native gas tokens is a significant friction, this is the difference between a usable product and an unusable one.

Cross-chain entry is handled via Meson.fi and KinetFlow: an employer on Ethereum or Arbitrum can deposit USDT, which is automatically bridged and swapped to AxCNH on Conflux eSpace before the stream opens. From the employer's perspective, it's a single transaction in USDT. From the worker's perspective, they receive AxCNH.

---

## Go-to-Market Plan

### Target Users

**Primary — Remote-first companies paying Asian contractors:**
Companies in Southeast Asia, Hong Kong, and Singapore that pay remote contractors in mainland China or other Belt and Road corridor countries. AxCNH (offshore CNH-pegged) is the natural settlement asset for this corridor. Estimated market: 50,000+ cross-border employment relationships in the target corridor as of 2026.

**Secondary — DeFi protocols and DAOs on Conflux paying contributors:**
Any on-chain organization that pays contributors — grant recipients, protocol developers, liquidity managers — benefits from streaming over lump-sum payouts. Streaming aligns incentives: contributors receive payment continuously proportional to ongoing contribution.

**Tertiary — Supply chain finance (B2B):**
Suppliers waiting 30–90 days for invoice payment can use FlowCNH to convert approved invoices into streaming payment obligations, unlocking liquidity immediately.

### Distribution

**Phase 1 — Hackathon (now → April 20):**
Deploy on Conflux eSpace testnet. Live demo with real AxCNH testnet tokens. Submit to Global Hackfest 2026 targeting Main Award + Best AxCNH Integration.

**Phase 2 — Mainnet Launch (Month 1–2):**
- Deploy on Conflux eSpace mainnet with AxCNH and USDT0 support
- Apply for Conflux Ecosystem Grants (fast-tracked for hackathon winners)
- Direct outreach to dForce team for joint announcement (FlowCNH deposits generate dForce TVL — aligned incentive)
- Apply for AnchorX AxCNH ecosystem fund grant (FlowCNH is the primary AxCNH use case beyond trading)

**Phase 3 — Scale (Month 3–6):**
- Add Meson.fi integration for one-click USDT → stream entry from any chain
- Build employer dashboard with multi-recipient batch stream creation
- Introduce protocol fee switch (20% of yield earned on idle stream balances)
- Target 50 active streams and $200K in total value streamed within 90 days of mainnet

### Growth Mechanics

- **Zero gas for workers** removes the single biggest adoption barrier in emerging markets
- **Yield on idle balances** gives employers a reason to fund streams early rather than at the last moment — the protocol pays them to do so
- **AxCNH-native** means every FlowCNH stream is a new AxCNH demand event — AnchorX has strong incentive to co-market

### Key Metrics

| Metric | 30-Day Target | 90-Day Target |
|--------|--------------|---------------|
| Active streams | 10 | 50 |
| Total value streamed (USD equiv.) | $20K | $200K |
| Unique recipients | 25 | 150 |
| dForce yield earned by streams | $500 | $5,000 |
| Gas sponsored (USD equiv.) | $200 | $1,500 |

---

## Conflux Integration

FlowCNH is designed to maximize Conflux-native features and showcase the full depth of the eSpace ecosystem:

- [ ] Core Space
- [x] **eSpace** — All contracts deployed on Conflux eSpace. EVM compatibility allows standard Solidity patterns; low gas and high TPS make per-second stream accounting economically viable (impossible on Ethereum mainnet at current gas prices).
- [ ] Cross-Space Bridge
- [x] **Gas Sponsorship** — The `SponsorWhitelistControl` built-in contract sponsors all `claim()` calls by stream recipients. Workers receive funds without ever needing CFX. The sponsor balance is replenished automatically from protocol yield revenue.
- [x] **Built-in Contracts** — Uses `SponsorWhitelistControl` at `0x0888000000000000000000000000000000000001` for Fee Sponsorship management. Whitelist is managed programmatically by `FlowCNHSponsorManager.sol`.
- [x] **Partner Integrations:**
  - **AxCNH (AnchorX)** — Primary stream asset. FlowCNH is the first streaming protocol for AxCNH, creating a new utility layer on top of Conflux's flagship stablecoin.
  - **dForce Unitus** — Idle stream balances are supplied to Unitus lending markets. FlowCNH streams are productive capital, not dead weight.
  - **Meson.fi** — Cross-chain entry point. Employers on Ethereum, Arbitrum, or Base deposit USDT; Meson bridges to Conflux eSpace and swaps to AxCNH before the stream opens.
  - **KinetFlow** — Secondary cross-chain bridge option, optimized for Core Space ↔ eSpace liquidity movement and Asia-aligned stablecoin corridors.

---

## Features

- **Second-by-second payment streaming** — Recipient balance increases every block; withdrawable at any time with no lock-up or minimum claim amount
- **AxCNH-native settlement** — Streams denominated in AxCNH (offshore CNH-pegged), purpose-built for the Asia cross-border payment corridor
- **Idle yield via dForce** — Unstreamed balances auto-supply to dForce Unitus lending markets; 80% of yield flows to recipients, 20% to protocol
- **Gasless withdrawals** — All `claim()` transactions sponsored via Conflux's Fee Sponsorship mechanism; workers never need CFX
- **Cross-chain employer entry** — Employers deposit USDT from any chain; Meson.fi bridges and swaps to AxCNH automatically before stream opens
- **Multi-recipient streams** — Employers create batch streams to multiple workers in a single transaction via `FlowCNHRouter`
- **Pausable and cancellable streams** — Employers can pause (worker stops accruing) or cancel (remainder returned to employer) with on-chain dispute window
- **USDT0 support** — Streams can also be denominated in USDT0 (LayerZero omnichain USDT) for non-CNH corridors
- **Stream NFTs** — Each active stream is minted as an ERC-721 NFT, making stream positions transferable and composable with other DeFi protocols

---

## Technology Stack

- **Frontend:** React 18, Next.js 14, Wagmi v2, Viem, TailwindCSS, Recharts (stream rate and yield charts)
- **Backend:** Node.js 20, TypeScript — yield harvester service that periodically calls `harvestYield()` on active stream vaults
- **Blockchain:** Conflux eSpace (Chain ID: 1030 mainnet / 71 testnet)
- **Smart Contracts:** Solidity ^0.8.24, Foundry (forge, cast, anvil)
- **Protocol Integrations:** dForce Unitus lending interface, AxCNH ERC-20, Meson.fi SDK, KinetFlow router
- **Conflux-Specific:** `SponsorWhitelistControl` built-in contract, Conflux eSpace RPC (`evm.confluxrpc.com`)
- **Testing:** Forge test suite with Conflux eSpace mainnet fork, Foundry invariant tests for stream accounting correctness
- **DevOps:** GitHub Actions CI, Tenderly contract monitoring and alerting on Conflux eSpace

---

## Setup Instructions

### Prerequisites

- Node.js v20+
- Foundry (`curl -L https://foundry.paradigm.xyz | bash && foundryup`)
- Git
- Conflux wallet — Fluent Wallet or MetaMask with Conflux eSpace network configured
- Testnet CFX from the [Conflux faucet](https://faucet.confluxnetwork.org/)
- Testnet AxCNH from the AnchorX testnet faucet

### Installation

1. Clone the repository

   ```bash
   git clone https://github.com/najnomics/flow-cnh
   cd flow-cnh
   ```

2. Install Foundry dependencies

   ```bash
   forge install
   ```

3. Install frontend and harvester dependencies

   ```bash
   npm install
   ```

4. Configure environment

   ```bash
   cp .env.example .env
   ```

   Edit `.env` with your configuration:

   ```env
   # Conflux eSpace
   CONFLUX_ESPACE_RPC=https://evm.confluxrpc.com
   CONFLUX_ESPACE_TESTNET_RPC=https://evmtestnet.confluxrpc.com
   CHAIN_ID=1030

   # Deployer
   PRIVATE_KEY=your_private_key_here

   # Protocol addresses (eSpace mainnet)
   AXCNH_ADDRESS=0x...
   USDT0_ADDRESS=0x...
   DFORCE_UNITUS_COMPTROLLER=0x...
   MESON_ROUTER=0x...
   KINETFLOW_ROUTER=0x...

   # Conflux built-in
   SPONSOR_WHITELIST_CONTROL=0x0888000000000000000000000000000000000001

   # Sponsor funding
   SPONSOR_FUND_AMOUNT_CFX=500

   # Yield harvester
   HARVEST_INTERVAL_SECONDS=3600
   PROTOCOL_FEE_BPS=2000

   # Stream settings
   DISPUTE_WINDOW_SECONDS=86400
   ```

5. Compile contracts

   ```bash
   forge build
   ```

6. Run the application

   ```bash
   # Start frontend
   npm run dev

   # Start yield harvester (in separate terminal)
   npm run harvester
   ```

### Testing

```bash
# Run full test suite
forge test -vvv

# Run with Conflux eSpace mainnet fork
forge test --fork-url https://evm.confluxrpc.com -vvv

# Run stream accounting invariant tests
forge test --match-path test/invariants/ -vvv

# Run specific test file
forge test --match-path test/FlowCNHStream.t.sol -vvv

# Generate coverage
forge coverage --report lcov
```

---

## Usage

### For Employers

1. **Connect Wallet** — Open FlowCNH and connect your wallet on Conflux eSpace (or any supported chain via Meson bridge).

2. **Fund a Stream** — Enter the recipient wallet address, payment rate (e.g. `0.01 AxCNH per second` = ~$25/day), and total duration. Click "Create Stream". If funding from another chain, select your source asset (USDT on Ethereum, etc.) — Meson handles the bridge and swap automatically.

3. **Monitor** — The employer dashboard shows all active streams, total streamed to date, yield earned on idle balances, and remaining stream duration.

4. **Manage** — Pause a stream if a contractor goes on leave. Cancel a stream to recover unstreamed funds (subject to the 24-hour dispute window). Extend a stream by topping up the contract balance.

### For Recipients (Workers)

1. **Connect Wallet** — Open FlowCNH and connect your wallet. No CFX required.

2. **View Claimable Balance** — The dashboard shows your real-time accruing balance and any bonus yield earned on the employer's idle deposit.

3. **Claim** — Click "Withdraw". Funds arrive in your wallet instantly. The transaction gas is fully sponsored — you pay nothing.

4. **Claim anytime** — Withdraw daily, weekly, or whenever you want. There's no minimum claim amount and no schedule requirement.

### Developer — Creating a Stream Programmatically

```typescript
import { FlowCNHClient } from '@flow-cnh/sdk';
import { parseUnits } from 'viem';

const client = new FlowCNHClient({
  rpcUrl: 'https://evm.confluxrpc.com',
  privateKey: process.env.EMPLOYER_PRIVATE_KEY,
});

// Create a stream: 0.01 AxCNH per second for 30 days
const stream = await client.createStream({
  recipient: '0xWorkerAddress',
  asset: 'AxCNH',
  ratePerSecond: parseUnits('0.01', 18),
  duration: 30 * 24 * 60 * 60, // 30 days in seconds
  enableYield: true, // auto-supply idle to dForce
});

console.log(`Stream created: ${stream.id}`);
console.log(`NFT token ID: ${stream.tokenId}`);
```

---

## Demo

- **Live Demo:** https://flow-cnh.vercel.app *(testnet deployment)*
- **Demo Video:** [YouTube — FlowCNH walkthrough](https://youtube.com/watch?v=TBD)
- **Screenshots:** See `/demo/screenshots/` folder

---

## Architecture

```
┌────────────────────────────────────────────────────────────────────┐
│                  Employer Entry Points                              │
│                                                                     │
│  ┌─────────────────────┐      ┌────────────────────────────────┐   │
│  │  Direct AxCNH       │      │  Cross-Chain (any chain)       │   │
│  │  (Conflux eSpace)   │      │  USDT → Meson.fi / KinetFlow   │   │
│  │                     │      │  → AxCNH on eSpace             │   │
│  └──────────┬──────────┘      └─────────────┬──────────────────┘   │
└─────────────┼────────────────────────────────┼────────────────────┘
              │  createStream()                 │  createStreamFromBridge()
              └────────────────┬────────────────┘
                               ▼
┌────────────────────────────────────────────────────────────────────┐
│                    FlowCNHRouter.sol                                │
│   Validates inputs · Deploys StreamVault · Mints stream NFT        │
│   Routes cross-chain entry · Manages multi-recipient batches       │
└──────────────────────────────┬─────────────────────────────────────┘
                               │
              ┌────────────────┼────────────────┐
              ▼                ▼                 ▼
   ┌──────────────────┐  ┌──────────────┐  ┌──────────────────────┐
   │  StreamVault.sol │  │  StreamNFT   │  │  FlowCNHSponsor      │
   │                  │  │  .sol        │  │  Manager.sol         │
   │  Holds AxCNH     │  │  ERC-721     │  │                      │
   │  Tracks accrual  │  │  per stream  │  │  SponsorWhitelist    │
   │  Supplies idle   │  │  Transferable│  │  Control built-in    │
   │  → dForce Unitus │  │  positions   │  │  Sponsors claim()    │
   └──────┬───────────┘  └──────────────┘  └──────────────────────┘
          │ idle AxCNH
          ▼
   ┌──────────────────────────────┐
   │  dForce Unitus (eSpace)      │
   │  Lending market              │
   │  Yield → 80% recipient       │
   │          20% protocol fee    │
   └──────────────────────────────┘

   Recipient calls claim() → gasless (Fee Sponsorship) → AxCNH arrives
```

**Key Design Decisions:**

- **Stream accounting is balance-based, not event-based.** Rather than emitting a payment event every second (which would be gas-prohibitive), `claimableBalance()` is computed on-demand as `rate × elapsedSeconds`. Only `claim()` writes to state — once per withdrawal, not once per second.
- **Stream NFTs** make positions composable. A future lending protocol can accept a stream NFT as collateral and advance the worker their upcoming earnings. This is unlockable without any changes to FlowCNH.
- **Dispute window** on cancellation (24 hours) prevents employers from cancelling mid-delivery of work. Workers have a 24-hour window to claim any accrued balance before a cancellation takes effect.

---

## Smart Contracts

### Testnet (Conflux eSpace Testnet — Chain ID: 71)

| Contract | Address |
|----------|---------|
| `FlowCNHRouter` | [`0x2Cd74565C93BC180e29bE542047b06605e974ca0`](https://evmtestnet.confluxscan.io/address/0x2Cd74565C93BC180e29bE542047b06605e974ca0) |
| `StreamVault` | [`0x09a1Bfac7fED8754f1EB37C802eEc9ED831A82F9`](https://evmtestnet.confluxscan.io/address/0x09a1Bfac7fED8754f1EB37C802eEc9ED831A82F9) |
| `StreamNFT` | [`0x349CcB9d138bE918B1AcE5849EFdd5c4652c9CbB`](https://evmtestnet.confluxscan.io/address/0x349CcB9d138bE918B1AcE5849EFdd5c4652c9CbB) |
| `FlowCNHSponsorManager` | [`0xA8640Dd210A6b506F2C0560A1268a2424695af61`](https://evmtestnet.confluxscan.io/address/0xA8640Dd210A6b506F2C0560A1268a2424695af61) |
| `DForceAdapter` | [`0xfD8a5df577184ad156DcF5Ec7a27B7194cC8d116`](https://evmtestnet.confluxscan.io/address/0xfD8a5df577184ad156DcF5Ec7a27B7194cC8d116) |

### Mainnet (Conflux eSpace — Chain ID: 1030)

| Contract | Address |
|----------|---------|
| `FlowCNHRouter` | Post-hackathon deployment |
| `StreamNFT` | Post-hackathon deployment |

*All contracts verified on [ConfluxScan eSpace](https://evm.confluxscan.io)*

---

## Future Improvements

- **Stream NFT collateralization** — Enable lending protocols (dForce) to accept stream NFTs as collateral, letting workers borrow against future earnings before they accrue
- **Conditional streams** — Oracle-triggered stream conditions (e.g. "stream pauses if on-chain attestation of work delivery is not submitted within 7 days") using Pyth Network data feeds
- **Recurring invoice streams** — Automated monthly stream renewal for ongoing contractor relationships, triggered on-chain with employer-signed intent
- **Mobile app** — React Native app with Fluent Wallet deep-link for one-tap claim on mobile; targeting gig-economy workers in Southeast Asia
- **AxCNH ↔ CNH off-ramp integration** — Partnership with AnchorX and GinsengSwap to enable workers to redeem AxCNH directly to CNH bank accounts from the FlowCNH UI
- **Multi-asset streams** — Support CFX, sFX (SHUI Finance), and additional Conflux eSpace stablecoins as stream assets beyond AxCNH and USDT0
- **Known Limitations:** The current yield harvester is a centralized off-chain service — decentralization via a keeper network with bonded operators is planned post-hackathon. Stream rate is fixed at creation; dynamic rate adjustment requires a stream cancel + recreate in the current version.

---

## License

This project is licensed under the MIT License — see the [LICENSE](./LICENSE) file for details.

---

## Acknowledgments

- **Conflux Network** — For the Fee Sponsorship mechanism that makes gasless worker withdrawals possible, and the high-throughput eSpace infrastructure that makes per-second accounting economically viable
- **AnchorX** — For the AxCNH stablecoin — the settlement asset that makes Conflux the right chain for Asia cross-border payment streaming
- **dForce** — For the Unitus lending market integration that turns idle stream balances into productive yield-earning capital
- **Meson.fi** — For cross-chain bridging that enables employers on any chain to fund AxCNH streams with a single transaction
- **KinetFlow** — For Core Space ↔ eSpace liquidity infrastructure and Asia-aligned stablecoin routing
- **Sablier / Superfluid** — Conceptual inspiration for payment streaming primitives (FlowCNH is an independent implementation built natively for Conflux and AxCNH)
- **OpenZeppelin** — ERC-20, ERC-721, and security pattern libraries
- **Foundry** — Solidity testing and deployment toolchain
- **Tenderly** — Contract monitoring and alerting on Conflux eSpace
