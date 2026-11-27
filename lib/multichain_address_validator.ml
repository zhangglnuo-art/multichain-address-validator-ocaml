type validation_result = {
  valid : bool;
  code : string;
  chain : string;
  message : string;
}

let is_hex_char c =
  (c >= '0' && c <= '9') || (c >= 'a' && c <= 'f') || (c >= 'A' && c <= 'F')

let is_digit c = c >= '0' && c <= '9'

let is_base58_char c =
  (c >= '1' && c <= '9')
  || (c >= 'A' && c <= 'H')
  || (c >= 'J' && c <= 'N')
  || (c >= 'P' && c <= 'Z')
  || (c >= 'a' && c <= 'k')
  || (c >= 'm' && c <= 'z')

let is_bech32_char c =
  let c = Char.lowercase_ascii c in
  String.contains "qpzry9x8gf2tvdw0s3jn54khce6mua7l" c

let for_all_chars pred s start len =
  let rec loop i =
    if i >= start + len then true
    else if pred s.[i] then loop (i + 1)
    else false
  in
  loop start

let starts_with ~prefix s =
  let plen = String.length prefix in
  String.length s >= plen && String.sub s 0 plen = prefix

let detect_address_poisoning ~candidate ~trusted =
  let a = String.lowercase_ascii (String.trim candidate) in
  let b = String.lowercase_ascii (String.trim trusted) in
  let la = String.length a in
  let lb = String.length b in
  if la < 12 || lb < 12 || a = b then false
  else
    String.sub a 0 5 = String.sub b 0 5
    && String.sub a (la - 4) 4 = String.sub b (lb - 4) 4

let valid_syntax chain addr =
  let len = String.length addr in
  match chain with
  | "EVM" ->
      len = 42 && starts_with ~prefix:"0x" addr && for_all_chars is_hex_char addr 2 40
  | "BTC" ->
      ((starts_with ~prefix:"1" addr || starts_with ~prefix:"3" addr)
      && len >= 26 && len <= 35 && for_all_chars is_base58_char addr 0 len)
      || (starts_with ~prefix:"bc1" (String.lowercase_ascii addr)
         && len >= 28 && len <= 90 && for_all_chars is_bech32_char addr 3 (len - 3))
  | "SOL" ->
      len >= 32 && len <= 44 && for_all_chars is_base58_char addr 0 len
  | "XRP" ->
      starts_with ~prefix:"r" addr && len >= 25 && len <= 35 && for_all_chars is_base58_char addr 0 len
  | "XLM" ->
      starts_with ~prefix:"G" addr && len = 56
  | "ATOM" ->
      starts_with ~prefix:"cosmos1" addr && len = 45 && for_all_chars is_bech32_char addr 7 38
  | "TRX" ->
      starts_with ~prefix:"T" addr && len = 34 && for_all_chars is_base58_char addr 0 len
  | "SUI" ->
      len = 66 && starts_with ~prefix:"0x" addr && for_all_chars is_hex_char addr 2 64
  | "TON" ->
      (starts_with ~prefix:"EQ" addr || starts_with ~prefix:"UQ" addr) && len = 48
  | _ -> false

let requires_memo chain =
  match String.uppercase_ascii (String.trim chain) with
  | "XRP" | "XLM" | "ATOM" | "TON" | "HBAR" | "EOS" -> true
  | _ -> false

let validate ?(memo = "") ?(trusted = "") chain address =
  let code = String.uppercase_ascii (String.trim chain) in
  let clean_addr = String.trim address in
  let clean_memo = String.trim memo in
  let supported = [ "EVM"; "BTC"; "SOL"; "XRP"; "XLM"; "ATOM"; "TRX"; "SUI"; "TON" ] in
  if not (List.mem code supported) then
    { valid = false; code = "UNSUPPORTED_CHAIN"; chain = code; message = "Unsupported chain: " ^ code }
  else if clean_addr = "" || not (valid_syntax code clean_addr) then
    { valid = false; code = "INVALID_ADDRESS_SYNTAX"; chain = code; message = "Invalid address format for " ^ code }
  else if requires_memo code && clean_memo = "" then
    { valid = false; code = "MISSING_MANDATORY_MEMO"; chain = code; message = code ^ " requires a mandatory Memo/Destination Tag" }
  else if code = "XRP" && (String.length clean_memo > 10 || not (for_all_chars is_digit clean_memo 0 (String.length clean_memo))) then
    { valid = false; code = "INVALID_MEMO_FORMAT"; chain = code; message = "XRP Destination Tag must be numeric" }
  else if String.trim trusted <> "" && detect_address_poisoning ~candidate:clean_addr ~trusted then
    { valid = false; code = "ADDRESS_POISONING_ALERT"; chain = code; message = "Prefix/suffix address-poisoning lookalike detected" }
  else
    { valid = true; code = "VALID_VERIFIED"; chain = code; message = "Verified valid " ^ code ^ " address" }
