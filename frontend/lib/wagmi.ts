import { createConfig, http } from "wagmi";
import { baseSepolia } from "wagmi/chains";
import { injected, coinbaseWallet } from "wagmi/connectors";

export const wagmiConfig = createConfig({
  chains: [baseSepolia],
  ssr: true,
  connectors: [
    injected(),                               // MetaMask, Rabby, any injected wallet
    coinbaseWallet({ appName: "NeuroCart" }), // Coinbase Wallet (native Base support)
  ],
  transports: {
    [baseSepolia.id]: http("https://sepolia.base.org"),
  },
});
