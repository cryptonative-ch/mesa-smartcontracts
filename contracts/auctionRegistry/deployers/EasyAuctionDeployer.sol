// SPDX-License-Identifier: LGPL-3.0-or-newer
pragma solidity >=0.6.8;
import "../modules/EasyAuction.sol";

contract AuctionDeployer {
    function deploy(address _idoManager) external returns (address) {
        EasyAuction deployedContract = new EasyAuction();
        return address(deployedContract);
    }
}
