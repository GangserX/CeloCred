/**
 * Credit Score Calculator
 * 
 * Calculates credit scores based on transaction history and loan behavior
 * Score range: 300-850 (similar to FICO)
 */

export class CreditScoreCalculator {
  constructor() {
    // Score component weights (total = 100%)
    this.weights = {
      paymentHistory: 0.35,      // 35% - Most important
      creditUtilization: 0.30,   // 30% - Loan vs revenue ratio
      lengthOfHistory: 0.15,     // 15% - Account age
      newCredit: 0.10,           // 10% - Recent loan activity
      creditMix: 0.10,           // 10% - Diversity of transactions
    };
    
    // Base score for new users
    this.baseScore = 650;
    
    // Score boundaries
    this.minScore = 300;
    this.maxScore = 850;
  }

  /**
   * Calculate credit score for a merchant
   * @param {Object} merchantData - Merchant profile and transaction data
   * @returns {number} Credit score (300-850)
   */
  calculateScore(merchantData) {
    const {
      transactions = [],
      loans = [],
      registeredAt,
      walletAddress,
    } = merchantData;

    // Need minimum transactions to calculate score
    if (transactions.length < 3) {
      return this.baseScore; // Default score for new merchants
    }

    // Calculate each component
    const paymentScore = this.calculatePaymentHistory(transactions, loans);
    const utilizationScore = this.calculateCreditUtilization(transactions, loans);
    const historyScore = this.calculateLengthOfHistory(registeredAt);
    const newCreditScore = this.calculateNewCredit(loans);
    const mixScore = this.calculateCreditMix(transactions);

    // Weighted average
    const totalScore = (
      paymentScore * this.weights.paymentHistory +
      utilizationScore * this.weights.creditUtilization +
      historyScore * this.weights.lengthOfHistory +
      newCreditScore * this.weights.newCredit +
      mixScore * this.weights.creditMix
    );

    // Clamp to valid range and round
    const finalScore = Math.round(
      Math.max(this.minScore, Math.min(this.maxScore, totalScore))
    );

    return finalScore;
  }

  /**
   * Payment History (35%)
   * Based on: on-time loan repayments, transaction consistency
   */
  calculatePaymentHistory(transactions, loans) {
    if (loans.length === 0) {
      // No loans yet - base on transaction consistency
      return this.calculateTransactionConsistency(transactions);
    }

    let totalLoans = 0;
    let onTimeRepayments = 0;
    let lateRepayments = 0;
    let defaults = 0;

    for (const loan of loans) {
      totalLoans++;
      
      if (loan.status === 'repaid') {
        // Check if repayment was on time
        const dueDate = loan.dueDate?.toDate ? loan.dueDate.toDate() : new Date(loan.dueDate);
        const repaidDate = loan.repaidAt?.toDate ? loan.repaidAt.toDate() : new Date(loan.repaidAt);
        
        if (repaidDate <= dueDate) {
          onTimeRepayments++;
        } else {
          lateRepayments++;
        }
      } else if (loan.status === 'defaulted') {
        defaults++;
      }
    }

    // Calculate score
    const onTimeRate = totalLoans > 0 ? onTimeRepayments / totalLoans : 1;
    const lateRate = totalLoans > 0 ? lateRepayments / totalLoans : 0;
    const defaultRate = totalLoans > 0 ? defaults / totalLoans : 0;

    let score = 850;
    score -= lateRate * 100;      // Late payments reduce score
    score -= defaultRate * 250;   // Defaults heavily reduce score

    return Math.max(300, score);
  }

  /**
   * Transaction Consistency (for merchants without loans)
   */
  calculateTransactionConsistency(transactions) {
    if (transactions.length === 0) return 650;

    // Sort by date
    const sorted = [...transactions].sort((a, b) => {
      const dateA = a.timestamp?.toDate ? a.timestamp.toDate() : new Date(a.timestamp);
      const dateB = b.timestamp?.toDate ? b.timestamp.toDate() : new Date(b.timestamp);
      return dateA - dateB;
    });

    // Calculate transaction frequency (transactions per month)
    const firstTx = sorted[0].timestamp?.toDate ? sorted[0].timestamp.toDate() : new Date(sorted[0].timestamp);
    const lastTx = sorted[sorted.length - 1].timestamp?.toDate ? sorted[sorted.length - 1].timestamp.toDate() : new Date(sorted[sorted.length - 1].timestamp);
    const monthsDiff = (lastTx - firstTx) / (1000 * 60 * 60 * 24 * 30) || 1;
    const txPerMonth = transactions.length / monthsDiff;

    // Score based on consistency
    let score = 650;
    if (txPerMonth >= 10) score += 100;      // Very active
    else if (txPerMonth >= 5) score += 50;   // Active
    else if (txPerMonth >= 2) score += 25;   // Moderate

    return Math.min(850, score);
  }

  /**
   * Credit Utilization (30%)
   * Ratio of outstanding loans to monthly revenue
   */
  calculateCreditUtilization(transactions, loans) {
    // Calculate total monthly revenue
    const monthlyRevenue = this.calculateMonthlyRevenue(transactions);
    
    if (monthlyRevenue === 0) return 650; // No data

    // Calculate outstanding loan amounts
    const outstandingLoans = loans
      .filter(loan => ['disbursed', 'funded', 'repaying'].includes(loan.status))
      .reduce((sum, loan) => sum + (loan.amount || 0), 0);

    // Utilization ratio
    const utilizationRatio = outstandingLoans / monthlyRevenue;

    // Score based on utilization
    let score = 850;
    if (utilizationRatio < 0.3) score = 850;        // Excellent (<30%)
    else if (utilizationRatio < 0.5) score = 750;   // Good (30-50%)
    else if (utilizationRatio < 0.7) score = 650;   // Fair (50-70%)
    else if (utilizationRatio < 1.0) score = 550;   // Poor (70-100%)
    else score = 450;                               // Very high (>100%)

    return score;
  }

  /**
   * Calculate average monthly revenue
   */
  calculateMonthlyRevenue(transactions) {
    if (transactions.length === 0) return 0;

    // Get last 3 months of transactions
    const threeMonthsAgo = new Date();
    threeMonthsAgo.setMonth(threeMonthsAgo.getMonth() - 3);

    const recentTx = transactions.filter(tx => {
      const txDate = tx.timestamp?.toDate ? tx.timestamp.toDate() : new Date(tx.timestamp);
      return txDate >= threeMonthsAgo;
    });

    const totalRevenue = recentTx.reduce((sum, tx) => sum + (tx.amount || 0), 0);
    return totalRevenue / 3; // Average per month
  }

  /**
   * Length of History (15%)
   * How long the merchant has been active
   */
  calculateLengthOfHistory(registeredAt) {
    const registeredDate = registeredAt?.toDate ? registeredAt.toDate() : new Date(registeredAt);
    const now = new Date();
    const daysSinceRegistration = (now - registeredDate) / (1000 * 60 * 60 * 24);

    let score = 650;
    if (daysSinceRegistration >= 365) score = 850;       // 1+ years
    else if (daysSinceRegistration >= 180) score = 750;  // 6+ months
    else if (daysSinceRegistration >= 90) score = 700;   // 3+ months
    else if (daysSinceRegistration >= 30) score = 650;   // 1+ month
    else score = 600;                                    // Less than 1 month

    return score;
  }

  /**
   * New Credit (10%)
   * Recent loan applications (too many = risky)
   */
  calculateNewCredit(loans) {
    if (loans.length === 0) return 750; // No loans = not risky

    // Count loans requested in last 3 months
    const threeMonthsAgo = new Date();
    threeMonthsAgo.setMonth(threeMonthsAgo.getMonth() - 3);

    const recentLoans = loans.filter(loan => {
      const requestDate = loan.requestedAt?.toDate ? loan.requestedAt.toDate() : new Date(loan.requestedAt);
      return requestDate >= threeMonthsAgo;
    });

    // Score based on recent loan activity
    let score = 750;
    if (recentLoans.length === 0) score = 750;      // No recent loans
    else if (recentLoans.length === 1) score = 700; // 1 loan (normal)
    else if (recentLoans.length === 2) score = 650; // 2 loans (moderate risk)
    else score = 550;                               // 3+ loans (high risk)

    return score;
  }

  /**
   * Credit Mix (10%)
   * Diversity of transaction types
   */
  calculateCreditMix(transactions) {
    if (transactions.length === 0) return 650;

    // Count unique currencies used
    const currencies = new Set(transactions.map(tx => tx.currency));
    const currencyCount = currencies.size;

    // Count transaction patterns
    const avgAmount = transactions.reduce((sum, tx) => sum + (tx.amount || 0), 0) / transactions.length;
    const hasSmall = transactions.some(tx => tx.amount < avgAmount * 0.5);
    const hasLarge = transactions.some(tx => tx.amount > avgAmount * 2);

    // Score based on diversity
    let score = 650;
    if (currencyCount >= 2) score += 50;  // Uses multiple currencies
    if (hasSmall && hasLarge) score += 50; // Diverse transaction sizes
    if (transactions.length >= 20) score += 50; // High volume

    return Math.min(850, score);
  }

  /**
   * Get detailed score breakdown
   */
  getScoreBreakdown(merchantData) {
    const {
      transactions = [],
      loans = [],
      registeredAt,
    } = merchantData;

    const components = {
      paymentHistory: this.calculatePaymentHistory(transactions, loans),
      creditUtilization: this.calculateCreditUtilization(transactions, loans),
      lengthOfHistory: this.calculateLengthOfHistory(registeredAt),
      newCredit: this.calculateNewCredit(loans),
      creditMix: this.calculateCreditMix(transactions),
    };

    const totalScore = this.calculateScore(merchantData);

    return {
      totalScore,
      components,
      weights: this.weights,
      metadata: {
        transactionCount: transactions.length,
        loanCount: loans.length,
        accountAgeDays: Math.floor(
          (new Date() - (registeredAt?.toDate ? registeredAt.toDate() : new Date(registeredAt))) / (1000 * 60 * 60 * 24)
        ),
      },
    };
  }
}

export default CreditScoreCalculator;
