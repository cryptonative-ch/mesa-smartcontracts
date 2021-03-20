// SPDX-License-Identifier: LGPL-3.0-or-newer
pragma solidity >=0.6.8;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "libraries/IdToAddressBiMap.sol";



contract PointDutch is Ownable {
    using SafeERC20 for IERC20;
    using SafeMath for uint64;
    using SafeMath for uint96;
    using SafeMath for uint256;
    using SafeCast for uint256;
    using IdToAddressBiMap for IdToAddressBiMap.Data;


    modifier atStageSolutionSubmission() {
        {
            uint256 auctionEndDate = auctionEndDate;
            require(
                auctionEndDate != 0 && clearingPriceOrder == bytes32(0),
                "Auction not in solution submission phase"
            );
        }
        _;
    }



    event NewUser(uint64 indexed OwnerId, address indexed userAddress);
    event InitializedAuction(
        IERC20 indexed _tokenIn,
        IERC20 indexed _tokenOut,
        uint256 orderCancellationEndDate,
        uint96 _tokenOutAmount,
        uint96 _minBidAmountToReceive,
        uint256 minimumBiddingAmountPerOrder,
        uint256 minSellThreshold
    );
    event UserRegistration(address indexed user, uint64 bidOwner);

  
    struct Order {
        address ownerId;
        uint96 _orderTokenOut;
        uint96 _orderTokenIn;
    }

    uint256 orderId;
    
    mapping (uint256 => Order) internal orders;

    uint256[] orderIds;


    IERC20 public tokenIn;
    IERC20 public tokenOut;
    uint256 public orderCancellationEndDate;
    uint96 public tokenOutAmount;
    uint96 public minBidAmountToReceive;
    uint256 public minimumBiddingAmountPerOrder;
    uint256 public minSellThreshold;
    uint256 public auctionStartedDate;
    uint256 public auctionEndDate;
    uint256 public interimSumBidAmount;
    bytes32 public clearingPriceOrder;
    uint96 public volumeClearingPriceOrder;
    bool public minSellThresholdNotReached;

    // to be used as ID counter Todo: change name
    uint64 public numUsers;
    // generates id for every address, to save storage space if the same address makes serverall bids
    IdToAddressBiMap.Data private registeredUsers;

    // import from EasyAuction


    bool public isAtomicClosureAllowed;
    uint256 public feeNumerator; // @nico init, bot no set?


    bytes32 public initialAuctionOrder;

    //IterableOrderedOrderSet.Data internal orders;


    constructor() public{}

    // @dev: intiate a new auction
    // Warning: In case the auction is expected to raise more than
    // 2^96 units of the tokenIn, don't start the auction, as
    // it will not be settlable. This corresponds to about 79
    // billion DAI.
    //
    // Prices between tokenIn and tokenOut are expressed by a
    // fraction whose components are stored as uint96.
    function initAuction(
        IERC20 _tokenIn, // nico did swich them in fix priced, old name tokenIn
        IERC20 _tokenOut,
        uint256 _orderCancelationPeriodDuration,
        uint96 _tokenOutAmount, // total amount to sell
        uint96 _minBidAmountToReceive, // Minimum amount of biding token to receive at final point
        uint256 _minimumBiddingAmountPerOrder,
        uint256 _minSellThreshold
    ) public {
        uint64 OwnerId = getOwnerId(msg.sender);

        // deposits _tokenOutAmount + fees
        _tokenOut.safeTransferFrom(
            msg.sender,
            address(this),
            _tokenOutAmount.mul(FEE_DENOMINATOR.add(feeNumerator)).div(
                FEE_DENOMINATOR
            ) //[0]
        );
        require(_tokenOutAmount > 0, "cannot auction zero tokens");
        require(
            _minBidAmountToReceive > 0,
            "tokens cannot be auctioned for free"
        );
        require(
            _minimumBiddingAmountPerOrder > 0,
            "minimumBiddingAmountPerOrder is not allowed to be zero"
        );

        uint256 cancellationEndDate = block.timestamp + _orderCancelationPeriodDuration;

        // arguments
        tokenIn = _tokenIn;
        tokenOut = _tokenOut;
        orderCancellationEndDate = cancellationEndDate;
        tokenOutAmount = _tokenOutAmount;
        minBidAmountToReceive = _minBidAmountToReceive;
        minimumBiddingAmountPerOrder = _minimumBiddingAmountPerOrder;
        minSellThreshold = _minSellThreshold;

        // other init vars
        auctionStartedDate = block.timestamp;
        auctionEndDate = 0;
        interimSumBidAmount = 0;
        clearingPriceOrder = bytes32(0);
        volumeClearingPriceOrder = 0;
        minSellThresholdNotReached = false;
 
        emit InitializedAuction(
            _tokenIn,
            _tokenOut,
            orderCancellationEndDate,
            _tokenOutAmount,
            _minBidAmountToReceive,
            _minimumBiddingAmountPerOrder,
            _minSellThreshold
        );
    }

    // why here? @nico
    uint256 public constant FEE_DENOMINATOR = 1000;
    uint64 public feeReceiverOwnerId = 1;

    function placeOrders(
        uint96[] memory _tokenInAmount, // amounts_To_Buy
        uint96[] memory _tokenOutAmount, // amounts_To_Bid
    ) internal returns (uint64 OwnerId) {
        // not general accassible the vars, from init
        //(, uint96 tokenOutAmount, uint96 minAmountToReceive) = initialAuctionOrder.decodeOrder();

        uint256 sumOfAmountsToBid = 0;
        OwnerId = getOwnerId(msg.sender);

        // order

    function placeOrders(uint96 orderTokenOut, uint96 orderTokenIn){

        uint256 newOrderId = orderId++;
        orders[newOrderId] = Order(msg.sender, orderTokenOut,  orderTokenIn);
        orderIds.push(newOrderId);

    }

        orders[].OwnerId = OwnerId;
        orders[].tokenInAmount = _tokenInAmount;
        orders[].tokenOutAmount = _tokenOutAmount;

        sumOfAmountsToBid = sumOfAmountsToBid.add(_tokenOutAmount);

        tokenIn.safeTransferFrom(
            msg.sender,
            address(this),
            _tokenInAmount
        );

        // ???
        for (uint256 i = 0; i < _tokenInAmount.length; i++) {
            require(_tokenInAmount[i].mul(minAmountToReceive) < tokenOutAmount.mul(_orderTokenIn[i]),
                "limit price not better than mimimal offer"
            );
            // _orders should have a minimum bid size in order to limit the gas
            // required to compute the final price of the auction.
            require(
                _tokenOutAmount[i] > minimumBiddingAmountPerOrder,
                "order too small"
            );
            bool success =
                orders.insert(
                    IterableOrderedOrderSet.encodeOrder(
                        OwnerId,
                        _orderTokenOut[i],
                        _orderTokenIn[i]
                    ),
                    _prevOrders[i],
                );
            if (success) {
                sumOfAmountsToBid = sumOfAmountsToBid.add(_orderTokenIn[i]);
                emit NewOrder(OwnerId, _orderTokenOut[i], _orderTokenIn[i]);
            }
        }
        tokenIn.safeTransferFrom(
            msg.sender,
            address(this),
            sumOfAmountsToBid
        ); //[1]
    }

    // @dev function settling the auction with a clearingOrder
    // this function only test the clearingPrice, no token are distributed
    function settleAuction(bytes32 clearingOrder) public atStageSolutionSubmission() returns (bytes32 clearingOrder) {
        tokenOutAmountToDistribute = tokenOutAmount;

        // loop over every order
        for (uint256 i = 0; i < orderIds.length; i++) {

            _orderId = orderIds[i];
            _orderTokenOut = orders[orderId].orderTokenOut;
            _orderTokenIn = orders[orderId].orderTokenIn;

            price = _orderTokenOut.div(_orderTokenIn);

            if (price >= clearingPrice) {
                tokenOutAmountToDistribute = tokenOutAmountToDistribute - _orderTokenOut;
            }
        }
        if (tokenOutAmountToDistribute < 1 and tokenOutAmountToDistribute > -1){
            // change var clearingPriceOrder
            clearingPriceOrder = clearingPrice;
            emit settleSucess('yea');
        // overlapping if?
        } else if (tokenOutAmountToDistribute > 0 || tokenOutAmountToDistribute < 0){
            emit settleSucess('ney');
        }
    }

    function registerUser(address user) public returns (uint64 OwnerId) {
        numUsers = numUsers.add(1).toUint64();
        require(
            registeredUsers.insert(numUsers, user),
            "User already registered"
        );
        // less gas if no = here?
        OwnerId = numUsers;
        emit UserRegistration(user, OwnerId);
    }

    function getOwnerId(address user) public returns (uint64 OwnerId) {
        if (registeredUsers.hasAddress(user)) {
            OwnerId = registeredUsers.getId(user);
        } else {
            OwnerId = registerUser(user);
            emit NewUser(OwnerId, user);
        }
    }

}

