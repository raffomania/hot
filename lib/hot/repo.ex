defmodule Hot.Repo do
  use AshSqlite.Repo,
    otp_app: :hot
end
