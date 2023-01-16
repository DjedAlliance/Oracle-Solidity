// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

import {DSTest} from "ds-test/test.sol";
import {Utilities} from "./utils/Utilities.sol";
import {console} from "./utils/Console.sol";
import {Vm} from "forge-std/Vm.sol";
import {SimpleOracle} from "../SimpleOracle.sol";

contract BaseSetup is DSTest {
    Vm internal immutable vm = Vm(HEVM_ADDRESS);

    Utilities internal utils;
    address payable[] internal users;
    address internal owner;
    address internal nonOwner;
    address internal reader;
    address internal nonReader;
    address internal userToSupport;
    address internal secondUserToSupport;

    function setUp() public virtual {
        utils = new Utilities();
        users = utils.createUsers(6);

        owner = users[0];
        vm.label(owner, "Owner");
        nonOwner = users[1];
        vm.label(nonOwner, "NonOwner");
        reader = users[2];
        vm.label(nonOwner, "Reader");
        nonReader = users[3];
        vm.label(nonOwner, "NonReader");
        userToSupport = users[4];
        vm.label(userToSupport, "User to support");
        secondUserToSupport = users[5];
        vm.label(userToSupport, "Second user to support");
    }
}
