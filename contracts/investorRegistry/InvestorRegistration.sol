// SPDX-License-Identifier: LGPL-3.0-or-newer
pragma solidity >=0.6.8;

contract InvestorRegistration {
    mapping(uint256 => mapping(address => bool)) public addressApproved;

    event NewInvestorRegistry(
        uint256 indexed registryIndex,
        address indexed accreditionManager
    );

    event ApprovedAccounts(uint256 registryIndex, address[] accounts);

    event RemovedAccounts(uint256 registryIndex, address[] accounts);

    uint256 public registryCount;
    mapping(uint256 => address) public accreditionManager;

    modifier onlyAccreditionManager(uint256 _index) {
        require(
            msg.sender == accreditionManager[_index],
            "AuctionRegistry: FORBIDDEN"
        );
        _;
    }

    function createRegistry(address _accreditionManager)
        external
        returns (uint256)
    {
        uint256 registryIndex = registryCount;
        accreditionManager[registryIndex] = _accreditionManager;
        registryCount++;
        emit NewInvestorRegistry(registryIndex, _accreditionManager);
    }

    function approveAccounts(uint256 registryIndex, address[] calldata accounts)
        external
        onlyAccreditionManager(registryIndex)
    {
        for (uint256 i = 0; i < accounts.length; i++) {
            addressApproved[registryIndex][accounts[i]] = true;
        }
        emit ApprovedAccounts(registryIndex, accounts);
    }

    function removeAccounts(uint256 registryIndex, address[] calldata accounts)
        external
        onlyAccreditionManager(registryIndex)
    {
        for (uint256 i = 0; i < accounts.length; i++) {
            addressApproved[registryIndex][accounts[i]] = false;
        }
        emit RemovedAccounts(registryIndex, accounts);
    }

    function updateAccreditionManager(
        uint256 registryIndex,
        address newAccreditionMananger
    ) external onlyAccreditionManager(registryIndex) {
        accreditionManager[registryIndex] = newAccreditionMananger;
    }

    function isAddressApproved(uint256 registryIndex, address who)
        external
        view
        returns (bool)
    {
        return addressApproved[registryIndex][who];
    }
}
