// SPDX-License-Identifier: LGPL-3.0-or-newer
pragma solidity >=0.6.8;

interface IAuctionWhitelist {
    function createWhitelist() external pure returns (uint256);
}
