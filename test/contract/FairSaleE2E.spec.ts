import { Contract, BigNumber } from "ethers";
import hre, { ethers, waffle } from "hardhat";

import {
    createTokensAndMintAndApprove,
    placeOrders,
} from "../../src/priceCalculation";

import { closeAuction } from "./utilities";

describe("FairSale", async () => {
    const [user_1, user_2] = waffle.provider.getWallets();
    let fairSale: Contract;
    beforeEach(async () => {
        const FairSale = await ethers.getContractFactory("FairSale");

        fairSale = await FairSale.deploy();
    });

    it("e2e - places a lot of sellOrders, such that the second last order is the clearingOrder and calculates the price to test gas usage of settleAuction", async () => {
        const { tokenIn, tokenOut } = await createTokensAndMintAndApprove(
            fairSale,
            [user_1, user_2],
            hre
        );
        const nrTests = 12; // increase here for better gas estimations, nrTests-2 must be a divisor of 10**18
        await fairSale.initAuction(
            tokenIn.address,
            tokenOut.address,
            60 * 60,
            60 * 60,
            ethers.utils.parseEther("1000"),
            ethers.utils.parseEther("1000"),
            1,
            0,
            false
        );

        for (let i = 2; i < nrTests; i++) {
            const sellOrder = [
                {
                    orderTokenIn: ethers.utils
                        .parseEther("1000")
                        .div(BigNumber.from(nrTests - 2)),
                    orderTokenOut: BigNumber.from("10")
                        .pow(BigNumber.from(18))
                        .mul(1000)
                        .div(BigNumber.from(nrTests - 2))
                        .mul(i - 1)
                        .div(BigNumber.from(i)),
                    ownerId: BigNumber.from(1),
                },
            ];
            await placeOrders(fairSale, sellOrder, hre);
        }
        await closeAuction(fairSale);
        const tx = await fairSale.settleAuction();
        const gasUsed = (await tx.wait()).gasUsed;

        console.log("Gas usage for verification", gasUsed.toString());
    });
});