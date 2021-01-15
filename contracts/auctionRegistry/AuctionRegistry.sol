// SPDX-License-Identifier: LGPL-3.0-or-newer
pragma solidity >=0.6.8;
import "../interfaces/IIdoCreator.sol";

contract AuctionRegistry {
    event NewModule(address indexed module);
    event ApprovedModule(address indexed module);
    event RemovedModule(address indexed module);

    IIdoCreator public idoCreator;
    mapping(address => bool) public moduleActive;
    mapping(address => bool) public moduleApproved;

    modifier onlyCurator {
        require(
            msg.sender == idoCreator.moduleCurator(),
            "AuctionRegistry: FORBIDDEN"
        );
        _;
    }

    constructor(IIdoCreator _idoCreator) public {
        idoCreator = _idoCreator;
    }

    function registerModule(address auctionModule) external {
        moduleActive[auctionModule] = true;
        emit NewModule(auctionModule);
    }

    function approveModule(address auctionModule) external onlyCurator {
        moduleApproved[auctionModule] = true;
        emit ApprovedModule(auctionModule);
    }

    function removeModule(address auctionModule) external onlyCurator {
        moduleApproved[auctionModule] = false;
        moduleActive[auctionModule] = false;
        emit RemovedModule(auctionModule);
    }

    function isModuleActive(address auctionModule)
        external
        view
        returns (bool)
    {
        return moduleActive[auctionModule];
    }

    function isModuleApproved(address auctionModule)
        external
        view
        returns (bool)
    {
        return moduleApproved[auctionModule];
    }
}
