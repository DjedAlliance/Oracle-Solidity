// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

import {DSTest} from "ds-test/test.sol";
import {Utilities} from "./utils/Utilities.sol";
import {console} from "./utils/Console.sol";
import {Vm} from "forge-std/Vm.sol";
import {SimpleOracle} from "../SimpleOracle.sol";
import {BaseSetup} from "./BaseSetup.sol";

contract SimpleOracleTest is BaseSetup {
    SimpleOracle internal simpleOracle;

    function setUp() public override {
        super.setUp();

        vm.prank(owner);
        simpleOracle = new SimpleOracle(
            owner,
            "Description",
            "Terms of service"
        );
        vm.stopPrank();
    }

    function testAcceptTermsOfService() public {
        console.log("Should accept terms of service");

        vm.startPrank(owner);
        simpleOracle.acceptTermsOfService();

        bool accepted = simpleOracle.acceptedTermsOfService(owner);
        assertTrue(accepted);
    }

    function testWriteAndReadData() public {
        console.log("Should set the data when called by the owner");

        vm.startPrank(owner);
        simpleOracle.writeData(1000);

        simpleOracle.acceptTermsOfService();

        uint256 dataAfterWrite = simpleOracle.readData();
        assertEq(dataAfterWrite, 1000);
        vm.stopPrank();
    }

    function testWriteDataRevertIfNotOwner() public {
        console.log("Should fail to set data when caller is not the owner");

        vm.startPrank(nonOwner);
        vm.expectRevert(abi.encodePacked("Unauthorized"));
        simpleOracle.writeData(1000);
        vm.stopPrank();
    }

    function testReadDataRevertIfNotAcceptedTermsOfService() public {
        console.log(
            "Should fail to read data when caller did not accept terms of service"
        );

        vm.startPrank(owner);
        vm.expectRevert(abi.encodePacked("Terms of Service not accepted"));
        simpleOracle.readData();
        vm.stopPrank();
    }

    function testWriteDataWithFuzzing(uint256 value) public {
        console.log("Should handle fuzzing");

        vm.startPrank(owner);
        simpleOracle.writeData(value);

        simpleOracle.acceptTermsOfService();

        uint256 dataAfterWrite = simpleOracle.readData();
        assertEq(dataAfterWrite, value);
        vm.stopPrank();
    }

    function testSupport() public {
        console.log("Should support non owner when called by the owner");
        address nonOwner = users[1];
        uint256 supportCounterBefore = simpleOracle.supportCounter(nonOwner);

        vm.startPrank(owner);
        simpleOracle.support(nonOwner);
        vm.stopPrank();

        uint256 supportCounterAfter = simpleOracle.supportCounter(nonOwner);

        assertEq(supportCounterAfter, supportCounterBefore + 1);
        assertEq(simpleOracle.supporting(owner, 0), nonOwner);
        assertTrue(simpleOracle.supporters(nonOwner, owner));
    }

    function testSupportRevertIfNotOwner() public {
        console.log("Should fail when caller is not the owner");

        address firstNonOwner = users[1];
        address secondNonOwner = users[2];

        vm.startPrank(firstNonOwner);
        vm.expectRevert(abi.encodePacked("Unauthorized"));

        simpleOracle.support(secondNonOwner);
        vm.stopPrank();
    }

    function testSupportRevertIfAlreadyOwner() public {
        console.log("Should fail when caller is not the owner");

        vm.startPrank(owner);
        vm.expectRevert(abi.encodePacked("address is already an owner"));

        simpleOracle.support(owner);
        vm.stopPrank();
    }

    function testSupportRevertAlreadySupporting() public {
        console.log("Should fail to support when already supporting");

        address nonOwner = users[1];
        vm.startPrank(owner);
        simpleOracle.support(nonOwner);

        vm.expectRevert(abi.encodePacked("already supporting"));
        simpleOracle.support(nonOwner);

        vm.stopPrank();
    }

    function testSupportWithFuzzing(address user) public {
        console.log("Should handle fuzzing");

        vm.assume(user != owner);
        vm.startPrank(owner);

        simpleOracle.support(user);
        vm.stopPrank();

        assertEq(simpleOracle.supportCounter(user), 1);
        assertEq(simpleOracle.supporting(owner, 0), user);
        assertTrue(simpleOracle.supporters(user, owner));
    }

    function testUnsupport() public {
        console.log("Should unsupport non owner when called by the owner");

        vm.startPrank(owner);
        address nonOwner = users[1];
        simpleOracle.support(nonOwner);

        uint256 supportCounterBefore = simpleOracle.supportCounter(nonOwner);

        simpleOracle.unsupport(nonOwner);
        vm.stopPrank();

        uint256 supportCounterAfter = simpleOracle.supportCounter(nonOwner);

        assertEq(supportCounterAfter, supportCounterBefore - 1);
        assertTrue(!simpleOracle.supporters(nonOwner, owner));

        vm.expectRevert();
        simpleOracle.supporting(owner, 0);
    }

    function testUnsupportRevertIfNotOwner() public {
        console.log("Should fail when caller is not the owner");

        address firstNonOwner = users[1];
        address secondNonOwner = users[2];

        vm.startPrank(firstNonOwner);
        vm.expectRevert(abi.encodePacked("Unauthorized"));

        simpleOracle.unsupport(secondNonOwner);
        vm.stopPrank();
    }

    function testUnsupportRevertIfAlreadyOwner() public {
        console.log("Should fail when caller is not the owner");

        vm.startPrank(owner);
        vm.expectRevert(abi.encodePacked("address is already an owner"));

        simpleOracle.unsupport(owner);
        vm.stopPrank();
    }

    function testUnsupportWithFuzzing(address user) public {
        console.log("Should handle fuzzing");

        vm.assume(user != owner);
        vm.startPrank(owner);

        simpleOracle.support(user);

        uint256 supportCounterBefore = simpleOracle.supportCounter(user);

        simpleOracle.unsupport(user);
        vm.stopPrank();

        uint256 supportCounterAfter = simpleOracle.supportCounter(user);

        assertEq(supportCounterAfter, supportCounterBefore - 1);
        assertTrue(!simpleOracle.supporters(user, owner));

        vm.expectRevert();
        simpleOracle.supporting(owner, 0);
    }

    function testAdd() public {
        address nonOwner = users[1];

        vm.startPrank(owner);
        simpleOracle.support(nonOwner);
        vm.stopPrank();

        uint256 numOwnersBefore = simpleOracle.numOwners();
        simpleOracle.add(nonOwner);
        uint256 numOwnersAfter = simpleOracle.numOwners();

        assertEq(numOwnersAfter, numOwnersBefore + 1);
        assertTrue(simpleOracle.owner(nonOwner));
    }

    function testAddRevertInsufficientQuorum() public {
        address nonOwner = users[1];

        vm.expectRevert(abi.encodePacked("Insufficient quorum"));
        simpleOracle.add(nonOwner);
    }

    function testRemove() public {
        address secondOwner = users[1];
        address ownerToRemove = users[2];

        vm.startPrank(owner);
        simpleOracle.support(secondOwner);
        simpleOracle.add(secondOwner);

        simpleOracle.support(ownerToRemove);
        vm.stopPrank();

        vm.startPrank(secondOwner);
        simpleOracle.support(ownerToRemove);
        simpleOracle.add(ownerToRemove);
        vm.stopPrank();

        vm.startPrank(owner);
        simpleOracle.oppose(ownerToRemove);
        vm.stopPrank();

        uint256 numberOfOwnersBefore = simpleOracle.numOwners();

        vm.startPrank(secondOwner);
        simpleOracle.oppose(ownerToRemove);
        simpleOracle.remove(ownerToRemove);

        uint256 numberOfOwnersAfter = simpleOracle.numOwners();

        assertEq(numberOfOwnersAfter, numberOfOwnersBefore - 1);
    }

    function testRemoveWhileSupportingSomeone() public {
        address secondOwner = users[1];
        address ownerToRemove = users[2];
        address firstUserToSupport = users[3];
        address secondUserToSupport = users[4];

        vm.startPrank(owner);
        simpleOracle.support(secondOwner);
        simpleOracle.add(secondOwner);

        simpleOracle.support(ownerToRemove);
        vm.stopPrank();

        vm.startPrank(secondOwner);
        simpleOracle.support(ownerToRemove);
        simpleOracle.add(ownerToRemove);
        vm.stopPrank();

        vm.startPrank(ownerToRemove);
        simpleOracle.support(firstUserToSupport);
        simpleOracle.support(secondUserToSupport);
        vm.stopPrank();

        vm.startPrank(owner);
        simpleOracle.oppose(ownerToRemove);
        vm.stopPrank();

        uint256 numberOfOwnersBefore = simpleOracle.numOwners();

        vm.startPrank(secondOwner);

        simpleOracle.oppose(ownerToRemove);
        simpleOracle.remove(ownerToRemove);

        uint256 numberOfOwnersAfter = simpleOracle.numOwners();

        assertEq(numberOfOwnersAfter, numberOfOwnersBefore - 1);
    }

    function testOppose() public {
        console.log("Should oppose user when called by owner");

        address nonOwner = users[1];
        vm.startPrank(owner);
        simpleOracle.support(nonOwner);
        simpleOracle.add(nonOwner);

        uint256 oppossingCounterBefore = simpleOracle.oppositionCounter(
            nonOwner
        );

        simpleOracle.oppose(nonOwner);
        vm.stopPrank();

        uint256 opposingCounterAfter = simpleOracle.oppositionCounter(nonOwner);

        assertEq(opposingCounterAfter, oppossingCounterBefore + 1);
        assertEq(simpleOracle.opposing(owner, 0), nonOwner);
        assertTrue(simpleOracle.opposers(nonOwner, owner));
    }

    function testOpposeRevertNotOwner() public {
        console.log("Should fail when user is not owner");

        address nonOwner = users[1];
        vm.startPrank(owner);

        vm.expectRevert(abi.encodePacked("address is not an owner"));
        simpleOracle.oppose(nonOwner);
        vm.stopPrank();
    }

    function testOpposeRevertAlreadyOpposing() public {
        console.log("Should fail when already opposing");

        address nonOwner = users[1];
        vm.startPrank(owner);
        simpleOracle.support(nonOwner);
        simpleOracle.add(nonOwner);
        simpleOracle.oppose(nonOwner);

        vm.expectRevert(abi.encodePacked("already opposing"));
        simpleOracle.oppose(nonOwner);
        vm.stopPrank();
    }

    function testUnoppose() public {
        console.log("Should unoppose owner when called by the owner");

        address nonOwner = users[1];
        vm.startPrank(owner);
        simpleOracle.support(nonOwner);
        simpleOracle.add(nonOwner);
        simpleOracle.oppose(nonOwner);

        uint256 oppositionCounterBefore = simpleOracle.oppositionCounter(
            nonOwner
        );
        simpleOracle.unoppose(nonOwner);
        vm.stopPrank();

        uint256 oppositionCounterAfter = simpleOracle.oppositionCounter(
            nonOwner
        );

        assertEq(oppositionCounterAfter, oppositionCounterBefore - 1);
        assertTrue(!simpleOracle.opposers(nonOwner, owner));

        vm.expectRevert();
        simpleOracle.opposing(owner, 0);
    }

    function testUnoppose(address user) public {
        console.log("Should handle fuzzing");

        vm.assume(user != owner);

        address nonOwner = user;
        vm.startPrank(owner);
        simpleOracle.support(nonOwner);
        simpleOracle.add(nonOwner);
        simpleOracle.oppose(nonOwner);

        uint256 oppositionCounterBefore = simpleOracle.oppositionCounter(
            nonOwner
        );
        simpleOracle.unoppose(nonOwner);
        vm.stopPrank();

        uint256 oppositionCounterAfter = simpleOracle.oppositionCounter(
            nonOwner
        );

        assertEq(oppositionCounterAfter, oppositionCounterBefore - 1);
        assertTrue(!simpleOracle.opposers(nonOwner, owner));

        vm.expectRevert();
        simpleOracle.opposing(owner, 0);
    }
}
