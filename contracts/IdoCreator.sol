// SPDX-License-Identifier: LGPL-3.0-or-newer
pragma solidity >=0.6.8;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "./interfaces/IAuctionRegistry.sol";
import "./interfaces/IAuctionDeployer.sol";

contract IdoCreator {
    using SafeERC20 for IERC20;

    event AuctionCreated(address indexed auction);

    IAuctionRegistry public auctionRegistry;
    uint256 public feeNumerator;
    address[] public allAuctions;
    address public feeTo;
    address public feeManager;
    address public moduleCurator;
    address public investorRegistry;

    constructor(
        address _investorRegistry,
        IAuctionRegistry _auctionRegistry,
        address _moduleCurator,
        address _feeManager,
        address _feeTo,
        uint256 _feeNumerator
    ) public {
        investorRegistry = _investorRegistry;
        auctionRegistry = _auctionRegistry;
        moduleCurator = _moduleCurator;
        feeManager = _feeManager;
        feeTo = _feeTo;
        feeNumerator = _feeNumerator;
    }

    function createAuction(address _auctionModule, address _idoManager) external {
        require(
            auctionRegistry.isModuleActive(_auctionModule),
            "EasyAuctionFactory: INACTIVE_MODULE"
        );
        address idoContract = IAuctionDeployer(_auctionModule).deploy(_idoManager);
        allAuctions.push(idoContract);
        emit AuctionCreated(idoContract);
    }

    function setFeeTo(address _feeTo) external {
        require(msg.sender == feeManager, "EasyAuctionFactory: FORBIDDEN");
        feeTo = _feeTo;
    }

    function setFeeNumerator(uint256 _feeNumerator) external {
        require(msg.sender == feeManager, "EasyAuctionFactory: FORBIDDEN");
        feeNumerator = _feeNumerator;
    }

    function setFeeManager(address _feeManager) external {
        require(msg.sender == feeManager, "EasyAuctionFactory: FORBIDDEN");
        feeManager = _feeManager;
    }

    function setModuleCurator(address _moduleCurator) external {
        require(msg.sender == moduleCurator, "EasyAuctionFactory: FORBIDDEN");
        moduleCurator = _moduleCurator;
    }

    function allAuctionsLength() external view returns (uint256) {
        return allAuctions.length;
    }
}
