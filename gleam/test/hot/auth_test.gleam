import envoy
import gleeunit/should
import hot/auth/shared_auth

pub fn validate_password_correct_test() {
  envoy.set("SHARED_PASSWORD", "test_password")
  shared_auth.validate_password("test_password")
  |> should.be_true
}

pub fn validate_password_incorrect_test() {
  envoy.set("SHARED_PASSWORD", "test_password")
  shared_auth.validate_password("wrong_password")
  |> should.be_false
}

pub fn validate_password_empty_test() {
  envoy.set("SHARED_PASSWORD", "test_password")
  shared_auth.validate_password("")
  |> should.be_false
}

pub fn validate_password_no_env_var_test() {
  envoy.unset("SHARED_PASSWORD")
  shared_auth.validate_password("anything")
  |> should.be_false
}
