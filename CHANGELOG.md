
# Change Log
All notable changes to this project will be documented in this file.
 
The format is based on [Keep a Changelog](http://keepachangelog.com/)
and this project adheres to [Semantic Versioning](http://semver.org/).
 
## [0.1.1-mpv.Unreleased] - 2012-mm-dd
 
Mainly fixes for fixeprice sale
 
### Added
 
 - template metadata over ipfs (#68)  48627ca58b39b541b1aa0bac6bc23bfbf6bcbdf5


### Changed

#### Fixedprice

##### events

NewPurchase() -> NewCommitment()
NewTokenClaim() -> NewTokenWithdraw()  (In UI called Claim)
NewTokenRelease() -> NewTokenRelease() (In UI called Claim)

##### vars

**Renaming**: 
tokensPurchased -> commitment (in tokenIn)

allocationMin -> minCommitment (min in tokenIn)
allocationMax -> maxCommitment (max in tokenIn)


#### functions

**Renaming**: 
buyTokens() -> commitTokens

**logic**:

closeSale() 

* isClosed = true, close sale if either minRaise is reached or endDate passed
* tokenIn and unsold tokenOut sent to owner 

- mesaFactory.initalize -> mesaFactory.initialize / e17bb3dec3d65c741fba7b375f9b8e232f4fdfe6
- (draft) allocationMin has been in tokenOut, now we use minCommitment for this and its in tokenIn (#88)
- (draft) allocationMax has been in tokenOut, now we use maxCommitment for this and its in tokenIn (#88)

### Fixed

- Fix: Remove isClosed = true on releaseTokens() (#71) / cabdc1682dd3a7754938c30aee30f47d1aa7284a

## [0.1.0-mpv.20210406] - 2021-04-06 
  
First deploy used for FE
 