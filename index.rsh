'reach 0.1'

export const main = Reach.App(() => {
    //CREATOR::::
    // Creator of NFT auction / asset
    const Creator = Participant('Creator', {
        getSale: Fun([], Object({
            nftId: Token,
            minBid: UInt,
            lenInBlocks: UInt, // how long item is on sale
        })),
        auctionReady: Fun([], Null),  // let the contract know the auction is ready
        seeBid: Fun([Address, UInt], Null),  // see the latest bids 
        showOutCome: Fun([Address, UInt], Null),  // show outcome of the auction

    });

    // BIDDER::::
    // Bidder will be a repeating participant, 
    // each participant will have identical functionality
    const Bidder = API('Bidder', {
        bid: Fun([UInt], Tuple(Address, UInt)),
    });
    init()

    // COMMUNICATION MODEL::::
    Creator.only(() => {
        const { nftId, minBid, lenInBlocks } = declassify(interact.getSale());
    })

    // Publish to Network 
    Creator.publish(nftId, minBid, lenInBlocks);
    // Set amount of asset
    const amt = 1;
    // Done with consensus back to local
    commit()
    // Deposit (1) nft into smart contract + charge(.pay) for consensus action
    Creator.pay([[amt, nftId]]);
    // 
    Creator.interact.auctionReady();
    // Set end by adding lastConsensus + how long we want the auction to run.
    const end = lastConsensusTime() + lenInBlocks;

    // CONCEPT: PARALELL REDUCE as BIDDING ENGINE
    // Parralell Reduce Creates a race between higest bidders 
    // in a consensus step until the auction is over.
    // P-Reduce means : Participants are attempting to produce 
    // a new state from the current values IN paralell. 
    // Alice and Bob compete to be the first to update state
    // Reach determins the winner and then runs the specified logic

    // Update bid values as a function of the P-Reduce
    const [
        highestBidder,
        lastPrice,
        isFirstBid,
    ] = parallelReduce([Creator, minBid, true])
        .invariant(balance(nftId) == amt) // must be the same before during and after 
        .invariant(balance() == (isFirstBid ? 0 : lastPrice))// balance shouold either be zero or the last price
        .while(lastConsensusTime() <= end) // if we haven't reached the end of the acution
        
        // BIDDING API
        .api_(Bidder.bid, (bid) => { // Checks for consensus and local step as well(les code)

            return [bid, (notify) => {
                notify([highestBidder, lastPrice]);
                if (!isFirstBid) {
                    transfer(lastPrice).to(highestBidder);
                }
                const who = this;
                Creator.interact.seeBid(who, bid);
                return [who, bid, false];
            }];

        });
})