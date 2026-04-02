"use client";

import Link from "next/link";
import { useAccount } from "wagmi";
import { ConnectButton } from "@rainbow-me/rainbowkit";

export default function Home() {
  const { isConnected } = useAccount();

  return (
    <div className="flex flex-col items-center pt-16 text-center">
      {/* Hero */}
      <div className="mb-4 inline-flex items-center rounded-full border border-brand-500/30 bg-brand-500/10 px-4 py-1.5 text-sm text-brand-500">
        Built on Conflux eSpace
      </div>
      <h1 className="mb-6 text-5xl font-bold leading-tight tracking-tight sm:text-6xl">
        Money that moves
        <br />
        <span className="text-brand-500">as fast as work happens</span>
      </h1>
      <p className="mb-10 max-w-2xl text-lg text-gray-400">
        FlowCNH is a real-time payment streaming protocol powered by AxCNH.
        Employers fund once — workers receive second-by-second. Gasless
        withdrawals. Idle yield via dForce. No banks, no delays.
      </p>

      {/* CTA */}
      <div className="flex gap-4">
        {isConnected ? (
          <>
            <Link href="/create" className="btn-primary text-lg px-8 py-3">
              Create Stream
            </Link>
            <Link href="/dashboard" className="btn-secondary text-lg px-8 py-3">
              Dashboard
            </Link>
          </>
        ) : (
          <ConnectButton />
        )}
      </div>

      {/* Features grid */}
      <div className="mt-24 grid w-full gap-6 sm:grid-cols-3">
        <div className="card text-left">
          <div className="mb-3 text-3xl">&#9889;</div>
          <h3 className="mb-2 text-lg font-semibold">Real-Time Streaming</h3>
          <p className="text-sm text-gray-400">
            Payments accrue every second. Workers withdraw any time — no batch
            runs, no waiting.
          </p>
        </div>
        <div className="card text-left">
          <div className="mb-3 text-3xl">&#127793;</div>
          <h3 className="mb-2 text-lg font-semibold">Idle Yield via dForce</h3>
          <p className="text-sm text-gray-400">
            Unstreamed balances earn yield in dForce Unitus. 80% goes to
            workers, 20% to protocol.
          </p>
        </div>
        <div className="card text-left">
          <div className="mb-3 text-3xl">&#128274;</div>
          <h3 className="mb-2 text-lg font-semibold">Gasless Withdrawals</h3>
          <p className="text-sm text-gray-400">
            Workers never need CFX. All claim transactions are sponsored via
            Conflux Fee Sponsorship.
          </p>
        </div>
      </div>

      {/* How it works */}
      <div className="mt-24 w-full">
        <h2 className="mb-12 text-3xl font-bold">How It Works</h2>
        <div className="grid gap-8 sm:grid-cols-4">
          {[
            { step: "1", title: "Fund", desc: "Employer deposits AxCNH (or USDT from any chain)" },
            { step: "2", title: "Stream", desc: "Payment accrues second-by-second to the worker" },
            { step: "3", title: "Earn", desc: "Idle funds generate yield in dForce Unitus" },
            { step: "4", title: "Claim", desc: "Worker withdraws anytime — gas is sponsored" },
          ].map((item) => (
            <div key={item.step} className="text-center">
              <div className="mx-auto mb-4 flex h-12 w-12 items-center justify-center rounded-full bg-brand-600 text-lg font-bold">
                {item.step}
              </div>
              <h3 className="mb-2 font-semibold">{item.title}</h3>
              <p className="text-sm text-gray-400">{item.desc}</p>
            </div>
          ))}
        </div>
      </div>

      {/* Tech badges */}
      <div className="mt-24 pb-16">
        <p className="mb-6 text-sm text-gray-500">Powered by</p>
        <div className="flex flex-wrap items-center justify-center gap-6 text-sm text-gray-400">
          <span className="rounded-lg border border-gray-800 px-4 py-2">Conflux eSpace</span>
          <span className="rounded-lg border border-gray-800 px-4 py-2">AxCNH</span>
          <span className="rounded-lg border border-gray-800 px-4 py-2">dForce Unitus</span>
          <span className="rounded-lg border border-gray-800 px-4 py-2">Meson.fi</span>
          <span className="rounded-lg border border-gray-800 px-4 py-2">Fee Sponsorship</span>
        </div>
      </div>
    </div>
  );
}
