// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import "./IOracle.sol";

contract Aggr3OracleWrapper {
    IOracle immutable a3oracle;

    uint256 constant SCALE = 1e18;

    mapping(address => bool) public acceptedTermsOfService;

    modifier onlyAcceptedTermsOfService() {
        require(
            acceptedTermsOfService[msg.sender],
            "Terms of Service not accepted"
        );
        _;
    }

    constructor(IOracle oracle) {
        // Accept the ToS required in the oracle contract
        oracle.acceptTermsOfService();
        a3oracle = oracle;
    }

    function acceptTermsOfService() external {
        acceptedTermsOfService[msg.sender] = true;
    }

    function readData()
        external
        view
        onlyAcceptedTermsOfService
        returns (uint256)
    {
        uint256 price = a3oracle.readData();

        return (1e18 * SCALE) / price;
    }
}
