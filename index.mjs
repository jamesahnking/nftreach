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
const theNFT = await stdlib.launchToken(accCreator, "TestNFt", 'TNF', { supply: 1});
// Establish ID
const nftId = theNFT.id;
// Min Bid 2 ALGO - parse down to micro algos
const minBid = stdlib.parseCurrency(2);
// Set length of auction in blocks
const lenInBlocks = 10;
// Set NFT parameter 
const params = {nftId, minBid, lenInBlocks};


// Attach to contract to backend
const ctcCreator = accCreator.contract(backend);
await ctcCreator.p.Creator({
    getSale: () => {
        console.log(`Create sets parameters of sale:`, params);
    },

    auctionReady: () => {

    },
})