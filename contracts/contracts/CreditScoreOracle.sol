// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title CreditScoreOracle
 * @dev Store and manage credit scores on-chain
 */
contract CreditScoreOracle is Ownable {
    struct CreditScore {
        uint256 score; // 300-850 range
        uint256 lastUpdated;
        bool exists;
    }

    mapping(address => CreditScore) public creditScores;
    address[] public scoredAddresses;
    mapping(address => bool) public authorizedOracles;

    event CreditScoreUpdated(
        address indexed user,
        uint256 oldScore,
        uint256 newScore,
        uint256 timestamp
    );

    event OracleAuthorized(
        address indexed oracle,
        bool authorized
    );

    constructor() Ownable(msg.sender) {}

    /**
     * @dev Set authorized oracle
     */
    function setOracle(address _oracle, bool _authorized) external onlyOwner {
        authorizedOracles[_oracle] = _authorized;
        emit OracleAuthorized(_oracle, _authorized);
    }

    /**
     * @dev Update credit score (only owner/oracle)
     */
    function updateCreditScore(address _user, uint256 _score) external {
        require(
            authorizedOracles[msg.sender] || msg.sender == owner(),
            "Not authorized to update credit scores"
        );
        require(_score >= 300 && _score <= 850, "Score must be between 300-850");

        uint256 oldScore = creditScores[_user].score;
        
        if (!creditScores[_user].exists) {
            scoredAddresses.push(_user);
        }

        creditScores[_user] = CreditScore({
            score: _score,
            lastUpdated: block.timestamp,
            exists: true
        });

        emit CreditScoreUpdated(_user, oldScore, _score, block.timestamp);
    }

    /**
     * @dev Batch update credit scores (for efficiency)
     */
    function updateCreditScoresBatch(
        address[] calldata _users,
        uint256[] calldata _scores
    ) external {
        require(
            authorizedOracles[msg.sender] || msg.sender == owner(),
            "Not authorized to update credit scores"
        );
        require(_users.length == _scores.length, "Array length mismatch");

        for (uint256 i = 0; i < _users.length; i++) {
            require(_scores[i] >= 300 && _scores[i] <= 850, "Invalid score");
            
            uint256 oldScore = creditScores[_users[i]].score;
            
            if (!creditScores[_users[i]].exists) {
                scoredAddresses.push(_users[i]);
            }

            creditScores[_users[i]] = CreditScore({
                score: _scores[i],
                lastUpdated: block.timestamp,
                exists: true
            });

            emit CreditScoreUpdated(_users[i], oldScore, _scores[i], block.timestamp);
        }
    }

    /**
     * @dev Get credit score
     */
    function getCreditScore(address _user)
        external
        view
        returns (uint256 score, uint256 lastUpdated, bool exists)
    {
        CreditScore memory cs = creditScores[_user];
        return (cs.score, cs.lastUpdated, cs.exists);
    }

    /**
     * @dev Check if user has a credit score
     */
    function hasScore(address _user) external view returns (bool) {
        return creditScores[_user].exists;
    }

    /**
     * @dev Get total number of scored users
     */
    function getScoredUserCount() external view returns (uint256) {
        return scoredAddresses.length;
    }
}
