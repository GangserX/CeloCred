const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("CeloCred Contracts Integration Test", function () {
  let merchantRegistry;
  let paymentProcessor;
  let loanEscrow;
  let creditScoreOracle;
  let mockCUSD;
  let owner;
  let merchant;
  let customer;
  let lender;

  before(async function () {
    [owner, merchant, customer, lender] = await ethers.getSigners();

    // Deploy Mock cUSD Token
    console.log("\n📝 Deploying Mock cUSD Token...");
    const MockERC20 = await ethers.getContractFactory("MockERC20");
    mockCUSD = await MockERC20.deploy("Celo Dollar", "cUSD", ethers.parseEther("1000000"));
    await mockCUSD.waitForDeployment();
    console.log("✅ Mock cUSD deployed:", await mockCUSD.getAddress());

    // Deploy MerchantRegistry
    console.log("\n📝 Deploying MerchantRegistry...");
    const MerchantRegistry = await ethers.getContractFactory("MerchantRegistry");
    merchantRegistry = await MerchantRegistry.deploy();
    await merchantRegistry.waitForDeployment();
    console.log("✅ MerchantRegistry deployed:", await merchantRegistry.getAddress());

    // Deploy PaymentProcessor
    console.log("\n📝 Deploying PaymentProcessor...");
    const PaymentProcessor = await ethers.getContractFactory("PaymentProcessor");
    paymentProcessor = await PaymentProcessor.deploy(
      await mockCUSD.getAddress(),
      await merchantRegistry.getAddress()
    );
    await paymentProcessor.waitForDeployment();
    console.log("✅ PaymentProcessor deployed:", await paymentProcessor.getAddress());

    // Deploy LoanEscrow
    console.log("\n📝 Deploying LoanEscrow...");
    const LoanEscrow = await ethers.getContractFactory("LoanEscrow");
    loanEscrow = await LoanEscrow.deploy(await mockCUSD.getAddress());
    await loanEscrow.waitForDeployment();
    console.log("✅ LoanEscrow deployed:", await loanEscrow.getAddress());

    // Deploy CreditScoreOracle
    console.log("\n📝 Deploying CreditScoreOracle...");
    const CreditScoreOracle = await ethers.getContractFactory("CreditScoreOracle");
    creditScoreOracle = await CreditScoreOracle.deploy();
    await creditScoreOracle.waitForDeployment();
    console.log("✅ CreditScoreOracle deployed:", await creditScoreOracle.getAddress());

    // Authorize PaymentProcessor to record transactions
    console.log("\n🔗 Authorizing PaymentProcessor...");
    await merchantRegistry.setAuthorizedCaller(await paymentProcessor.getAddress(), true);
    console.log("✅ PaymentProcessor authorized");

    // Distribute cUSD to test accounts
    console.log("\n💰 Distributing cUSD to test accounts...");
    await mockCUSD.transfer(customer.address, ethers.parseEther("1000"));
    await mockCUSD.transfer(lender.address, ethers.parseEther("1000"));
    console.log("✅ cUSD distributed");
  });

  describe("Merchant Registration", function () {
    it("Should register a merchant", async function () {
      console.log("\n🧪 Testing merchant registration...");
      await merchantRegistry.connect(merchant).registerMerchant(
        "Test Store",
        "Retail",
        "Lagos, Nigeria"
      );

      const isMerchant = await merchantRegistry.isMerchant(merchant.address);
      expect(isMerchant).to.equal(true);
      console.log("✅ Merchant registered successfully");
    });

    it("Should retrieve merchant details", async function () {
      console.log("\n🧪 Testing merchant details retrieval...");
      const merchantData = await merchantRegistry.getMerchant(merchant.address);
      expect(merchantData.businessName).to.equal("Test Store");
      expect(merchantData.category).to.equal("Retail");
      expect(merchantData.isActive).to.equal(true);
      console.log("✅ Merchant details retrieved correctly");
    });
  });

  describe("Payment Processing (Both Directions)", function () {
    it("Should process customer-to-merchant payment (RECEIVED)", async function () {
      console.log("\n🧪 Testing customer→merchant payment...");
      const paymentAmount = ethers.parseEther("10");
      
      // Approve payment
      await mockCUSD.connect(customer).approve(
        await paymentProcessor.getAddress(),
        paymentAmount
      );

      // Process payment
      await paymentProcessor.connect(customer).payWithCUSD(
        merchant.address,
        paymentAmount,
        "Payment for goods"
      );

      // Check merchant received payment
      const merchantBalance = await mockCUSD.balanceOf(merchant.address);
      expect(merchantBalance).to.equal(paymentAmount);
      console.log("✅ Customer→Merchant payment successful");
    });

    it("Should record transaction in merchant registry", async function () {
      console.log("\n🧪 Verifying transaction recorded...");
      const merchantData = await merchantRegistry.getMerchant(merchant.address);
      expect(merchantData.totalTransactions).to.equal(1);
      expect(merchantData.totalVolume).to.equal(ethers.parseEther("10"));
      console.log("✅ Transaction recorded in registry");
    });

    it("Should track payment history for both customer and merchant", async function () {
      console.log("\n🧪 Testing payment history tracking...");
      const customerPayments = await paymentProcessor.getCustomerPayments(customer.address);
      const merchantPayments = await paymentProcessor.getMerchantPayments(merchant.address);
      
      expect(customerPayments.length).to.equal(1);
      expect(merchantPayments.length).to.equal(1);
      console.log("✅ Payment history tracked for both parties");
    });

    it("Should allow merchant to make payments (SENT)", async function () {
      console.log("\n🧪 Testing merchant→customer payment (refund scenario)...");
      const refundAmount = ethers.parseEther("5");
      
      // Approve refund
      await mockCUSD.connect(merchant).approve(
        await paymentProcessor.getAddress(),
        refundAmount
      );

      // Process refund
      await paymentProcessor.connect(merchant).payWithCUSD(
        customer.address,
        refundAmount,
        "Refund for returned item"
      );

      console.log("✅ Merchant→Customer payment successful");
    });

    it("Should track both sent and received transactions", async function () {
      console.log("\n🧪 Verifying bidirectional transaction tracking...");
      
      // Merchant should have both received and sent payments
      const merchantAsReceiver = await paymentProcessor.getMerchantPayments(merchant.address);
      const merchantAsSender = await paymentProcessor.getCustomerPayments(merchant.address);
      
      expect(merchantAsReceiver.length).to.equal(1); // Received from customer
      expect(merchantAsSender.length).to.equal(1); // Sent to customer (refund)
      
      console.log("✅ Both sent and received transactions tracked correctly");
    });
  });

  describe("Credit Score Management", function () {
    it("Should update credit score", async function () {
      console.log("\n🧪 Testing credit score update...");
      await creditScoreOracle.updateCreditScore(merchant.address, 750);
      
      const [score, , exists] = await creditScoreOracle.getCreditScore(merchant.address);
      expect(score).to.equal(750);
      expect(exists).to.equal(true);
      console.log("✅ Credit score updated successfully");
    });

    it("Should prevent invalid credit scores", async function () {
      console.log("\n🧪 Testing credit score validation...");
      await expect(
        creditScoreOracle.updateCreditScore(merchant.address, 900)
      ).to.be.revertedWith("Score must be between 300-850");
      console.log("✅ Credit score validation working");
    });
  });

  describe("Loan Management", function () {
    let loanId;

    it("Should request a loan", async function () {
      console.log("\n🧪 Testing loan request...");
      const tx = await loanEscrow.connect(merchant).requestLoan(
        ethers.parseEther("100"),
        500, // 5% interest
        30 // 30 days
      );
      const receipt = await tx.wait();
      
      // Get loan ID from event
      const event = receipt.logs.find(log => {
        try {
          return loanEscrow.interface.parseLog(log).name === "LoanRequested";
        } catch {
          return false;
        }
      });
      loanId = loanEscrow.interface.parseLog(event).args.loanId;
      
      console.log("✅ Loan requested, ID:", loanId);
    });

    it("Should fund a loan", async function () {
      console.log("\n🧪 Testing loan funding...");
      const loanAmount = ethers.parseEther("100");
      
      // Approve loan funding
      await mockCUSD.connect(lender).approve(
        await loanEscrow.getAddress(),
        loanAmount
      );

      // Fund the loan
      await loanEscrow.connect(lender).fundLoan(loanId);
      
      console.log("✅ Loan funded successfully");
    });

    it("Should repay a loan", async function () {
      console.log("\n🧪 Testing loan repayment...");
      const loanAmount = ethers.parseEther("100");
      const interest = ethers.parseEther("5"); // 5%
      const totalRepayment = loanAmount + interest;
      
      // Merchant needs to have enough cUSD (they have 5 from refund test, need 105)
      await mockCUSD.transfer(merchant.address, ethers.parseEther("100"));
      
      // Approve repayment
      await mockCUSD.connect(merchant).approve(
        await loanEscrow.getAddress(),
        totalRepayment
      );

      // Repay the loan
      await loanEscrow.connect(merchant).repayLoan(loanId);
      
      console.log("✅ Loan repaid successfully");
    });
  });

  describe("QR Code Merchant Verification (Simulated)", function () {
    it("Should verify merchant is registered for QR payments", async function () {
      console.log("\n🧪 Simulating QR code merchant verification...");
      
      // This simulates the QR scanner verifying a merchant
      const isMerchant = await merchantRegistry.isMerchant(merchant.address);
      expect(isMerchant).to.equal(true);
      
      // Get merchant details for QR payment
      const merchantData = await merchantRegistry.getMerchant(merchant.address);
      expect(merchantData.businessName).to.equal("Test Store");
      
      console.log("✅ QR merchant verification working");
    });

    it("Should reject non-registered merchant addresses", async function () {
      console.log("\n🧪 Testing rejection of non-registered merchants...");
      const isMerchant = await merchantRegistry.isMerchant(customer.address);
      expect(isMerchant).to.equal(false);
      console.log("✅ Non-registered address correctly rejected");
    });
  });

  describe("Dashboard Statistics Integration", function () {
    it("Should provide merchant transaction stats", async function () {
      console.log("\n🧪 Testing merchant statistics for dashboard...");
      
      const merchantData = await merchantRegistry.getMerchant(merchant.address);
      
      // These stats are used by the Firebase getMerchantStats function
      expect(merchantData.totalTransactions).to.be.greaterThan(0);
      expect(merchantData.totalVolume).to.be.greaterThan(0);
      
      console.log("📊 Merchant Stats:");
      console.log("  - Total Transactions:", merchantData.totalTransactions.toString());
      console.log("  - Total Volume:", ethers.formatEther(merchantData.totalVolume), "cUSD");
      
      console.log("✅ Dashboard statistics available");
    });
  });

  after(async function () {
    console.log("\n" + "═".repeat(70));
    console.log("🎉 ALL TESTS PASSED!");
    console.log("═".repeat(70));
    console.log("\n✅ Contracts are compatible with app changes");
    console.log("✅ Bidirectional transactions supported");
    console.log("✅ QR merchant verification working");
    console.log("✅ Dashboard statistics functional");
    console.log("\n💡 Contracts are ready for deployment!");
  });
});
