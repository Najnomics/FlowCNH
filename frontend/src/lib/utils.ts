import { formatUnits } from "viem";
import { clsx, type ClassValue } from "clsx";
import { twMerge } from "tailwind-merge";

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs));
}

export function formatAxCNH(amount: bigint, decimals = 18): string {
  const formatted = formatUnits(amount, decimals);
  return Number(formatted).toLocaleString(undefined, {
    minimumFractionDigits: 2,
    maximumFractionDigits: 6,
  });
}

export function formatRate(ratePerSecond: bigint): string {
  const perDay = ratePerSecond * 86400n;
  return `${formatAxCNH(perDay)} /day`;
}

export function formatDuration(seconds: number): string {
  if (seconds < 60) return `${seconds}s`;
  if (seconds < 3600) return `${Math.floor(seconds / 60)}m`;
  if (seconds < 86400) return `${Math.floor(seconds / 3600)}h`;
  return `${Math.floor(seconds / 86400)}d`;
}

export function streamProgress(
  startTime: number,
  stopTime: number,
  now: number
): number {
  if (now >= stopTime) return 100;
  if (now <= startTime) return 0;
  return Math.floor(((now - startTime) / (stopTime - startTime)) * 100);
}

export const STATUS_LABELS: Record<number, string> = {
  0: "Active",
  1: "Paused",
  2: "Cancelled",
  3: "Completed",
};

export const STATUS_COLORS: Record<number, string> = {
  0: "text-accent-green",
  1: "text-accent-yellow",
  2: "text-accent-red",
  3: "text-brand-500",
};
