import envoy

pub fn shared_password() -> Result(String, Nil) {
  envoy.get("SHARED_PASSWORD")
}
