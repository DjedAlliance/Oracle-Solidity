// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;
import {console} from "./test/utils/Console.sol";

contract MultiOwnable {
    uint256 public numOwners;
    mapping(address => bool) public owner;
    mapping(address => uint256) public supportCounter;
    mapping(address => uint256) public oppositionCounter;
    mapping(address => mapping(address => bool)) public supporters; // address => addresses of owners who support the address being an owner
    mapping(address => mapping(address => bool)) public opposers; // address => addresses of owners who oppose the address being an owner
    mapping(address => address[]) public supporting; // owner => addresses that the owner is supporting
    mapping(address => address[]) public opposing; // owner => addresses that the owner is opposing

    event OwnerAdded(address a);
    event OwnerRemoved(address a);
    event SupportAdded(address a, address supporter);
    event OppositionAdded(address a, address opposer);
    event SupportRemoved(address a, address supporter);
    event OppositionRemoved(address a, address opposer);

    modifier onlyOwner() {
        require(owner[msg.sender], "Unauthorized");
        _;
    }
    modifier isOwner(address a) {
        require(owner[a], "address is not an owner");
        _;
    }
    modifier isNotOwner(address a) {
        require(!owner[a], "address is already an owner");
        _;
    }

    constructor(address initialOwner) {
        numOwners = 1;
        owner[initialOwner] = true;
    }

    function add(address a) external isNotOwner(a) {
        require(supportCounter[a] > numOwners / 2, "Insufficient quorum");
        numOwners += 1;
        owner[a] = true;
        emit OwnerAdded(a);
    }

    function remove(address a) external isOwner(a) {
        require(oppositionCounter[a] > numOwners / 2, "Insufficient quorum");
        numOwners -= 1;
        for (uint256 i = 0; i < supporting[a].length; i++)
            _unsupport(supporting[a][i], a);

        delete supporting[a];

        for (uint256 i = 0; i < opposing[a].length; i++)
            _unoppose(opposing[a][i], a);

        delete opposing[a];

        owner[a] = false;
        emit OwnerRemoved(a);
    }

    function support(address a) external onlyOwner {
        require(!supporters[a][msg.sender], "already supporting");
        supportCounter[a] += 1;
        supporters[a][msg.sender] = true;
        supporting[msg.sender].push(a);
        _unoppose(a, msg.sender); // When owner starts supporting `a`, it will automatically stop opposing `a`
        emit SupportAdded(a, msg.sender);
    }

    function oppose(address a) external onlyOwner {
        require(!opposers[a][msg.sender], "already opposing");
        oppositionCounter[a] += 1;
        opposers[a][msg.sender] = true;
        opposing[msg.sender].push(a);
        _unsupport(a, msg.sender); // When owner starts opposing `a`, it will automatically stop supporting `a`
        emit OppositionAdded(a, msg.sender);
    }

    function unsupport(address a) external onlyOwner {
        _unsupport(a, msg.sender);
    }

    function _unsupport(address a, address _owner) internal {
        if (supporters[a][_owner]) {
            supportCounter[a] -= 1;
            supporters[a][_owner] = false;
            deleteElement(supporting[_owner], a);
            emit SupportRemoved(a, _owner);
        }
    }

    function unoppose(address a) external onlyOwner {
        _unoppose(a, msg.sender);
    }

    function _unoppose(address a, address _owner) internal {
        if (opposers[a][_owner]) {
            oppositionCounter[a] -= 1;
            opposers[a][_owner] = false;
            deleteElement(opposing[msg.sender], a);
            emit OppositionRemoved(a, _owner);
        }
    }

    function deleteElement(address[] storage array, address a) private {
        uint256 index = 0;

        while (array[index] != a && index < array.length) {
            index++;
        }

        array[index] = array[array.length - 1];
        array.pop();
    }
}
