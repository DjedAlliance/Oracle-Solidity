// SPDX-License-Identifier: AFEL
pragma solidity ^0.8.0;

interface IOracle {
    function readData() external view returns (uint256);

    function stateVariables(address consumer)
        external
        view
        returns (
            uint256 baseFee,
            uint256 credit,
            uint256 weight
        );

    function depositCredit(address consumer) external payable;

    function acceptTermsOfService() external;
}
