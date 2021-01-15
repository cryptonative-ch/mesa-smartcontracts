// SPDX-License-Identifier: LGPL-3.0-or-newer
pragma solidity >=0.6.8;

interface IEasyAuctionFactory {
    function auctionWhitelist() external view returns (address);

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function setFeeTo(address _feeTo) external pure returns (address);

    function setFeeToSetter(address _feeToSetter)
        external
        pure
        returns (address);
}
