import "hardhat-deploy";
import "@nomiclabs/hardhat-ethers";
import { ethers } from "ethers";
import { task, types } from "hardhat/config";

import { getEasyAuctionContract } from "./utils";

const initiateAuction: () => void = () => {
  task("initiateAuction", "Starts a new auction")
    .addParam(
      "auctioningToken",
      "The ERC20's address of the token that should be sold",
    )
    .addParam(
      "biddingToken",
      "The ERC20's address of the token that should be bought",
    )
    .addParam(
      "sellAmount",
      "The amount of auctioningTokens to be sold in atoms",
    )
    .addParam(
      "minBuyAmount",
      "The amount of biddingToken to be bought at least for selling sellAmount in atoms",
    )
    .addOptionalParam(
      "duration",
      "Describes how long the auction should last in seconds",
      "3600",
      types.string,
    )
    .addOptionalParam(
      "minBuyAmountPerOrder",
      "Describes the minimal buyAmount per order placed in the auction. This can be used in order to protect against too high gas costs for the settlement",
      "0.01",
      types.string,
    )
    .setAction(async (taskArgs, hardhatRuntime) => {
      const [caller] = await hardhatRuntime.ethers.getSigners();
      console.log("Using the account:", caller.address);

      const easyAuction = await getEasyAuctionContract(hardhatRuntime);
      const biddingToken = await hardhatRuntime.ethers.getContractAt(
        "ERC20",
        taskArgs.biddingToken,
      );
      const auctioningToken = await hardhatRuntime.ethers.getContractAt(
        "ERC20",
        taskArgs.auctioningToken,
      );
      const sellAmountsInAtoms = ethers.utils.parseUnits(
        taskArgs.sellAmount,
        await auctioningToken.callStatic.decimals(),
      );
      const minBuyAmountInAtoms = ethers.utils.parseUnits(
        taskArgs.minBuyAmount,
        await biddingToken.callStatic.decimals(),
      );
      const minParticipantsBuyAmount = ethers.utils.parseUnits(
        taskArgs.minBuyAmountPerOrder,
        await biddingToken.callStatic.decimals(),
      );

      console.log("Using EasyAuction deployed to:", easyAuction.address);

      const allowance = await auctioningToken.callStatic.allowance(
        caller.address,
        easyAuction.address,
      );
      if (sellAmountsInAtoms.gt(allowance)) {
        console.log("Approving tokens:");
        const tx = await auctioningToken
          .connect(caller)
          .approve(easyAuction.address, sellAmountsInAtoms);
        await tx.wait();
        console.log("Done");
      }

      console.log("Auction gets initiated:");
      const tx = await easyAuction
        .connect(caller)
        .initiateAuction(
          auctioningToken.address,
          biddingToken.address,
          taskArgs.duration,
          sellAmountsInAtoms,
          minBuyAmountInAtoms,
          minParticipantsBuyAmount,
        );
      const txResult = await tx.wait();
      const auctionId = txResult.events
        .filter((event: any) => event.event === "NewAuction")
        .map((event: any) => event.args.auctionId);
      console.log(
        "Your auction has been schedule and has the Id:",
        auctionId.toString(),
      );
    });
};
export { initiateAuction };

// Rinkeby tests task selling WETH for DAI:
// yarn hardhat initiateAuction --sell-token "0xc778417e063141139fce010982780140aa0cd5ab" --buy-token "0x5592EC0cfb4dbc12D3aB100b257153436a1f0FEa" --sell-amount 0.1 --min-buy-amount 50 --network rinkeby
