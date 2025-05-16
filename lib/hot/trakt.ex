defmodule Hot.Trakt do
  use Ash.Domain,
    otp_app: :hot

  resources do
    resource Hot.Trakt.Show
  end
end
