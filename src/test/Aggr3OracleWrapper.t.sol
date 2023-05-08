// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

import {BaseSetup} from "./BaseSetup.sol";
import {Aggr3Oracle} from "../Aggr3Oracle.sol";
import {Aggr3OracleWrapper} from "../Aggr3OracleWrapper.sol";
import {IOracle} from "../IOracle.sol";
import {console} from "./utils/Console.sol";

contract Aggr3OracleWrapperTest is BaseSetup {
    Aggr3Oracle internal aggr3Oracle;
    Aggr3OracleWrapper internal aggr3OracleWrapper;

    function setUp() public override {
        super.setUp();

        vm.prank(owner);
        aggr3Oracle = new Aggr3Oracle(owner, "Description", "Terms of service");
        vm.stopPrank();

        aggr3OracleWrapper = new Aggr3OracleWrapper(
            IOracle(address(aggr3Oracle))
        );
    }

    function testAcceptedTermsOfService() public {
        bool accepted = aggr3Oracle.acceptedTermsOfService(
            address(aggr3OracleWrapper)
        );
        assertTrue(accepted);
    }

    function testReadPriceIfAcceptedToS(uint256 _price) public {
        vm.assume(_price > 0);

        vm.prank(owner);
        aggr3Oracle.writeData(_price);
        vm.stopPrank();

        vm.startPrank(reader);
        aggr3OracleWrapper.acceptTermsOfService();

        assertTrue(aggr3OracleWrapper.acceptedTermsOfService(reader));

        uint256 priceData = aggr3OracleWrapper.readData();

        uint256 invertedPrice = (1e18 * 1e18) / _price;

        assertEq(priceData, invertedPrice);
        vm.stopPrank();
    }

    function testReadPriceRevertIfNotAcceptedToS() public {
        vm.expectRevert(abi.encodePacked("Terms of Service not accepted"));

        vm.prank(reader);
        aggr3OracleWrapper.readData();
    }
}
