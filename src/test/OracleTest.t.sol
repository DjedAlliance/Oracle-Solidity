// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../MultiOwnable.sol";
import "../Oracle.sol";
import {Utilities} from "./utils/Utilities.sol";
import {DSTest} from "ds-test/test.sol";
import {Vm} from "forge-std/Vm.sol";
import {BaseSetup} from "./BaseSetup(Oracle).sol";

contract OracleTest is BaseSetup
{
    Oracle internal oracle;
    function setUp() public override
    {
        super.setUp ();
        vm.prank(owner);
        oracle = new Oracle (owner, "MyOracle", 600, 100);
        vm.stopPrank();
    }

    function testWriteData () public 
    {
        console.log ("Should write the data and set the latest cost");
        vm.startPrank(owner);
        oracle.writeData(1, 200);
        assertEq(oracle.getTotalCost(), 200);
    }

    function testReadDataNoCredit () public
    {
        console.log ("Reader should get warning for not enough credit");
        vm.startPrank (owner);
        oracle.writeData(1, 200);
        vm.stopPrank ();
        vm.startPrank (reader);
        vm.expectRevert (abi.encodePacked ("Insufficient credit"));
        uint data = oracle.readData ();
        vm.stopPrank();
    }

    function testReadDataSomeCredit () public
    {
        console.log ("Reader should get warning for not enough credit");
        vm.startPrank (owner);
        oracle.writeData(1, 200);
        vm.stopPrank ();
        vm.startPrank (reader);
        oracle.depositCredit {value : 50} (reader);
        assertEq (oracle.totalCredit (), 50);
        vm.expectRevert (abi.encodePacked ("Insufficient credit"));
        uint data = oracle.readData ();
        vm.stopPrank();
    }

    function testReadDataFullCredit () public
    {
        console.log ("Reader should get the data");
        vm.startPrank (owner);
        oracle.writeData(1, 200);
        vm.stopPrank ();
        vm.startPrank (reader);
        oracle.depositCredit {value : 150} (reader);
        assertEq (oracle.totalCredit (), 150);
        uint data = oracle.readData ();
        vm.stopPrank ();
        vm.startPrank (owner);
        uint totalRevenue = oracle.getTotalRevenue ();
        assertEq (data, 1);
        assertEq (totalRevenue, 100); 
        vm.stopPrank();
    }

    function testReaderPaysOnceBetweenWrites () public
    {
        uint data;
        uint totalRevenue;
        uint feeReader;
        uint latestWrite;
        uint latestRead;
        console.log ("Reader should pay only once");
        vm.startPrank (owner);
        oracle.writeData (1, 200);
        vm.stopPrank ();
        vm.startPrank (reader);
        oracle.depositCredit {value : 150} (reader);
        // Reading the first time
        feeReader = oracle.feeOf(reader);
        data = oracle.readData ();

        // Reading the second time
        latestWrite = oracle.latestWrite ();
        vm.stopPrank ();
        vm.startPrank (owner);
        latestRead = oracle.getLatestRead (reader);
        vm.stopPrank ();
        vm.startPrank (reader);
        feeReader = oracle.feeOf(reader);
        data = oracle.readData();
        assertEq (data, 1);
        vm.stopPrank ();
        vm.startPrank (owner);
        totalRevenue = oracle.getTotalRevenue ();
        assertEq (totalRevenue, 100);
        vm.stopPrank ();
    }

    function testAdjustBaseFee () public
    {
        uint data;
        uint totalRevenue;
        uint totalCost;
        console.log ("Testing if the adjust base fee works the way it supposed to");
        vm.startPrank (owner);
        oracle.writeData (1, 200);
        changePrank (reader);
        oracle.depositCredit {value : 1000} (reader);
        data = oracle.readData ();
        changePrank (owner);
        oracle.writeData (2, 50);
        changePrank (reader);
        data = oracle.readData ();
        changePrank (owner);
        oracle.adjustBaseFee ();
        

        changePrank (owner);
        oracle.writeData (3, 50);
        changePrank (reader);
        data = oracle.readData ();
        changePrank (owner);
        oracle.writeData (2, 50);
        changePrank (reader);
        data = oracle.readData ();
        oracle.adjustBaseFee ();

        changePrank (owner);
        totalCost = oracle.getTotalCost ();
        totalRevenue = oracle.getTotalRevenue ();
        assertEq (totalRevenue, totalCost);
    }



}
