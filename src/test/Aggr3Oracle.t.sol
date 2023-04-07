// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

import {DSTest} from "ds-test/test.sol";
import {Utilities} from "./utils/Utilities.sol";
import {console} from "./utils/Console.sol";
import {Vm} from "forge-std/Vm.sol";
import {Aggr3Oracle} from "../Aggr3Oracle.sol";
import {BaseSetup} from "./BaseSetup.sol";

contract aggr3OracleTest is BaseSetup {
    Aggr3Oracle internal aggr3Oracle;

    function setUp() public override {
        super.setUp();

        vm.prank(owner);
        aggr3Oracle = new Aggr3Oracle(owner, "Description", "Terms of service");
        vm.stopPrank();
    }

    function testAcceptTermsOfService() public {
        console.log("Should accept terms of service");

        vm.startPrank(owner);
        aggr3Oracle.acceptTermsOfService();

        bool accepted = aggr3Oracle.acceptedTermsOfService(owner);
        assertTrue(accepted);
    }

    function testWriteAndReadData() public {
        console.log("Should set the data when called by the owner");

        vm.startPrank(owner);
        aggr3Oracle.writeData(1000);

        aggr3Oracle.acceptTermsOfService();

        uint256 dataAfterWrite = aggr3Oracle.readData();
        assertEq(dataAfterWrite, 1000);
        vm.stopPrank();
    }

    function testWriteDataRevertIfNotOwner() public {
        console.log("Should fail to set data when caller is not the owner");

        vm.startPrank(nonOwner);
        vm.expectRevert(abi.encodePacked("Unauthorized"));
        aggr3Oracle.writeData(1000);
        vm.stopPrank();
    }

    function testReadDataRevertIfNotAcceptedTermsOfService() public {
        console.log(
            "Should fail to read data when caller did not accept terms of service"
        );

        vm.startPrank(owner);
        vm.expectRevert(abi.encodePacked("Terms of Service not accepted"));
        aggr3Oracle.readData();
        vm.stopPrank();
    }

    function testWriteDataWithFuzzing(uint256 value) public {
        console.log("Should handle fuzzing");

        vm.startPrank(owner);
        aggr3Oracle.writeData(value);

        aggr3Oracle.acceptTermsOfService();

        uint256 dataAfterWrite = aggr3Oracle.readData();
        assertEq(dataAfterWrite, value);
        vm.stopPrank();
    }

    function testSupport() public {
        console.log("Should support non owner when called by the owner");
        address nonOwner = users[1];
        uint256 supportCounterBefore = aggr3Oracle.supportCounter(nonOwner);

        vm.startPrank(owner);
        aggr3Oracle.support(nonOwner);
        vm.stopPrank();

        uint256 supportCounterAfter = aggr3Oracle.supportCounter(nonOwner);

        assertEq(supportCounterAfter, supportCounterBefore + 1);
        assertEq(aggr3Oracle.supporting(owner, 0), nonOwner);
        assertTrue(aggr3Oracle.supporters(nonOwner, owner));
    }

    function testSupportRevertIfNotOwner() public {
        console.log("Should fail when caller is not the owner");

        address firstNonOwner = users[1];
        address secondNonOwner = users[2];

        vm.startPrank(firstNonOwner);
        vm.expectRevert(abi.encodePacked("Unauthorized"));

        aggr3Oracle.support(secondNonOwner);
        vm.stopPrank();
    }

    function testSupportRevertAlreadySupporting() public {
        console.log("Should fail to support when already supporting");

        address nonOwner = users[1];
        vm.startPrank(owner);
        aggr3Oracle.support(nonOwner);

        vm.expectRevert(abi.encodePacked("already supporting"));
        aggr3Oracle.support(nonOwner);

        vm.stopPrank();
    }

    function testSupportWithFuzzing(address user) public {
        console.log("Should handle fuzzing");

        vm.assume(user != owner);
        vm.startPrank(owner);

        aggr3Oracle.support(user);
        vm.stopPrank();

        assertEq(aggr3Oracle.supportCounter(user), 1);
        assertEq(aggr3Oracle.supporting(owner, 0), user);
        assertTrue(aggr3Oracle.supporters(user, owner));
    }

    function testUnsupport() public {
        console.log("Should unsupport non owner when called by the owner");

        vm.startPrank(owner);
        address nonOwner = users[1];
        aggr3Oracle.support(nonOwner);

        uint256 supportCounterBefore = aggr3Oracle.supportCounter(nonOwner);

        aggr3Oracle.unsupport(nonOwner);
        vm.stopPrank();

        uint256 supportCounterAfter = aggr3Oracle.supportCounter(nonOwner);

        assertEq(supportCounterAfter, supportCounterBefore - 1);
        assertTrue(!aggr3Oracle.supporters(nonOwner, owner));

        vm.expectRevert();
        aggr3Oracle.supporting(owner, 0);
    }

    function testUnsupportRevertIfNotOwner() public {
        console.log("Should fail when caller is not the owner");

        address firstNonOwner = users[1];
        address secondNonOwner = users[2];

        vm.startPrank(firstNonOwner);
        vm.expectRevert(abi.encodePacked("Unauthorized"));

        aggr3Oracle.unsupport(secondNonOwner);
        vm.stopPrank();
    }

    function testUnsupportWithFuzzing(address user) public {
        console.log("Should handle fuzzing");

        vm.assume(user != owner);
        vm.startPrank(owner);

        aggr3Oracle.support(user);

        uint256 supportCounterBefore = aggr3Oracle.supportCounter(user);

        aggr3Oracle.unsupport(user);
        vm.stopPrank();

        uint256 supportCounterAfter = aggr3Oracle.supportCounter(user);

        assertEq(supportCounterAfter, supportCounterBefore - 1);
        assertTrue(!aggr3Oracle.supporters(user, owner));

        vm.expectRevert();
        aggr3Oracle.supporting(owner, 0);
    }

    function testAdd() public {
        address nonOwner = users[1];

        vm.startPrank(owner);
        aggr3Oracle.support(nonOwner);
        vm.stopPrank();

        uint256 numOwnersBefore = aggr3Oracle.numOwners();
        aggr3Oracle.add(nonOwner);
        uint256 numOwnersAfter = aggr3Oracle.numOwners();

        assertEq(numOwnersAfter, numOwnersBefore + 1);
        assertTrue(aggr3Oracle.owner(nonOwner));
    }

    function testAddRevertInsufficientQuorum() public {
        address nonOwner = users[1];

        vm.expectRevert(abi.encodePacked("Insufficient quorum"));
        aggr3Oracle.add(nonOwner);
    }

    function testRemove() public {
        address secondOwner = users[1];
        address ownerToRemove = users[2];

        vm.startPrank(owner);
        aggr3Oracle.support(secondOwner);
        aggr3Oracle.add(secondOwner);

        aggr3Oracle.support(ownerToRemove);
        vm.stopPrank();

        vm.startPrank(secondOwner);
        aggr3Oracle.support(ownerToRemove);
        aggr3Oracle.add(ownerToRemove);
        vm.stopPrank();

        vm.startPrank(owner);
        aggr3Oracle.oppose(ownerToRemove);
        vm.stopPrank();

        uint256 numberOfOwnersBefore = aggr3Oracle.numOwners();

        vm.startPrank(secondOwner);
        aggr3Oracle.oppose(ownerToRemove);
        aggr3Oracle.remove(ownerToRemove);

        uint256 numberOfOwnersAfter = aggr3Oracle.numOwners();

        assertEq(numberOfOwnersAfter, numberOfOwnersBefore - 1);
    }

    function testRemoveWhileSupportingSomeone() public {
        address secondOwner = users[1];
        address ownerToRemove = users[2];
        address firstUserToSupport = users[3];
        address secondUserToSupport = users[4];

        vm.startPrank(owner);
        aggr3Oracle.support(secondOwner);
        aggr3Oracle.add(secondOwner);

        aggr3Oracle.support(ownerToRemove);
        vm.stopPrank();

        vm.startPrank(secondOwner);
        aggr3Oracle.support(ownerToRemove);
        aggr3Oracle.add(ownerToRemove);
        vm.stopPrank();

        vm.startPrank(ownerToRemove);
        aggr3Oracle.support(firstUserToSupport);
        aggr3Oracle.support(secondUserToSupport);
        vm.stopPrank();

        vm.startPrank(owner);
        aggr3Oracle.oppose(ownerToRemove);
        vm.stopPrank();

        uint256 numberOfOwnersBefore = aggr3Oracle.numOwners();

        vm.startPrank(secondOwner);

        aggr3Oracle.oppose(ownerToRemove);
        aggr3Oracle.remove(ownerToRemove);

        uint256 numberOfOwnersAfter = aggr3Oracle.numOwners();

        assertEq(numberOfOwnersAfter, numberOfOwnersBefore - 1);
    }

    function testOppose() public {
        console.log("Should oppose user when called by owner");

        address nonOwner = users[1];
        vm.startPrank(owner);
        aggr3Oracle.support(nonOwner);
        aggr3Oracle.add(nonOwner);

        uint256 oppossingCounterBefore = aggr3Oracle.oppositionCounter(
            nonOwner
        );

        aggr3Oracle.oppose(nonOwner);
        vm.stopPrank();

        uint256 opposingCounterAfter = aggr3Oracle.oppositionCounter(nonOwner);

        assertEq(opposingCounterAfter, oppossingCounterBefore + 1);
        assertEq(aggr3Oracle.opposing(owner, 0), nonOwner);
        assertTrue(aggr3Oracle.opposers(nonOwner, owner));
    }

    function testOpposeRevertAlreadyOpposing() public {
        console.log("Should fail when already opposing");

        address nonOwner = users[1];
        vm.startPrank(owner);
        aggr3Oracle.support(nonOwner);
        aggr3Oracle.add(nonOwner);
        aggr3Oracle.oppose(nonOwner);

        vm.expectRevert(abi.encodePacked("already opposing"));
        aggr3Oracle.oppose(nonOwner);
        vm.stopPrank();
    }

    function testUnoppose() public {
        console.log("Should unoppose owner when called by the owner");

        address nonOwner = users[1];
        vm.startPrank(owner);
        aggr3Oracle.support(nonOwner);
        aggr3Oracle.add(nonOwner);
        aggr3Oracle.oppose(nonOwner);

        uint256 oppositionCounterBefore = aggr3Oracle.oppositionCounter(
            nonOwner
        );
        aggr3Oracle.unoppose(nonOwner);
        vm.stopPrank();

        uint256 oppositionCounterAfter = aggr3Oracle.oppositionCounter(
            nonOwner
        );

        assertEq(oppositionCounterAfter, oppositionCounterBefore - 1);
        assertTrue(!aggr3Oracle.opposers(nonOwner, owner));

        vm.expectRevert();
        aggr3Oracle.opposing(owner, 0);
    }

    function testUnoppose(address user) public {
        console.log("Should handle fuzzing");

        vm.assume(user != owner);

        address nonOwner = user;
        vm.startPrank(owner);
        aggr3Oracle.support(nonOwner);
        aggr3Oracle.add(nonOwner);
        aggr3Oracle.oppose(nonOwner);

        uint256 oppositionCounterBefore = aggr3Oracle.oppositionCounter(
            nonOwner
        );
        aggr3Oracle.unoppose(nonOwner);
        vm.stopPrank();

        uint256 oppositionCounterAfter = aggr3Oracle.oppositionCounter(
            nonOwner
        );

        assertEq(oppositionCounterAfter, oppositionCounterBefore - 1);
        assertTrue(!aggr3Oracle.opposers(nonOwner, owner));

        vm.expectRevert();
        aggr3Oracle.opposing(owner, 0);
    }

    function testWriteDataDifferentOwners() public {
        address secondOwner = users[1];
        address thirdOwner = users[2];

        vm.startPrank(owner);
        aggr3Oracle.support(secondOwner);
        aggr3Oracle.add(secondOwner);
        aggr3Oracle.support(thirdOwner);
        vm.stopPrank();

        vm.startPrank(secondOwner);
        aggr3Oracle.support(thirdOwner);
        aggr3Oracle.add(thirdOwner);
        vm.stopPrank();

        vm.startPrank(owner);
        aggr3Oracle.writeData(10);
        vm.stopPrank();

        vm.startPrank(secondOwner);
        aggr3Oracle.writeData(20);
        vm.stopPrank();

        vm.startPrank(thirdOwner);
        aggr3Oracle.writeData(30);
        aggr3Oracle.acceptTermsOfService();
        uint256 medianValue = aggr3Oracle.readData();
        assertEq(medianValue, 20, "Should calculate the correct median value");
        vm.stopPrank();
    }

    function testWriteDataSameOwner() public {
        vm.startPrank(owner);
        aggr3Oracle.writeData(10);
        aggr3Oracle.writeData(20);
        aggr3Oracle.writeData(30);
        aggr3Oracle.acceptTermsOfService();
        uint256 dataValue = aggr3Oracle.readData();
        assertEq(
            dataValue,
            30,
            "Should store the most recent value from the same owner"
        );
        vm.stopPrank();
    }

    function testReadDataWithoutEnoughData() public {
        address secondOwner = users[1];

        vm.startPrank(owner);
        aggr3Oracle.support(secondOwner);
        aggr3Oracle.add(secondOwner);
        vm.stopPrank();

        vm.startPrank(owner);
        aggr3Oracle.writeData(10);
        vm.stopPrank();

        vm.startPrank(secondOwner);
        aggr3Oracle.writeData(20);
        aggr3Oracle.acceptTermsOfService();
        uint256 medianValue = aggr3Oracle.readData();
        assertEq(medianValue, 15, "Should calculate the correct median value");
        vm.stopPrank();
    }

    function testReadDataWith3OraclesData() public {
        address secondOwner = users[1];
        address thirdOwner = users[2];

        vm.startPrank(owner);
        aggr3Oracle.support(secondOwner);
        aggr3Oracle.add(secondOwner);
        aggr3Oracle.support(thirdOwner);
        vm.stopPrank();

        vm.startPrank(secondOwner);
        aggr3Oracle.support(thirdOwner);
        aggr3Oracle.add(thirdOwner);
        vm.stopPrank();

        vm.startPrank(owner);
        aggr3Oracle.writeData(10);
        vm.stopPrank();

        vm.startPrank(secondOwner);
        aggr3Oracle.writeData(20);
        vm.stopPrank();

        vm.startPrank(thirdOwner);
        aggr3Oracle.writeData(30);
        aggr3Oracle.acceptTermsOfService();
        uint256 medianValue = aggr3Oracle.readData();
        assertEq(medianValue, 20, "Should calculate the correct median value");
        vm.stopPrank();
    }

    function testWriteDataFourDifferentOwners() public {
        address secondOwner = users[1];
        address thirdOwner = users[2];
        address fourthOwner = users[3];

        vm.startPrank(owner);
        aggr3Oracle.support(secondOwner);
        aggr3Oracle.add(secondOwner);
        aggr3Oracle.support(thirdOwner);
        vm.stopPrank();

        vm.startPrank(secondOwner);
        aggr3Oracle.support(thirdOwner);
        aggr3Oracle.add(thirdOwner);
        aggr3Oracle.support(fourthOwner);
        vm.stopPrank();

        vm.startPrank(thirdOwner);
        aggr3Oracle.support(fourthOwner);
        aggr3Oracle.add(fourthOwner);
        vm.stopPrank();

        vm.startPrank(owner);
        aggr3Oracle.writeData(10);
        vm.stopPrank();

        vm.startPrank(secondOwner);
        aggr3Oracle.writeData(20);
        vm.stopPrank();

        vm.startPrank(thirdOwner);
        aggr3Oracle.writeData(30);
        vm.stopPrank();

        vm.startPrank(fourthOwner);
        aggr3Oracle.writeData(40);
        aggr3Oracle.acceptTermsOfService();
        uint256 medianValue = aggr3Oracle.readData();
        assertEq(medianValue, 30, "Should calculate the correct median value");
        vm.stopPrank();
    }

    function testWriteDataFourDifferentOwnersAndOneMultipleTimes() public {
        address secondOwner = users[1];
        address thirdOwner = users[2];
        address fourthOwner = users[3];

        vm.startPrank(owner);
        aggr3Oracle.support(secondOwner);
        aggr3Oracle.add(secondOwner);
        aggr3Oracle.support(thirdOwner);
        vm.stopPrank();

        vm.startPrank(secondOwner);
        aggr3Oracle.support(thirdOwner);
        aggr3Oracle.add(thirdOwner);
        aggr3Oracle.support(fourthOwner);
        vm.stopPrank();

        vm.startPrank(thirdOwner);
        aggr3Oracle.support(fourthOwner);
        aggr3Oracle.add(fourthOwner);
        vm.stopPrank();

        vm.startPrank(owner);
        aggr3Oracle.writeData(10);
        vm.stopPrank();

        vm.startPrank(secondOwner);
        aggr3Oracle.writeData(20);
        vm.stopPrank();

        vm.startPrank(thirdOwner);
        aggr3Oracle.writeData(30);
        vm.stopPrank();

        vm.startPrank(owner);
        aggr3Oracle.writeData(40);
        aggr3Oracle.writeData(50);
        aggr3Oracle.writeData(60);
        vm.stopPrank();

        vm.startPrank(fourthOwner);
        aggr3Oracle.writeData(40);
        aggr3Oracle.acceptTermsOfService();
        uint256 medianValue = aggr3Oracle.readData();
        assertEq(medianValue, 40, "Should calculate the correct median value");
        vm.stopPrank();
    }
}
