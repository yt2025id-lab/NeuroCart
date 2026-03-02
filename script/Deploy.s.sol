// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// =============================================================================
// Deploy.s.sol — Deployment Script (Foundry)
//
// Deploy ke BASE SEPOLIA (chain ID 84532):
//
//   forge script script/Deploy.s.sol \
//     --rpc-url https://sepolia.base.org \
//     --broadcast \
//     --verify \
//     --verifier-url https://api-sepolia.basescan.org/api \
//     --etherscan-api-key $BASESCAN_API_KEY \
//     -vvvv
//
// Butuh env vars di .env:
//   PRIVATE_KEY=0x...
//   FUNCTIONS_SUBSCRIPTION_ID=...   (buat di https://functions.chain.link → Base Sepolia)
//   BASESCAN_API_KEY=...            (opsional, untuk --verify)
//
// Setelah deploy, update contracts.py dan frontend/.env.local
// =============================================================================

import {Script, console} from "forge-std/Script.sol";
import {AgentRegistry} from "../src/AgentRegistry.sol";
import {JobEscrow} from "../src/JobEscrow.sol";
import {NeuroCartFunctions} from "../src/NeuroCartFunctions.sol";
import {NeuroCartAutomation} from "../src/NeuroCartAutomation.sol";

contract Deploy is Script {

    // =========================================================================
    // CHAINLINK ADDRESSES — BASE SEPOLIA (chain ID 84532)
    // Verify: https://docs.chain.link/chainlink-functions/supported-networks
    // =========================================================================

    // ETH/USD Price Feed (Base Sepolia)
    // https://docs.chain.link/data-feeds/price-feeds/addresses?network=base
    address constant ETH_USD_FEED = 0x4aDC67696bA383F43DD60A9e78F2C97Fbbfc7cb1;

    // Chainlink Functions Router (Base Sepolia) — same address as Arbitrum Sepolia
    // https://docs.chain.link/chainlink-functions/supported-networks
    address constant FUNCTIONS_ROUTER = 0xf9B8fc078197181C841c296C876945aaa425B278;

    // DON ID untuk Base Sepolia (fun-base-sepolia-1)
    // hex encode of "fun-base-sepolia-1" padded to bytes32
    bytes32 constant DON_ID = 0x66756e2d626173652d7365706f6c69612d310000000000000000000000000000;

    // USDC di Base Sepolia (Circle official — sudah dipakai di x402 demo_client.py)
    // https://developers.circle.com/stablecoins/usdc-on-test-networks
    address constant USDC_BASE_SEPOLIA = 0x036CbD53842c5426634e7929541eC2318f3dCF7e;

    // =========================================================================
    // DEPLOY
    // =========================================================================

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        // Ambil subscription ID dari env (buat dulu di https://functions.chain.link)
        uint64 subscriptionId = uint64(vm.envUint("FUNCTIONS_SUBSCRIPTION_ID"));

        console.log("=== NEUROCART DEPLOYMENT ===");
        console.log("Deployer:", deployer);
        console.log("Network: Base Sepolia (chainId 84532)");
        console.log("Subscription ID:", subscriptionId);

        vm.startBroadcast(deployerPrivateKey);

        // 1. Deploy AgentRegistry (ERC-8004 + Chainlink Data Feeds)
        AgentRegistry registry = new AgentRegistry(ETH_USD_FEED);
        console.log("AgentRegistry deployed:", address(registry));

        // 2. Deploy JobEscrow (Chainlink Functions + USDC)
        JobEscrow escrow = new JobEscrow(
            address(registry),
            deployer,
            USDC_BASE_SEPOLIA
        );
        console.log("JobEscrow deployed:", address(escrow));

        // 3. Deploy NeuroCartFunctions (Chainlink Functions Consumer)
        NeuroCartFunctions functions = new NeuroCartFunctions(
            FUNCTIONS_ROUTER,
            subscriptionId,
            DON_ID
        );
        console.log("NeuroCartFunctions deployed:", address(functions));

        // 4. Deploy NeuroCartAutomation (Chainlink Automation)
        NeuroCartAutomation automation = new NeuroCartAutomation(address(escrow));
        console.log("NeuroCartAutomation deployed:", address(automation));

        // 5. Wiring: hubungkan semua contract
        registry.setEscrowContract(address(escrow));
        escrow.setFunctionsContract(address(functions));
        escrow.setAutomationContract(address(automation));
        functions.setEscrowContract(address(escrow));

        console.log("\n=== WIRING SELESAI ===");
        console.log("registry.escrowContract ->", address(escrow));
        console.log("escrow.functionsContract ->", address(functions));
        console.log("escrow.automationContract ->", address(automation));
        console.log("functions.escrowContract ->", address(escrow));

        vm.stopBroadcast();

        // Output untuk disalin ke sdk/contracts.py
        console.log("\n=== COPY KE contracts.py ===");
        console.log("AgentRegistry =", address(registry));
        console.log("JobEscrow =", address(escrow));
        console.log("NeuroCartFunctions =", address(functions));
        console.log("NeuroCartAutomation =", address(automation));

        console.log("\n=== LANGKAH SELANJUTNYA ===");
        console.log("1. Tambahkan NeuroCartFunctions ke subscription LINK:");
        console.log("   https://functions.chain.link -> tambah consumer:", address(functions));
        console.log("2. Upload verify-quality.js source ke contract:");
        console.log("   cast send", address(functions), "setSource(string)");
        console.log("3. Daftarkan NeuroCartAutomation di Automation:");
        console.log("   https://automation.chain.link -> Register Upkeep:", address(automation));
    }
}
