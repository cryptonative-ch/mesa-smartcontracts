// SPDX-License-Identifier: LGPL-3.0-or-newer
pragma solidity >=0.6.8;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract EasyAuction {
    event NewSellOrder(
        uint256 indexed auctionId,
        uint64 indexed userId,
        uint96 buyAmount,
        uint96 sellAmount
    );
    event CancellationSellOrder(
        uint256 indexed auctionId,
        uint64 indexed userId,
        uint96 buyAmount,
        uint96 sellAmount
    );
    event ClaimedFromOrder(
        uint256 indexed auctionId,
        uint64 indexed userId,
        uint96 buyAmount,
        uint96 sellAmount
    );
    event NewUser(uint64 indexed userId, address indexed userAddress);
    event NewAuction(
        uint256 indexed auctionId,
        IERC20 indexed _auctioningToken,
        IERC20 indexed _biddingToken,
        uint256 orderCancellationEndDate,
        uint256 auctionEndDate,
        uint96 _auctionedSellAmount,
        uint96 _minBuyAmount,
        uint256 minimumBiddingAmountPerOrder,
        uint256 minFundingThreshold
    );
    event AuctionCleared(
        uint256 indexed auctionId,
        uint96 priceNumerator,
        uint96 priceDenominator
    );
    event UserRegistration(address indexed user, uint64 userId);

    function emitNewSellOrder(
        uint256 auctionId,
        uint64 userId,
        uint96 buyAmount,
        uint96 sellAmount
    ) public {
        emit NewSellOrder(auctionId, userId, buyAmount, sellAmount);
    }

    function emitCancellationSellOrder(
        uint256 auctionId,
        uint64 userId,
        uint96 buyAmount,
        uint96 sellAmount
    ) public {
        emit CancellationSellOrder(auctionId, userId, buyAmount, sellAmount);
    }

    function emitClaimedFromOrder(
        uint256 auctionId,
        uint64 userId,
        uint96 buyAmount,
        uint96 sellAmount
    ) public {
        emit ClaimedFromOrder(auctionId, userId, buyAmount, sellAmount);
    }

    function emitNewUser(uint64 userId, address userAddress) public {
        emit NewUser(userId, userAddress);
    }

    function emitNewAuction(
        uint256 auctionId,
        IERC20 _auctioningToken,
        IERC20 _biddingToken,
        uint256 orderCancellationEndDate,
        uint256 auctionEndDate,
        uint96 _auctionedSellAmount,
        uint96 _minBuyAmount,
        uint256 minimumBiddingAmountPerOrder,
        uint256 minFundingThreshold
    ) public {
        emit NewAuction(
            auctionId,
            _auctioningToken,
            _biddingToken,
            orderCancellationEndDate,
            auctionEndDate,
            _auctionedSellAmount,
            _minBuyAmount,
            minimumBiddingAmountPerOrder,
            minFundingThreshold
        );
    }

    function emitAuctionCleared(
        uint256 auctionId,
        uint96 priceNumerator,
        uint96 priceDenominator
    ) public {
        emit AuctionCleared(auctionId, priceNumerator, priceDenominator);
    }

    function emitUserRegistration(address user, uint64 userId) public {
        emit UserRegistration(user, userId);
    }
}
