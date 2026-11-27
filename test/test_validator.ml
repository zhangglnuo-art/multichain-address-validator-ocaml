open Multichain_address_validator

let () =
  let r1 = validate "EVM" "0x71C95911E9a5D330f4D621842EC243EE1343292e" in
  assert r1.valid;
  let r2 = validate "XRP" "rEb8TK3gBgk5auZkwc6sHnwrGVJH8DuaLh" in
  assert ((not r2.valid) && r2.code = "MISSING_MANDATORY_MEMO");
  let r3 = validate ~memo:"104928173" "XRP" "rEb8TK3gBgk5auZkwc6sHnwrGVJH8DuaLh" in
  assert r3.valid;
  let r4 =
    validate
      ~trusted:"0x71C95911E9a5D330f4D621842EC243EE1343292e"
      "EVM"
      "0x71C950000000000000000000000000000000292e"
  in
  assert ((not r4.valid) && r4.code = "ADDRESS_POISONING_ALERT")
