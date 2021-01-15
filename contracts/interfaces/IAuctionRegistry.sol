// SPDX-License-Identifier: LGPL-3.0-or-newer
pragma solidity >=0.6.8;

interface IAuctionRegistry {
    function isModuleActive(address auctionModule) external view returns (bool);

    function isModuleApproved(address auctionModule)
        external
        view
        returns (bool);
}
