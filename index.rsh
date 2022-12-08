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
        showOutcome: Fun([Address, UInt], Null),  // show outcome of the auction

    });

    // BIDDER:::
    // Bidder will be a repeating participant, 
    // each participant will have identical functionality
    const Bidder = API('Bidder', {
        bid: Fun([UInt], Tuple(Address, UInt)),
    });
    init()

    // COMMUNICATION MODEL:::
    Creator.only(() => {
        const { nftId, minBid, lenInBlocks } = declassify(interact.getSale());
    })

    // PUBLISH TO NETWORK:::
    Creator.publish(nftId, minBid, lenInBlocks);
    // Set amount of asset
    const amt = 1;
    // Done with consensus back to local
    commit()
    // Deposit (1) nft into smart contract + charge(.pay) for consensus action
    Creator.pay([[amt, nftId]]);
    // Interact with acutionReady func
    Creator.interact.auctionReady();

    // ASSERTION::: 
    // The balance of the NFT will always be set to one
    // If assert fails the program will exit
    assert(balance(nftId) == amt, 'balance of NFT is wrong');

    // Set end by adding lastConsensus + how long we want the auction to run.
    const end = lastConsensusTime() + lenInBlocks;

    // PARALELL REDUCE as BIDDING ENGINE:::
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

        // BIDDING API:::
        .api_(Bidder.bid, (bid) => { // Checks for consensus and local step as well(les code)

            // ASSERTION::: 
            // Is the bid greater than the last price
            // if not tell us why
            check(bid > lastPrice, "bid is too low");

            return [bid, (notify) => {
                notify([highestBidder, lastPrice]);
                if (!isFirstBid) { //not fb
                    transfer(lastPrice).to(highestBidder); //lastprice to highest bidder
                }
                const who = this; // who is this ? this is the caller of the contract -> the bidder
                Creator.interact.seeBid(who, bid); // we wand them to see the bid
                return [who, bid, false]; // update the three values and its (it is no longer the first bid)
            }];
        })
        // P-REDUCE TIMEOUT::: - allows p-reduce to escape
        .timeout(absoluteTime(end), () => {
            Creator.publish();
            return [highestBidder, lastPrice, isFirstBid];
        });

    // AUCTION RESOLUTION:::
    transfer(amt, nftId).to(highestBidder);
    if (!isFirstBid) { transfer(lastPrice).to(Creator); }
    Creator.interact.showOutcome(highestBidder, lastPrice);
    commit()
    exit()
}) 