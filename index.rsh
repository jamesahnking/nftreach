'reach 0.1'

export const main = Reach.App(() => {
    //CREATOR
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

    // BIDDER 
    // Bidder will be a repeating participant, 
    // each participant will have identical functionality
    const Bidder = API('Bidder', {
        bid: Fun([UInt], Tuple(Address, UInt)),
    });
    init()

    // COMMUNICATION MODEL:
    Creator.only(() => {
        const { nftId, minBid, lenInBlocks } = declassify(interact.getSale());
    })

    // Publish to Network 
    Creator.publish(nftId, minBid, lenInBlocks);
    const amt = 1; // set amount of
    commit()  // done with consensus back to local
    Creator.pay([[amt, nftId]]); // deposit (1) nft into smart contract + charge(.pay) for consensus action
    Creator.interact.auctionReady();// 
    // Get block time 
    const end = lastConsensusTime() + lenInBlocks;

    // CONCEPT: PARALELL REDUCE as BIDDING ENGINE
    // Parralell Reduce Creates a race between higest bidders 
    // in a consensus step until the auction is over.
    // P-Reduce means : Participants are attempting to produce 
    // a new state from the current values IN paralell.

    // Update bid values
    const [
        highestBidder,
        lastPrice,
        isFirstBid,
    ] = parallelReduce([Creator, minBid, true])
        .invariant(balance(nftId) == amt) // must be the same before during and after 
        .invariant(balance() == (isFirstBid ? 0 : lastPrice))// balance shouold either be zero or the last price
        .while(lastConsensusTime() <= end) // while loop
        .api_(Bidder.bid, (bid) => { //api macro with _ allowing to check for consensus and local step

        })
}) 