// SPDX-License-Identifier: LGPL-3.0-or-newer
pragma solidity >=0.6.8;

interface IIdoCreator {
    function feeTo() external pure returns (address);

    function feeManager() external pure returns (address);

    function moduleCurator() external pure returns (address);

    function feeNumerator() external pure returns (uint256);
}
