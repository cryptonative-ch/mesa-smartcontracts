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

    event NewOrder(
        uint64 indexed ownerId,
        uint96 orderTokenOut,
        uint96 orderTokenIn
    );
    event ClaimedFromOrder(
        uint64 indexed ownerId,
        uint96 orderTokenOut,
        uint96 orderTokenIn
    );

    event NewUser(
        uint64 indexed ownerId, 
        address indexed userAddress
    );

    event InitializedAuction(
        IERC20 indexed _tokenIn,
        IERC20 indexed _tokenOut,
        uint256 orderCancellationEndDate,
        uint96 _orderTokenOut,
        uint96 _minBidAmountToReceive,
        uint256 minimumBiddingAmountPerOrder,
        uint256 minSellThreshold
    );
    event UserRegistration(address indexed user, uint64 bidOwner);

    // https://medium.com/wolverineblockchain/common-questions-for-the-curious-in-solidity-5d40b5d38dc2
    // nico??
    struct Order {
        address ownerId; // 160 bits
        uint96 _orderTokenOut;
        uint96 _orderTokenIn;
    }
    // total 160+96+96 = 352
    // 160+48+48 = 256  48 bits 281,474,976,710,656 valus
    // 1 eth = 1,000,000,000,000,000,000 wei

    uint256 orderId;
    
    mapping (uint256 => Order) internal orders;

    uint256[] orderIds;


    IERC20 public tokenIn;
    IERC20 public tokenOut;
    uint256 public orderCancellationEndDate;
    uint96 public orderTokenOut;
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
        uint64 ownerId = getOwnerId(msg.sender);

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
    //?? memory and why array?
    function placeOrders(
        uint96[] memory _orderTokenIn, // amounts_To_Buy
        uint96[] memory _orderTokenOut, // amounts_To_Bid
    ) internal returns (uint64 ownerId) {

        uint256 sumOfAmountsToBid = 0;

        ownerId = getOwnerId(msg.sender);
        uint256 newOrderId = orderId++;
        orders[newOrderId] = Order(ownerId, orderTokenOut,  orderTokenIn);
        // for looping
        orderIds.push(newOrderId);

        sumOfAmountsToBid = sumOfAmountsToBid.add(_orderTokenIn);

        emit NewOrder(ownerId, _orderTokenOut, _orderTokenIn);

        tokenIn.safeTransferFrom(
            msg.sender,
            address(this),
            _orderTokenIn
        ); //[1]

        // ??? why arrary? old stuff from EA
        for (uint256 i = 0; i < _orderTokenIn.length; i++) {
            require(_orderTokenIn[i].mul(minAmountToReceive) < orderTokenOut.mul(_orderTokenIn[i]),
                "limit price not better than mimimal offer"
            );
            // _orders should have a minimum bid size in order to limit the gas
            // required to compute the final price of the auction.
            require(
                _orderTokenOut[i] > minimumBiddingAmountPerOrder,
                "order too small"
            );
            if (success) {
                sumOfAmountsToBid = sumOfAmountsToBid.add(_orderTokenIn[i]);
                emit NewOrder(ownerId, _orderTokenOut[i], _orderTokenIn[i]);
            }
        }
    }

    // input is array with orders id to cancel?
    // how this ids find in the fe? (??? nico)
    function cancelOrders(bytes32[] memory _orders)
        public
        atStageOrderPlacementAndCancelation()
    {
        uint64 ownerId = getUserId(msg.sender);
        uint256 claimableAmount = 0;
        // ?? nico, I cant loop over all orders to get the right orders, this is too expensiv

        for (uint256 i = 0; i < _orders.length; i++) {
            uint96 orderId = _orders[i];
            // get as single value?
            uint96 orderTokenIn = orderIds[orderId].orderTokenIn;
            // or like this? (nico??)
            //(uint64 ownerId, uint96 orderTokenOut, uint96 orderTokenIn) = orderIds[orderId];
            require(
                    orderIds[orderId].ownerId == ownerId,
                    "Only the user can cancel his orders"
            );
            claimableAmount = claimableAmount.add(orderTokenIn);
            emit CancellationOrder(ownerId, orderTokenOut, orderTokenIn);
        }
        // https://ethereum.stackexchange.com/questions/13167/are-there-well-solved-and-simple-storage-patterns-for-solidity
        // remove from order array, looks like this this is only possible by move the value at the end of the array and then shorten the array by -1
        orderIds[orderId] // Todo remove from orderIds
        tokenIn.safeTransfer(msg.sender, claimableAmount); //[2]
    }

    // @dev function settling the auction with a clearingOrder
    // this function only test the clearingPrice, if test is true, clearingPrice is set, should only be callable once. 
    // Todo Make it only callable once, if clearingPrice not set
    function setClearingPrice(uint256 offChainClearingPrice)
        public
        atStageSolutionSubmission()
        returns (bytes32 clearingPrice)
    {
        uint256 tokenOutAmountToDistribute = tokenOutAmount;
        uint256 equalClearingPriceOrderSum = 0;

        // loop over every order
        // thing to consider
        // we may have severall orders which can have the same price as the clearing price
        for (uint256 i = 0; i < orderIds.length; i++) {
            uint256 _orderId = orderIds[i];
            uint256 _orderTokenOut = orders[orderId].orderTokenOut;
            uint256 _orderTokenIn = orders[orderId].orderTokenIn;

            // ??? can this be a int, has to be float?
            uint256  price = _orderTokenOut.div(_orderTokenIn);

            // substract from stack (tokenOutAmount) to orders above settelment price 
            if (price > offChainClearingPrice) {
                tokenOutAmountToDistribute = tokenOutAmountToDistribute - _orderTokenOut;

                // if all token gone too early, then ClearingPrice too low
                if (tokenOutAmountToDistribute < 0){
                    emit settleSucess(false);
                }

            } else if (price == offChainClearingPrice){
                // set priceNumerator / priceDenominator
                if (equalClearingPriceOrderSum == 0){
                    priceNumerator = _orderTokenOut;
                    priceDenominator = _orderTokenIn;
                }
                // sum all orders equal settelment price
                // possible doss to set all bids to offChainClearingPrice
                equalClearingPriceOrderSum = equalClearingPriceOrderSum + _orderTokenOut;
            }
        } 
        // still token left on ClearingPrice, then ClearingPrice is too high  () > or >= ???)
        if (tokenOutAmountToDistribute - equalClearingPriceOrderSum > 0){
                emit settleSucess(false);
        }
        // if not stopped here, clearingPrice is the right solution


        clearingPrice = offChainClearingPrice;
        emit settleSucess(true);
        return clearingPrice; // ??? nico       
    }

    function registerUser(address user) public returns (uint64 ownerId) {
        numUsers = numUsers.add(1).toUint64();
        require(
            registeredUsers.insert(numUsers, user),
            "User already registered"
        );
        // less gas if no = here?
        ownerId = numUsers;
        emit UserRegistration(user, ownerId);
    }

    function getOwnerId(address user) public returns (uint64 ownerId) {
        if (registeredUsers.hasAddress(user)) {
            ownerId = registeredUsers.getId(user);
        } else {
            ownerId = registerUser(user);
            emit NewUser(ownerId, user);
        }
    }

}

