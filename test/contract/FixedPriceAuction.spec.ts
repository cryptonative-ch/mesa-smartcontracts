import { expect } from "chai";
import { Contract, BigNumber } from "ethers";
import hre, { ethers, waffle } from "hardhat";

import { mineBlock, expandTo18Decimals } from "./utilities";
import "@nomiclabs/hardhat-ethers";

describe("FixedPriceAuction", async () => {
    const [user_1, user_2] = waffle.provider.getWallets();
    let fixedPriceAuction: Contract;
    let auctionIntialized: Contract;
    let tokenA: Contract;
    let tokenB: Contract;
    let currentBlockNumber, currentBlock;

    const defaultTokenPrice = expandTo18Decimals(10);
    const defaultTokensForSale = expandTo18Decimals(2000);
    const defaultAllocationMin = expandTo18Decimals(2);
    const defaultAllocationMax = expandTo18Decimals(10);
    const defaultMinimumRaise = expandTo18Decimals(5000);
    let defaultStartDate: number;
    let defaultEndDate: number;

    function encodeInitData(
        tokenA: string,
        tokenB: string,
        tokenPrice: BigNumber,
        tokensForSale: BigNumber,
        startDate: number,
        endDate: number,
        allocationMin: BigNumber,
        allocationMax: BigNumber,
        minimumRaise: BigNumber,
        owner: string
    ) {
        return ethers.utils.defaultAbiCoder.encode(
            [
                "address",
                "address",
                "uint256",
                "uint256",
                "uint256",
                "uint256",
                "uint256",
                "uint256",
                "uint256",
                "address",
            ],
            [
                tokenA,
                tokenB,
                tokenPrice,
                tokensForSale,
                startDate,
                endDate,
                allocationMin,
                allocationMax,
                minimumRaise,
                owner,
            ]
        );
    }

    beforeEach(async () => {
        currentBlockNumber = await ethers.provider.getBlockNumber();
        currentBlock = await ethers.provider.getBlock(currentBlockNumber);

        defaultStartDate = currentBlock.timestamp + 500;
        defaultEndDate = defaultStartDate + 86400; // 24 hours

        const FixedPriceAuction = await ethers.getContractFactory(
            "FixedPriceAuction"
        );

        const ERC20 = await hre.ethers.getContractFactory("ERC20Mintable");

        fixedPriceAuction = await FixedPriceAuction.deploy();
        auctionIntialized = await FixedPriceAuction.deploy();

        tokenA = await ERC20.deploy("tokenA", "tokA");
        tokenB = await ERC20.deploy("tokenB", "tokB");

        await tokenA.mint(user_1.address, BigNumber.from(10).pow(30));
        await tokenB.mint(user_1.address, BigNumber.from(10).pow(30));

        await tokenB.approve(auctionIntialized.address, defaultTokensForSale);

        const initData = await encodeInitData(
            tokenA.address,
            tokenB.address,
            defaultTokenPrice,
            defaultTokensForSale,
            defaultStartDate,
            defaultEndDate,
            defaultAllocationMin,
            defaultAllocationMax,
            defaultMinimumRaise,
            user_1.address
        );

        await auctionIntialized.init(initData);
    });
    describe("initiate auction", async () => {
        it("throws if token is used for both tokenA and tokenB", async () => {
            const initData = await encodeInitData(
                tokenA.address,
                tokenA.address,
                defaultTokenPrice,
                defaultTokensForSale,
                defaultStartDate,
                defaultEndDate,
                defaultAllocationMin,
                defaultAllocationMax,
                defaultMinimumRaise,
                user_1.address
            );

            await expect(fixedPriceAuction.init(initData)).to.be.revertedWith(
                "FixedPriceAuction: invalid tokens"
            );
        });

        it("throws if token price is zero", async () => {
            const initData = await encodeInitData(
                tokenA.address,
                tokenB.address,
                BigNumber.from(0),
                defaultTokensForSale,
                defaultStartDate,
                defaultEndDate,
                defaultAllocationMin,
                defaultAllocationMax,
                defaultMinimumRaise,
                user_1.address
            );

            await expect(fixedPriceAuction.init(initData)).to.be.revertedWith(
                "FixedPriceAuction: invalid tokenPrice"
            );
        });

        it("throws if tokensForSale is zero", async () => {
            const initData = await encodeInitData(
                tokenA.address,
                tokenB.address,
                defaultTokenPrice,
                BigNumber.from(0),
                defaultStartDate,
                defaultEndDate,
                defaultAllocationMin,
                defaultAllocationMax,
                defaultMinimumRaise,
                user_1.address
            );

            await expect(fixedPriceAuction.init(initData)).to.be.revertedWith(
                "FixedPriceAuction: invalid tokensForSale"
            );
        });

        it("throws if startDate is in the past", async () => {
            const initData = await encodeInitData(
                tokenA.address,
                tokenB.address,
                defaultTokenPrice,
                defaultTokensForSale,
                defaultStartDate - 1000,
                defaultEndDate,
                defaultAllocationMin,
                defaultAllocationMax,
                defaultMinimumRaise,
                user_1.address
            );

            await expect(fixedPriceAuction.init(initData)).to.be.revertedWith(
                "FixedPriceAuction: invalid startDate"
            );
        });

        it("throws if endDate is before startDate", async () => {
            const initData = await encodeInitData(
                tokenA.address,
                tokenB.address,
                defaultTokenPrice,
                defaultTokensForSale,
                defaultEndDate,
                defaultStartDate,
                defaultAllocationMin,
                defaultAllocationMax,
                defaultMinimumRaise,
                user_1.address
            );

            await expect(fixedPriceAuction.init(initData)).to.be.revertedWith(
                "FixedPriceAuction: invalid endDate"
            );
        });

        it("initializes auction", async () => {
            tokenB.approve(fixedPriceAuction.address, defaultTokensForSale);

            const initData = await encodeInitData(
                tokenA.address,
                tokenB.address,
                defaultTokenPrice,
                defaultTokensForSale,
                defaultStartDate,
                defaultEndDate,
                defaultAllocationMin,
                defaultAllocationMax,
                defaultMinimumRaise,
                user_1.address
            );

            await expect(fixedPriceAuction.init(initData))
                .to.emit(fixedPriceAuction, "AuctionInitalized")
                .withArgs(
                    tokenA.address,
                    tokenB.address,
                    defaultTokenPrice,
                    defaultTokensForSale,
                    defaultStartDate,
                    defaultEndDate,
                    defaultAllocationMin,
                    defaultAllocationMax,
                    defaultMinimumRaise
                )
                .to.emit(tokenB, "Transfer")
                .withArgs(
                    user_1.address,
                    fixedPriceAuction.address,
                    defaultTokensForSale
                );
        });
    });

    describe("purchasig tokens", async () => {
        it("throws trying to purchase less tokens then allocationMin", async () => {
            await expect(
                auctionIntialized.buyTokens(expandTo18Decimals(1))
            ).to.be.revertedWith("FixedPriceAuction: amount to low");
        });

        it("throws trying to purchase more tokens then allocationMax", async () => {
            await expect(
                auctionIntialized.buyTokens(expandTo18Decimals(11))
            ).to.be.revertedWith("FixedPriceAuction: allocationMax reached");
        });

        it("throws trying to purchase tokens after endDate", async () => {
            await mineBlock(defaultEndDate + 100);
            await expect(
                auctionIntialized.buyTokens(expandTo18Decimals(10))
            ).to.be.revertedWith("FixedPriceAuction: auction deadline passed");
        });

        it("throws trying to purchase after auction is closed", async () => {
            tokenB.approve(fixedPriceAuction.address, defaultTokensForSale);

            const initData = await encodeInitData(
                tokenA.address,
                tokenB.address,
                defaultTokenPrice,
                defaultTokensForSale,
                defaultStartDate,
                defaultEndDate,
                defaultAllocationMin,
                defaultAllocationMax,
                expandTo18Decimals(0),
                user_1.address
            );

            await fixedPriceAuction.init(initData);
            await mineBlock(defaultEndDate + 100);
            await fixedPriceAuction.closeAuction();

            await expect(
                fixedPriceAuction.buyTokens(expandTo18Decimals(10))
            ).to.be.revertedWith("FixedPriceAuction: auction closed");
        });

        it("allows to purchase tokens", async () => {
            await tokenA.approve(
                auctionIntialized.address,
                expandTo18Decimals(10)
            );

            expect(await auctionIntialized.tokensRemaining()).to.be.equal(
                defaultTokensForSale
            );

            await expect(auctionIntialized.buyTokens(expandTo18Decimals(10)))
                .to.emit(auctionIntialized, "NewPurchase")
                .withArgs(user_1.address, expandTo18Decimals(10))
                .to.emit(tokenA, "Transfer")
                .withArgs(
                    user_1.address,
                    auctionIntialized.address,
                    expandTo18Decimals(10)
                );

            expect(await auctionIntialized.tokensRemaining()).to.be.equal(
                expandTo18Decimals(1990)
            );

            await mineBlock(defaultEndDate - 100);
            expect(
                await auctionIntialized.secondsRemainingInAuction()
            ).to.be.equal(100);

            await mineBlock(defaultEndDate + 100);
            expect(
                await auctionIntialized.secondsRemainingInAuction()
            ).to.be.equal(0);
        });
    });

    describe("closing auction", async () => {
        it("throws trying to close auction twice", async () => {
            tokenB.approve(fixedPriceAuction.address, defaultTokensForSale);

            const initData = await encodeInitData(
                tokenA.address,
                tokenB.address,
                defaultTokenPrice,
                defaultTokensForSale,
                defaultStartDate,
                defaultEndDate,
                defaultAllocationMin,
                defaultAllocationMax,
                expandTo18Decimals(0),
                user_1.address
            );

            await fixedPriceAuction.init(initData);
            await mineBlock(defaultEndDate + 100);
            await expect(fixedPriceAuction.closeAuction()).to.emit(
                fixedPriceAuction,
                "AuctionClosed"
            );
            await expect(fixedPriceAuction.closeAuction()).to.be.revertedWith(
                "FixedPriceAuction: already closed"
            );
        });

        it("throws trying to close auction before endDate", async () => {
            tokenB.approve(fixedPriceAuction.address, defaultTokensForSale);

            const initData = await encodeInitData(
                tokenA.address,
                tokenB.address,
                defaultTokenPrice,
                defaultTokensForSale,
                defaultStartDate,
                defaultEndDate,
                defaultAllocationMin,
                defaultAllocationMax,
                expandTo18Decimals(0),
                user_1.address
            );

            await fixedPriceAuction.init(initData);
            await mineBlock(defaultEndDate - 10);
            await expect(fixedPriceAuction.closeAuction()).to.be.revertedWith(
                "FixedPriceAuction: endDate not passed"
            );
        });

        it("throws trying to close auction without minumumRaise reached", async () => {
            tokenB.approve(fixedPriceAuction.address, defaultTokensForSale);

            const initData = await encodeInitData(
                tokenA.address,
                tokenB.address,
                defaultTokenPrice,
                defaultTokensForSale,
                defaultStartDate,
                defaultEndDate,
                defaultAllocationMin,
                defaultAllocationMax,
                expandTo18Decimals(10),
                user_1.address
            );

            await fixedPriceAuction.init(initData);
            await mineBlock(defaultEndDate + 100);
            await expect(fixedPriceAuction.closeAuction()).to.be.revertedWith(
                "FixedPriceAuction: minumumRaise not reached"
            );
        });

        it("allows closing auction", async () => {
            tokenB.approve(fixedPriceAuction.address, defaultTokensForSale);

            const initData = await encodeInitData(
                tokenA.address,
                tokenB.address,
                defaultTokenPrice,
                defaultTokensForSale,
                defaultStartDate,
                defaultEndDate,
                defaultAllocationMin,
                defaultAllocationMax,
                expandTo18Decimals(10),
                user_1.address
            );

            await fixedPriceAuction.init(initData);
            await tokenA.approve(
                fixedPriceAuction.address,
                expandTo18Decimals(10)
            );
            await fixedPriceAuction.buyTokens(expandTo18Decimals(10));
            await mineBlock(defaultEndDate + 100);

            await expect(fixedPriceAuction.closeAuction()).to.emit(
                fixedPriceAuction,
                "AuctionClosed"
            );
        });
    });

    describe("releasing tokens for auctions not reached raise goal", async () => {
        it("throws trying to release tokens for auctions without minRaise", async () => {
            tokenB.approve(fixedPriceAuction.address, defaultTokensForSale);

            const initData = await encodeInitData(
                tokenA.address,
                tokenB.address,
                defaultTokenPrice,
                defaultTokensForSale,
                defaultStartDate,
                defaultEndDate,
                defaultAllocationMin,
                defaultAllocationMax,
                expandTo18Decimals(0),
                user_1.address
            );

            await fixedPriceAuction.init(initData);
            await tokenA.approve(
                fixedPriceAuction.address,
                expandTo18Decimals(10)
            );
            await fixedPriceAuction.buyTokens(expandTo18Decimals(10));

            await expect(fixedPriceAuction.releaseTokens()).to.be.revertedWith(
                "FixedPriceAuction: no minumumRaise"
            );
        });
        it("throws trying to release tokens for auctions before endDate passed", async () => {
            tokenB.approve(fixedPriceAuction.address, defaultTokensForSale);

            const initData = await encodeInitData(
                tokenA.address,
                tokenB.address,
                defaultTokenPrice,
                defaultTokensForSale,
                defaultStartDate,
                defaultEndDate,
                defaultAllocationMin,
                defaultAllocationMax,
                expandTo18Decimals(10),
                user_1.address
            );

            await fixedPriceAuction.init(initData);
            await tokenA.approve(
                fixedPriceAuction.address,
                expandTo18Decimals(10)
            );
            await fixedPriceAuction.buyTokens(expandTo18Decimals(10));

            await expect(fixedPriceAuction.releaseTokens()).to.be.revertedWith(
                "FixedPriceAuction: endDate not passed"
            );
        });

        it("throws trying to release tokens for auctions if no tokens purchased", async () => {
            tokenB.approve(fixedPriceAuction.address, defaultTokensForSale);

            const initData = await encodeInitData(
                tokenA.address,
                tokenB.address,
                defaultTokenPrice,
                defaultTokensForSale,
                defaultStartDate,
                defaultEndDate,
                defaultAllocationMin,
                defaultAllocationMax,
                expandTo18Decimals(10),
                user_1.address
            );

            await fixedPriceAuction.init(initData);
            await mineBlock(defaultEndDate + 100);
            await expect(fixedPriceAuction.releaseTokens()).to.be.revertedWith(
                "FixedPriceAuction: no tokens purchased by this investor"
            );
        });

        it("throws trying to release tokens for auctions if no tokens purchased", async () => {
            tokenB.approve(fixedPriceAuction.address, defaultTokensForSale);

            const initData = await encodeInitData(
                tokenA.address,
                tokenB.address,
                defaultTokenPrice,
                defaultTokensForSale,
                defaultStartDate,
                defaultEndDate,
                defaultAllocationMin,
                defaultAllocationMax,
                expandTo18Decimals(10),
                user_1.address
            );

            await fixedPriceAuction.init(initData);

            await tokenA.approve(
                fixedPriceAuction.address,
                expandTo18Decimals(10)
            );
            await fixedPriceAuction.buyTokens(expandTo18Decimals(10));
            await mineBlock(defaultEndDate + 100);
            await expect(fixedPriceAuction.releaseTokens()).to.be.revertedWith(
                "FixedPriceAuction: minumumRaise reached"
            );
        });

        it("allows releasing tokens back to investor if minRaise was not reached", async () => {
            tokenB.approve(fixedPriceAuction.address, defaultTokensForSale);

            const initData = await encodeInitData(
                tokenA.address,
                tokenB.address,
                defaultTokenPrice,
                defaultTokensForSale,
                defaultStartDate,
                defaultEndDate,
                defaultAllocationMin,
                defaultAllocationMax,
                expandTo18Decimals(20),
                user_1.address
            );

            await fixedPriceAuction.init(initData);
            await tokenA.approve(
                fixedPriceAuction.address,
                expandTo18Decimals(10)
            );
            await fixedPriceAuction.buyTokens(expandTo18Decimals(10));
            await mineBlock(defaultEndDate + 100);
            await expect(fixedPriceAuction.releaseTokens())
                .to.emit(fixedPriceAuction, "NewTokenRelease")
                .withArgs(user_1.address, expandTo18Decimals(10));
        });
    });

    describe("claiming tokens & withdrawing funds", async () => {
        it("throws trying to claim tokens for auction is closed", async () => {
            await expect(auctionIntialized.claimTokens()).to.be.revertedWith(
                "FixedPriceAuction: auction not closed"
            );
        });

        it("throws trying to claim tokens without purchase", async () => {
            tokenB.approve(fixedPriceAuction.address, defaultTokensForSale);

            const initData = await encodeInitData(
                tokenA.address,
                tokenB.address,
                defaultTokenPrice,
                defaultTokensForSale,
                defaultStartDate,
                defaultEndDate,
                defaultAllocationMin,
                defaultAllocationMax,
                expandTo18Decimals(0),
                user_1.address
            );

            await fixedPriceAuction.init(initData);
            await mineBlock(defaultEndDate + 100);
            await fixedPriceAuction.closeAuction();
            await expect(fixedPriceAuction.claimTokens()).to.be.revertedWith(
                "FixedPriceAuction: no tokens to claim"
            );
        });

        it("allows claiming tokens after auction closing", async () => {
            tokenB.approve(fixedPriceAuction.address, defaultTokensForSale);

            const initData = await encodeInitData(
                tokenA.address,
                tokenB.address,
                defaultTokenPrice,
                defaultTokensForSale,
                defaultStartDate,
                defaultEndDate,
                defaultAllocationMin,
                defaultAllocationMax,
                expandTo18Decimals(0),
                user_1.address
            );

            await fixedPriceAuction.init(initData);
            await tokenA.approve(
                fixedPriceAuction.address,
                expandTo18Decimals(10)
            );
            await fixedPriceAuction.buyTokens(expandTo18Decimals(10));

            await mineBlock(defaultEndDate + 100);
            await fixedPriceAuction.closeAuction();

            await expect(fixedPriceAuction.claimTokens())
                .to.emit(fixedPriceAuction, "NewTokenClaim")
                .withArgs(user_1.address, expandTo18Decimals(10));
        });

        it("allows distribut all tokens after auction closing", async () => {
            tokenB.approve(fixedPriceAuction.address, defaultTokensForSale);

            const initData = await encodeInitData(
                tokenA.address,
                tokenB.address,
                defaultTokenPrice,
                defaultTokensForSale,
                defaultStartDate,
                defaultEndDate,
                defaultAllocationMin,
                defaultAllocationMax,
                expandTo18Decimals(0),
                user_1.address
            );

            await fixedPriceAuction.init(initData);
            await tokenA.approve(
                fixedPriceAuction.address,
                expandTo18Decimals(10)
            );

            await fixedPriceAuction.buyTokens(expandTo18Decimals(10));

            await mineBlock(defaultEndDate + 100);

            await fixedPriceAuction.closeAuction();

            await expect(fixedPriceAuction.distributeAllTokens())
                .to.emit(fixedPriceAuction, "distributeAllTokensLeft")
                .withArgs('0');
        });
        it("allows distribut all tokens after auction closing with two bidders", async () => {

            tokenB.approve(fixedPriceAuction.address, defaultTokensForSale);

            const initData = await encodeInitData(
                tokenA.address,
                tokenB.address,
                defaultTokenPrice,
                defaultTokensForSale,
                defaultStartDate,
                defaultEndDate,
                defaultAllocationMin,
                defaultAllocationMax,
                expandTo18Decimals(0),
                user_1.address
            );

            await fixedPriceAuction.init(initData);

            await tokenA.approve(
                fixedPriceAuction.address,
                expandTo18Decimals(10)
            );

            await tokenA.mint(user_2.address, BigNumber.from(10).pow(30));
            await tokenA.connect(user_2).approve(fixedPriceAuction.address, BigNumber.from(10).pow(30));

            await fixedPriceAuction.buyTokens(expandTo18Decimals(10));
            await fixedPriceAuction.connect(user_2).buyTokens(expandTo18Decimals(3));
            await fixedPriceAuction.connect(user_2).buyTokens(expandTo18Decimals(4));

            await mineBlock(defaultEndDate + 100);

            await fixedPriceAuction.closeAuction();

            await expect(fixedPriceAuction.distributeAllTokens())
                .to.emit(fixedPriceAuction, "distributeAllTokensLeft")
                .withArgs('0');
        });
        it("allows withdrawing unsold tokens", async () => {
            tokenB.approve(fixedPriceAuction.address, defaultTokensForSale);

            const initData = await encodeInitData(
                tokenA.address,
                tokenB.address,
                defaultTokenPrice,
                defaultTokensForSale,
                defaultStartDate,
                defaultEndDate,
                defaultAllocationMin,
                defaultAllocationMax,
                expandTo18Decimals(0),
                user_1.address
            );

            await fixedPriceAuction.init(initData);
            await tokenA.approve(
                fixedPriceAuction.address,
                expandTo18Decimals(10)
            );
            await fixedPriceAuction.buyTokens(expandTo18Decimals(10));

            await mineBlock(defaultEndDate + 100);

            await expect(
                fixedPriceAuction.withdrawUnsoldFunds()
            ).to.be.revertedWith("FixedPriceAuction: auction not closed");

            await fixedPriceAuction.closeAuction();

            const remainingTokes = await fixedPriceAuction.tokensRemaining();

            await expect(fixedPriceAuction.withdrawUnsoldFunds())
                .to.emit(tokenB, "Transfer")
                .withArgs(
                    fixedPriceAuction.address,
                    user_1.address,
                    remainingTokes
                );
        });

        it("allows withdrawing funds", async () => {
            tokenB.approve(fixedPriceAuction.address, defaultTokensForSale);

            const initData = await encodeInitData(
                tokenA.address,
                tokenB.address,
                defaultTokenPrice,
                defaultTokensForSale,
                defaultStartDate,
                defaultEndDate,
                defaultAllocationMin,
                defaultAllocationMax,
                expandTo18Decimals(0),
                user_1.address
            );

            await fixedPriceAuction.init(initData);
            await tokenA.approve(
                fixedPriceAuction.address,
                expandTo18Decimals(10)
            );
            await fixedPriceAuction.buyTokens(expandTo18Decimals(10));

            await mineBlock(defaultEndDate + 100);

            await expect(
                fixedPriceAuction.withdrawFunds()
            ).to.be.revertedWith("FixedPriceAuction: auction not closed");

            await fixedPriceAuction.closeAuction();

            await expect(fixedPriceAuction.withdrawFunds())
                .to.emit(tokenA, "Transfer")
                .withArgs(
                    fixedPriceAuction.address,
                    user_1.address,
                    expandTo18Decimals(10)
                );
        });


        it("allows withdrawing funds with params", async () => {
            tokenB.approve(fixedPriceAuction.address, defaultTokensForSale);

            const calldata = "0x";

            const initData = await encodeInitData(
                tokenA.address,
                tokenB.address,
                defaultTokenPrice,
                defaultTokensForSale,
                defaultStartDate,
                defaultEndDate,
                defaultAllocationMin,
                defaultAllocationMax,
                expandTo18Decimals(0),
                user_1.address
            );

            await fixedPriceAuction.init(initData);
            await tokenA.approve(
                fixedPriceAuction.address,
                expandTo18Decimals(10)
            );
            await fixedPriceAuction.buyTokens(expandTo18Decimals(10));

            await mineBlock(defaultEndDate + 100);

            await expect(
                fixedPriceAuction.withdrawFundsWithParams(calldata)
            ).to.be.revertedWith("FixedPriceAuction: auction not closed");

            await fixedPriceAuction.closeAuction();

            await expect(fixedPriceAuction.withdrawFundsWithParams(calldata))
                .to.emit(tokenA, "Transfer")
                .withArgs(
                    fixedPriceAuction.address,
                    user_1.address,
                    expandTo18Decimals(10)
                );
        });

        it("allows only owner to withdraw ERC20", async () => {
            tokenB.approve(fixedPriceAuction.address, defaultTokensForSale);

            const initData = await encodeInitData(
                tokenA.address,
                tokenB.address,
                defaultTokenPrice,
                defaultTokensForSale,
                defaultStartDate,
                defaultEndDate,
                defaultAllocationMin,
                defaultAllocationMax,
                expandTo18Decimals(0),
                user_1.address
            );

            await fixedPriceAuction.init(initData);
            await tokenA.approve(
                fixedPriceAuction.address,
                expandTo18Decimals(10)
            );
            await tokenA.transfer(
                fixedPriceAuction.address,
                expandTo18Decimals(10)
            );

            await expect(
                fixedPriceAuction.ERC20Withdraw(
                    tokenA.address,
                    expandTo18Decimals(1)
                )
            ).to.be.revertedWith("FixedPriceAuction: auction not ended");

            await mineBlock(defaultEndDate + 100);

            await expect(
                fixedPriceAuction
                    .connect(user_2)
                    .ERC20Withdraw(tokenA.address, expandTo18Decimals(1))
            ).to.be.revertedWith("FixedPriceAuction: FORBIDDEN");

            await expect(
                fixedPriceAuction.ERC20Withdraw(
                    tokenA.address,
                    expandTo18Decimals(1)
                )
            )
                .to.emit(tokenA, "Transfer")
                .withArgs(
                    fixedPriceAuction.address,
                    user_1.address,
                    expandTo18Decimals(1)
                );
        });

        it("allows only owner to withdraw ETH", async () => {
            tokenB.approve(fixedPriceAuction.address, defaultTokensForSale);

            const initData = await encodeInitData(
                tokenA.address,
                tokenB.address,
                defaultTokenPrice,
                defaultTokensForSale,
                defaultStartDate,
                defaultEndDate,
                defaultAllocationMin,
                defaultAllocationMax,
                expandTo18Decimals(0),
                user_1.address
            );

            await fixedPriceAuction.init(initData);

            await user_1.sendTransaction({
                to: fixedPriceAuction.address,
                value: expandTo18Decimals(10),
            });

            await expect(
                fixedPriceAuction.ETHWithdraw(expandTo18Decimals(1))
            ).to.be.revertedWith("FixedPriceAuction: auction not ended");

            await mineBlock(defaultEndDate + 100);

            await expect(
                fixedPriceAuction
                    .connect(user_2)
                    .ETHWithdraw(expandTo18Decimals(1))
            ).to.be.revertedWith("FixedPriceAuction: FORBIDDEN");
            const balanceBefore = await user_1.getBalance();
            await fixedPriceAuction.ETHWithdraw(expandTo18Decimals(1));
            expect(await user_1.getBalance()).to.be.above(balanceBefore);
        });
    });
});
