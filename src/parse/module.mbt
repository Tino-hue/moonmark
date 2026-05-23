pub struct Module {
  name : String
  version : String
  deps : Map[String, String]
} derive(Show)

pub fn parse_mod_json(content : String) -> Result[Module, String] {
  // TODO: Implement JSON parsing
  Err("Not implemented")
}
