#!/bin/bash

# Naming conventions: https://hackmd.io/l6ZNaX0zQbuNpT9fxAZY-g
# step 1

sed -i 's/biddingToken/tokenIn/g' *.sol *.spec.ts
sed -i 's/auctioningToken/tokenOut/g' *.sol *.spec.ts

sed -i 's/minFundingThreshold/minSellThreshold/g' *.sol *.spec.ts

sed -i 's/amountToSell/tokenOutAmount/g' *.sol *.spec.ts

sed -i 's/amountToBuy/orderTokenOut/g' *.sol *.spec.ts
sed -i 's/amountToBid/orderTokenIn/g' *.sol *.spec.ts

sed -i 's/userId/ownerId/g' *.sol *.spec.ts

