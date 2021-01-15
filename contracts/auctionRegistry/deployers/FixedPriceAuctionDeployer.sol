// SPDX-License-Identifier: LGPL-3.0-or-newer
pragma solidity >=0.6.8;
import "../modules/FixedPriceAuction.sol";

contract AuctionDeployer {
    function deploy(address _idoManager) external returns (address) {
        FixedPriceAuction deployedContract = new FixedPriceAuction(_idoManager);
        return address(deployedContract);
    }
}
