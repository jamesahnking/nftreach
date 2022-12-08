// NFT Auction Front End 

import { loadStdlib } from "@reach-sh/stdlib";
import * as backend from "./build/index.main.mjs";

const stdlib = loadStdlib();
const startingBalance = stdlib.parseCurrency(100);

// Creator test account 
console.log(`Creating test account for Creator`);
const accCreator = await stdlib.newTestAccount(startingBalance);

// Creator creates NFT
console.log(`Having creator create a testing NFT`);
// Launch the token using LaunchToken - who, what, supply
const theNFT = await stdlib.launchToken(accCreator, "TestNFt", 'TNF', { supply: 1 });
// Establish ID
const nftId = theNFT.id;
// Min Bid 2 ALGO - parse down to micro algos
const minBid = stdlib.parseCurrency(2);
// Set length of auction in blocks
const lenInBlocks = 10;
// Set NFT parameter 
const params = { nftId, minBid, lenInBlocks };
// Complete Application 
let done = false;
// Array for bidders
const bidders = [];

// BIDDING FUNCTION:::
const startBidders = async () => {
    // Set Minum Bid
    let bid = minBid;
    const runBidder = async (who) => {
        const inc = stdlib.parseCurrency(Math.random() * 10);
        // Set bid to a random sum
        bid = bid.add(inc);
        // Create test account
        const acc = await stdlib.newTestAccount(startingBalance);
        // Error messaging
        acc.setDebugLabel(who);
        // Token Opt In - Algorand Network specific
        await acc.tokenAccept(nftId);
        // Add current bidder to array of bidder(s)
        bidders.push([who, acc]);
        // Get the creators info
        const ctc = acc.contract(backend, ctcCreator.getInfo());
        // Get bidder account balance - correctly formatting the currency for display
        const getBal = async () => stdlib.formatCurrency(await stdlib.balanceOf(acc));

        // MESSAGES::: Print balances before interaction with the contract
        console.log(`${who} decides to bid ${stdlib.formatCurrency(bid)}.`);
        console.log(`${who} balance before contract interaction is ${await getBal()}.`);

        try {
            // 'lastBidder' and 'lastBid' values made through API
            const [lastBidder, lastBid] = await ctc.apis.Bidder.bid(bid);
            // A. outbid B. and their bid was X
            console.log(`${who} out bid ${lastBidder}, who bid ${stdlib.formatCurrency(lastBid)}.`)  
        } catch (e) {
            // A. cant make a bid because the auction has ended
            console.log(`${who} failed to bid, because the auction is over`);
        }
        // After the bid this is what A's balance is
        console.log(`${who} balance after is ${await getBal()}`);

    }
    
    // AUCTION RESOLUTION:::

    //GENERATE BIDDERS:::
    await runBidder('Alice');
    await runBidder('Bob');
    await runBidder('Clair');
    while (!done) {
        // wait 1 block
        await stdlib.wait(1);
    }
 };


// ATTACH CONTRACT/ACCOUNT TO BACKEND:::
const ctcCreator = accCreator.contract(backend);
// CALL Creator
await ctcCreator.p.Creator({
    // Creator Interact Objects:
    getSale: () => {
        console.log(`Creator sets parameters of sale:`, params);
        return params;
    },
    auctionReady: () => {
        startBidders();
    },
    // Micro -> algo formatCurrency. algo -> migcro parseCurrency
    seeBid: (who, amt) => { // who and amt - address, amounts
        console.log(`Creator saw that ${stdlib.formatAddress(who)} bid ${stdlib.formatCurrency(amt)}`);
    },
    showOutcome: (winner, amt) => { // the winner - address(winner), amount
        console.log(`Creator saw that ${stdlib.formatAddress(winner)} won with ${stdlib.formatCurrency(amt)}`);
    },
});
    // AUCTION RESOLUTION:::
    // TRANFER PATTERN:::
    for(const [who, acc] of bidders) {
    //     
    const [ amt, amtNft] = await stdlib.balancesOf(acc, [null, nftId]);
    // A has x. and z. amount of nft    
    console.log(`${who} has ${stdlib.formatCurrency(amt)} ${stdlib.standardUnit} and ${amtNft} of the NFT`);
}   
    // EXIT PROGRAM
    done = true;
