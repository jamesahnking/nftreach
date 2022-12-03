import { loadStdlib } from "@reach-sh/stdlib";
import * as backend from "./build/index.main.mjs";
import { ask } from '@reach-sh/stdlib';
// Load the standard library
const stdlib = loadStdlib(process.env);

// Starting Balance For Participants
const stargingBalance = stdlib.parseCurrency(100);

// Create and fund (2) accounts A/B
const [accA, accB] = await stdlib.newTestAccounts(2, stargingBalance);
console.log('Hello account A and Account B');

// App message 
console.log('Hello, A and B!');

// Add and attach to the contract 
const ctcA = accA.contract(backend);
const ctcB = accB.contract(backend, ctcA.getInfo());

console.log('Staring backends.....');

