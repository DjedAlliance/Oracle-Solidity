// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import {MultiOwnable} from "./MultiOwnable.sol";

contract Aggr3Oracle is MultiOwnable {
    string public description; // short string describing this oracle's data (e.g. "USD/ADA")
    string public termsOfService; // terms of service

    struct Data {
        uint256 value;
        address owner;
    }
    Data[] private data; // data provided by the owners
    uint256 private median; // median of the last 3 data points from distinct owners

    event DataWritten(uint256 data, address indexed owner);

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
        data.push(Data(_data, msg.sender));
        emit DataWritten(_data, msg.sender);

        // # Begin Median Update
        uint256[] memory values = new uint256[](3); // Will contain up to 3 latest data points by 3 mutually distinct owners.
        address[] memory owners = new address[](3); // Will contain the owners who wrote the data points in `values`.

        uint256 index; // = 0  // an index for `values` and `owners`
        uint256 i = data.length - 1; // traversal of `data` starts from the end, to get the latest data points
        while (index < 3) {
            // will find at most 3 data points to populate `values` and `owners`
            bool isOwnerDistinct = true;
            for (uint256 j; j < index; ) {
                // checks whether the owner of the i-th data point is distinct from all owners in `owners`
                if (owners[j] == data[i].owner) {
                    isOwnerDistinct = false;
                    break;
                }
                unchecked {
                    ++j;
                }
            }
            if (isOwnerDistinct) {
                // if it is, then populate `values` and `owners` accordingly
                values[index] = data[i].value;
                owners[index] = data[i].owner;
                unchecked {
                    ++index;
                }
            }
            if (i == 0) break;
            else {
                unchecked {
                    --i;
                }
            } // continue traversing `data`
        }

        if (index == 3) median = median3(values[0], values[1], values[2]);
        else if (index == 2) median = (values[0] + values[1]) / 2;
        else median = values[0]; // (index == 1), since `index == 0` never occurs.
        // # End Median Update
    }

    function readData()
        external
        view
        onlyAcceptedTermsOfService
        returns (uint256)
    {
        return median;
    }

    function acceptTermsOfService() external {
        acceptedTermsOfService[msg.sender] = true;
    }

    function median3(
        uint256 a,
        uint256 b,
        uint256 c
    ) internal pure returns (uint256) {
        if (a >= b) {
            if (c >= a) return a;
            else if (b >= c) return b;
            else return c;
        } else {
            // b > a
            if (c >= b) return b;
            else if (a >= c) return a;
            else return c;
        }
    }
}
