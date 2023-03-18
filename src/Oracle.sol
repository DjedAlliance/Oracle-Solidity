// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "./MultiOwnable.sol";

contract Oracle is MultiOwnable {
    // # Parameters
    string public description; // short string describing this oracle's data (e.g. "ADA/USD")
    uint public constant scaling = 1e18;   // 18 decimals
    uint public immutable lockingPeriod;   // locking period (in seconds) for changes by the owners that may negatively affect consumers
    

    // # State Variables
    uint private data;             // latest data provided by the oracle
    uint private time = 0;    // timestamp to be used for keeping track of events
    uint private totalCost = 0;    // sum of costs informed by owners for writing data (resettable to avoid overflow)
    uint private totalRevenue = 0; // sum of fees paid by consumers for reading data (resettable to avoid overflow)
    uint private writes = 0; // number of writes since last base fee adjustment
    uint private reads = 0;  // number of weighted reads since last base fee adjustment
    uint public baseFee;        // fee to read the data once, only paid if the data is new
    uint public maxFee;         // maximum fee to read the data once
    uint public maxFeeNext;     // next maximum fee, which replaced `maxFee` after `maxFeeTimelock`
    uint public maxFeeTimelock; // timestamp of the earliest time for the next max fee adjustment
    uint public latestCost;  // latest cost of writing data
    uint public latestWrite; // timestamp of the latest write
    uint public totalCredit = 0; // sum of credits of all consumers
    mapping(address => uint) private credit; // credit of a consumer, used to pay for data reads
    mapping(address => uint) private latestRead; // timestamps of the latest reads of consumers
    mapping(address => uint) private weight; // weight imposed by owners on consumers that are reselling the data, to prevent free-riding
    mapping(address => uint) private weightNext; // next weight, which replaces the current weight after the timelock
    mapping(address => uint) private weightTimelock; // timestamp of the earliest time for the next weight adjustment
    
    event DataWritten(uint data, uint cost);
    event DataRead(address consumer, uint weight, uint data);
    event WeightAdjustmentScheduled(address consumer, uint weightTimelock, uint weightNext);
    event WeightAdjusted(address consumer, uint weight);
    event MaxFeeAdjustmentScheduled(uint maxFeeTimelock, uint maxFeeNext);
    event MaxFeeAdjusted(uint maxFee);
    event BaseFeeAdjusted(uint writes, uint reads, uint fee);  
    event CreditDeposited(address consumer, uint amount);
    event CreditWithdrawn(address consumer, uint amount);
    event RevenueWithdrawn(address receiver, uint amount);
    event Reset(uint cost, uint revenue);

    constructor(address _owner, string memory _description, uint _lockingPeriod, uint _baseFee) MultiOwnable(_owner) {
        description = _description;
        lockingPeriod = _lockingPeriod;
        baseFee = _baseFee;
        maxFee = _baseFee * 3;
    }

    // ####### Testing Purpose Only
    function getTotalCost () external view onlyOwner returns (uint)
    {
        return totalCost;
    }
    function getTotalRevenue () external view onlyOwner returns (uint)
    {
        return totalRevenue;
    }
    function getLatestRead (address consumer) external view onlyOwner returns (uint)
    {
        return latestRead [consumer];
    }
    function getReads () external view onlyOwner returns (uint)
    {
        return reads;
    }
    function getWrites () external view onlyOwner returns (uint)
    {
        return writes;
    }
    
    // # Functions to Write and Read Data.

    function writeData(uint _data, uint cost) external onlyOwner 
    {
        writes += 1;
        data = _data;
        totalCost += cost;
        latestCost = cost;
        time += 1;
        latestWrite = time;
        emit DataWritten(data, cost);
    }

    function readData() external returns (uint) {
        uint w = weightOf(msg.sender);
        uint f = feeOf(msg.sender, w);
        require(credit[msg.sender] >= f, "Insufficient credit");
        credit[msg.sender] -= f; // Consumer pays to read data
        totalCredit -= f;
        reads = reads + (f > 0 ? w : 0);
        totalRevenue += f;
        time += 1;
        latestRead[msg.sender] = time; // update the consumer's latest read timestamp
        emit DataRead(msg.sender, w, data);
        return data;
    }

    function inspectData() external view onlyOwner() returns (uint) { return data; } // Owners can read data for free.

    // # Functions to View a Consumer's State.

    function creditOf(address consumer) external view returns (uint) { return credit[consumer]; }
    function weightOf(address consumer) public view returns (uint) { return (weight [consumer] == 0) ? 1 : (weight[consumer]); } 
    function feeOf(address consumer) public view returns (uint) { return feeOf(consumer, weightOf(consumer)); }
    function feeOf(address consumer, uint _weight) internal view returns (uint) 
    { return latestRead[consumer] > latestWrite ? 0 : (_weight * baseFee); }

    function stateVariables(address consumer) external view returns (uint, uint) {
        return (baseFee * weightOf(consumer), credit [consumer]);
    }

    // # Functions for owners to adjust fees and weights
    //
    // To protect consumers from sudden changes, adjustments must be scheduled in advance.

    function scheduleWeightAdjustment(address consumer, uint _weightNext) external onlyOwner {
        uint t = block.timestamp + lockingPeriod;
        weightTimelock[consumer] = t;
        weightNext[consumer] = _weightNext;
        emit WeightAdjustmentScheduled(consumer, t, _weightNext);
    }

    function adjustWeight(address consumer) external onlyOwner {
        require(block.timestamp >= weightTimelock[consumer], "locking period not elapsed");
        uint w = weightNext[consumer];
        weight[consumer] = w;
        emit WeightAdjusted(consumer, w);
    }

    function scheduleMaxFeeAdjustment(uint _maxFeeNext) external onlyOwner {
        maxFeeTimelock = block.timestamp + lockingPeriod;
        maxFeeNext = _maxFeeNext;
        emit MaxFeeAdjustmentScheduled(maxFeeTimelock, maxFeeNext);
    }

    function adjustMaxFee() external onlyOwner {
        require(block.timestamp >= maxFeeTimelock, "locking period not elapsed");
        maxFee = maxFeeNext;
        emit MaxFeeAdjusted(maxFee);
    }

    // We extrapolate that, from now until next call to `adjustFee`, number of writes and reads will be the same as in previous period.
    // We extrapolate that the cost of every future write will be the same as the cost of the latest write.
    // If true and we are not in a corner case of integer subtraction or division, `totalCost` will be equal to `totalRevenue` at the next call to `adjustFees`.
    function adjustBaseFee() external {
        baseFee = min(subtraction((latestCost * writes) + totalCost, totalRevenue) / ((reads != 0) ? reads : 1), maxFee);
        emit BaseFeeAdjusted(writes, reads, baseFee);
        writes = 0;
        reads = 0;
    }

    // # Functions for consumers to deposit, withdraw and view their credits
    function depositCredit(address consumer) external payable { 
        credit[consumer] += msg.value; 
        totalCredit += msg.value;
        emit CreditDeposited(consumer, msg.value);
    }

    function withdrawCredit(uint amount) external {
        require(credit[msg.sender] >= amount, "Insufficient credit");
        credit[msg.sender] -= amount;
        totalCredit -= amount;
        payable(msg.sender).transfer(amount);
        emit CreditWithdrawn(msg.sender, amount);
    }

    // Withdraws part of the revenue accumulated by the contract to a receiver specified by the calling owner
    function withdraw(address receiver, uint amount) external onlyOwner {
        require(address(this).balance - totalCredit >= amount, "Insufficient balance");
        payable(receiver).transfer(amount);
        emit RevenueWithdrawn(receiver, amount);
    }

    // Prevents overflow of `totalCost` and `totalRevenue`, preserving their difference
    function resetCostAndRevenue() external {
        emit Reset(totalCost, totalRevenue);
        if (totalCost > totalRevenue) {
            totalCost -= totalRevenue;
            totalRevenue = 0;
        } else {
            totalRevenue -= totalCost;
            totalCost = 0;
        }
    }

    function subtraction(uint a, uint b) internal pure returns (uint) { return (b < a) ? (a - b) : 0; } 
    function max(uint a, uint b) internal pure returns (uint) { return (b < a) ? a : b; } 
    function min(uint a, uint b) internal pure returns (uint) { return (b < a) ? b : a; }
}
