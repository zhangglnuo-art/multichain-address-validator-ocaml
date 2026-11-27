# multichain-address-validator-ocaml

Zero-dependency OCaml library validating multi-chain cryptocurrency address syntax, mandatory custodial Memo/Destination Tag routing rules (`XRP`, `XLM`, `ATOM`, `TON`, `HBAR`, `EOS`), and prefix/suffix vanity address-poisoning lookalikes across EVM, Bitcoin, Solana, XRP, Stellar, Cosmos, TRON, Sui, and TON.

- **Interactive Web Tool:** [AllSwap Multi-Chain Address & Memo Validator](https://allswap.io/tools/address-validator)
- **Platform:** [AllSwap](https://allswap.io)
- **Documentation:** [AllSwap Developer Docs](https://allswap.io/docs)

## Installation

```bash
opam install multichain_address_validator
```

Or build from source with Dune (`OCaml >= 4.14.0`, `dune >= 3.0`):

```bash
dune build
dune runtest
```

## Usage

```ocaml
open Multichain_address_validator

let () =
  (* Validate EVM address *)
  let r1 = validate "EVM" "0x71C95911E9a5D330f4D621842EC243EE1343292e" in
  assert r1.valid;

  (* Enforce mandatory XRP Destination Tag *)
  let r2 = validate "XRP" "rEb8TK3gBgk5auZkwc6sHnwrGVJH8DuaLh" in
  assert (not r2.valid && r2.code = "MISSING_MANDATORY_MEMO");

  (* Detect prefix/suffix address-poisoning lookalike *)
  let r3 =
    validate
      ~trusted:"0x71C95911E9a5D330f4D621842EC243EE1343292e"
      "EVM"
      "0x71C950000000000000000000000000000000292e"
  in
  assert (not r3.valid && r3.code = "ADDRESS_POISONING_ALERT")
```

## License

MIT License — see [LICENSE](./LICENSE).
