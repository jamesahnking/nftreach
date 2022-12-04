// NFT Auction Front End 
import { loadStdlib } from "@reach-sh/stdlib";
import * as backend from "./build/index.main.mjs";

const stlib = loadStdlib();
const startingBalance = stlib.parseCurrency(100);

// Creator test account 
console.log(`Creating test account for Creator`);
const accCreator = await stlib.newTestAccount(startingBalance);