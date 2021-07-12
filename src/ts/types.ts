import { BigNumberish, BytesLike, Contract } from "ethers";

export interface InitiateAuctionInput {
    tokenOut: Contract;
    tokenIn: Contract;
    orderCancellationEndDate: BigNumberish;
    auctionEndDate: BigNumberish;
    auctionedSellAmount: BigNumberish;
    minBuyAmount: BigNumberish;
    minimumBiddingAmountPerOrder: BigNumberish;
    minFundingThreshold: BigNumberish;
    isAtomicClosureAllowed: boolean;
    allowListManager: BytesLike;
    allowListData: BytesLike;
}
