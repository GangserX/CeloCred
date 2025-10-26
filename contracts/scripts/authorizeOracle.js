const hre = require("hardhat");

async function main() {
  console.log("\n🔐 Authorizing Oracle Wallet...\n");

  // Contract details
  const contractAddress = "0xaF04bC6b274d6De4e6d260BDFA6B57EB14fd3C4c";
  const oracleAddress = "0xf2e92f2bde761fa4e7b1f81ccf1fe096aa74dc75";

  // Get the contract
  const CreditScoreOracle = await hre.ethers.getContractAt(
    "CreditScoreOracle",
    contractAddress
  );

  console.log("📋 Contract:", contractAddress);
  console.log("🤖 Oracle Wallet:", oracleAddress);
  
  // Get current owner
  const owner = await CreditScoreOracle.owner();
  console.log("👤 Contract Owner:", owner);
  
  const [signer] = await hre.ethers.getSigners();
  console.log("✍️  Signer:", signer.address);
  
  if (owner.toLowerCase() !== signer.address.toLowerCase()) {
    console.error("\n❌ Error: You are not the contract owner!");
    console.error(`   Owner: ${owner}`);
    console.error(`   Your address: ${signer.address}`);
    process.exit(1);
  }

  // Check if already authorized
  console.log("\n🔍 Checking current authorization status...");
  try {
    const isAuthorized = await CreditScoreOracle.authorizedOracles(oracleAddress);
    console.log("Current status:", isAuthorized ? "✅ Already Authorized" : "❌ Not Authorized");
    
    if (isAuthorized) {
      console.log("\n✅ Oracle is already authorized! No action needed.");
      return;
    }
  } catch (error) {
    console.log("⚠️  Could not check authorization status (function may not exist)");
    console.log("   Proceeding with authorization anyway...");
  }

  // Authorize the oracle
  console.log("\n📝 Authorizing oracle wallet...");
  const tx = await CreditScoreOracle.setOracle(oracleAddress, true, {
    gasLimit: 100000 // Explicit gas limit
  });
  
  console.log("⏳ Transaction sent:", tx.hash);
  console.log("   Waiting for confirmation...");
  
  const receipt = await tx.wait();
  
  console.log("\n✅ SUCCESS! Oracle authorized!");
  console.log("   Transaction:", receipt.hash);
  console.log("   Block:", receipt.blockNumber);
  console.log("   Gas used:", receipt.gasUsed.toString());

  // Verify authorization
  console.log("\n🔍 Verifying authorization...");
  try {
    const isAuthorized = await CreditScoreOracle.authorizedOracles(oracleAddress);
    if (isAuthorized) {
      console.log("✅ Verification successful! Oracle is now authorized.");
    } else {
      console.log("⚠️  Warning: Authorization status still shows false");
    }
  } catch (error) {
    console.log("⚠️  Could not verify (function may not exist, but authorization likely succeeded)");
  }

  console.log("\n🎉 All done! Your backend can now update credit scores on-chain.");
  console.log("\n📋 Next steps:");
  console.log("   1. cd ../backend");
  console.log("   2. npm test          # Run connection tests");
  console.log("   3. npm run update-scores -- --dry-run  # Test without blockchain");
  console.log("   4. npm run update-scores  # Update scores for real");
  console.log("   5. npm start         # Start automatic hourly updates");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error("\n❌ Error:", error.message);
    if (error.data) {
      console.error("   Error data:", error.data);
    }
    if (error.reason) {
      console.error("   Reason:", error.reason);
    }
    console.error("\n💡 Troubleshooting:");
    console.error("   - Make sure your wallet has CELO for gas");
    console.error("   - Check that you're connected to Alfajores testnet");
    console.error("   - Verify the contract address is correct");
    process.exit(1);
  });
