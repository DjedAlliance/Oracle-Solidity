// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

import "forge-std/Test.sol";
import {Utilities} from "./utils/Utilities.sol";
import {Vm} from "forge-std/Vm.sol";
import {Oracle} from "../Oracle.sol";
import {MultiOwnable} from "../MultiOwnable.sol";

contract BaseSetup is Test
{
    Utilities internal utils;
    address payable[] internal users;
    address internal owner;
    address internal reader;

    function setUp() public virtual 
    {
        utils = new Utilities ();
        users = utils.createUsers (2);
        owner = users [0];
        vm.label(owner, "Owner");
        reader = users [1];
        vm.label(reader, "Reader");
    }
}
