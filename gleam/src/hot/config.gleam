import envoy

pub fn shared_password() -> Result(String, Nil) {
  envoy.get("SHARED_PASSWORD")
}

pub fn secret_key_base() -> Result(String, Nil) {
  envoy.get("SECRET_KEY_BASE")
}
