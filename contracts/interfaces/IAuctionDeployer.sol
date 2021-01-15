// SPDX-License-Identifier: LGPL-3.0-or-newer
pragma solidity >=0.6.8;

interface IAuctionDeployer {
    function deploy(address _idoManager) external view returns (address);
}
