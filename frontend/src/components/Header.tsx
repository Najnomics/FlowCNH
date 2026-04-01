"use client";

import Link from "next/link";
import { ConnectButton } from "@rainbow-me/rainbowkit";

export function Header() {
  return (
    <header className="border-b border-gray-800 bg-gray-950/80 backdrop-blur-sm">
      <div className="mx-auto flex max-w-7xl items-center justify-between px-4 py-4 sm:px-6 lg:px-8">
        <div className="flex items-center gap-8">
          <Link href="/" className="text-xl font-bold text-white">
            Flow<span className="text-brand-500">CNH</span>
          </Link>
          <nav className="hidden items-center gap-6 sm:flex">
            <Link
              href="/dashboard"
              className="text-sm text-gray-400 transition-colors hover:text-white"
            >
              Dashboard
            </Link>
            <Link
              href="/create"
              className="text-sm text-gray-400 transition-colors hover:text-white"
            >
              Create Stream
            </Link>
            <Link
              href="/faucet"
              className="text-sm text-gray-400 transition-colors hover:text-white"
            >
              Faucet
            </Link>
          </nav>
        </div>
        <ConnectButton
          chainStatus="icon"
          showBalance={false}
          accountStatus="address"
        />
      </div>
    </header>
  );
}
