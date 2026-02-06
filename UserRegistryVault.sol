// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract UserRegistryVault {
    //STATE VARIABLE
    // Address of the contract owner (admin)
    address public owner;

    // Total ETH deposited into the vault
    uint256 public totalDeposits;

    //CONSTRUCTOR

    constructor() {
        owner = msg.sender;
    }

    //2) Struct + Mapping + Enum
    enum Status {
        Active,
        Suspended,
        Banned
    }

    // Represents a registered user in the system
    struct User {
        uint256 balance;     
        Status status;       
        uint256 createdAt;   
    }

    //3) Modifiers

    error NotOwner();
    error NotActive();

    // Maps user address to their User data
    mapping(address => User) private users;

    // Restricts function access to the contract owner
    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert NotOwner();
        }
        _;
    }

    // Restricts function access to active users only
    modifier onlyActiveUser() {
        if (users[msg.sender].status != Status.Active) {
            revert NotActive();
        }
        _;
    }

    //4) Functions (Public + Internal)

    // Registering new user
    function registerUser() external {
        require(users[msg.sender].createdAt == 0, "Already registered");

        users[msg.sender] = User({
            balance: 0,
            status: Status.Active,
            createdAt: block.timestamp
        });
    }

    // Depositing ETH into the vault
    function deposit() external payable onlyActiveUser {
        require(msg.value > 0, "Zero deposit");

        users[msg.sender].balance += msg.value;
        totalDeposits += msg.value;
    }

    error InsufficientBalance();  //! @dev move this to the top,
    // Withdrawing ETH from the vault
    // @dev good CEI pattern
    function withdraw(uint256 amount) external onlyActiveUser {
        if (users[msg.sender].balance < amount) {
            revert InsufficientBalance();
        }

        users[msg.sender].balance -= amount;
        totalDeposits -= amount;

        _safeTransfer(msg.sender, amount); //@dev good use of safe transfer
    }

    // For viewing the user data
    function getUser(address user)
        external
        view
        returns (User memory)
    {
        return users[user];
    }

    // OWNER FUNCTIONS(user status (Active / Suspended / Banned)
    function setStatus(address user, Status newStatus)
        external
        onlyOwner //@dev great
    {
        require(users[user].createdAt != 0, "User not registered");
        users[user].status = newStatus;
    }
    //INTERNAL FUNCTIONS
    // Transfer ETH
    function _safeTransfer(address to, uint256 amount) internal {
        (bool success, ) = to.call{value: amount}("");
        require(success, "ETH transfer failed");
    }

    //ERROR DEMONSTRATION
    // @dev this is good but next time include within the functions you are writing
    function failWithRequire() external pure {
        require(false, "Require failed");
    }

    function failWithRevert() external pure {
        revert("Revert failed");
    }

    function failWithAssert() external pure {
        assert(false);
    }

}

