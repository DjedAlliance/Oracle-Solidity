// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import {MultiOwnable} from "./MultiOwnable.sol";

contract SimpleOracle is MultiOwnable {
    string public description; // short string describing this oracle's data (e.g. "ADA/USD")
    string public termsOfService; // terms of service
    uint256 private data; // latest data provided by the oracle

    event DataWritten(uint256 data);

    mapping(address => bool) public acceptedTermsOfService;

    modifier onlyAcceptedTermsOfService() {
        require(
            acceptedTermsOfService[msg.sender],
            "Terms of Service not accepted"
        );
        _;
    }

    constructor(
        address _owner,
        string memory _description,
        string memory _termsOfService
    ) MultiOwnable(_owner) {
        description = _description;
        termsOfService = _termsOfService;
    }

    function writeData(uint256 _data) external onlyOwner {
        data = _data;
        emit DataWritten(data);
    }

    function readData()
        external
        view
        onlyAcceptedTermsOfService
        returns (uint256)
    {
        return data;
    }

    function acceptTermsOfService() external {
        acceptedTermsOfService[msg.sender] = true;
    }
}
