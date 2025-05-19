defmodule Hot.Trakt do
  use Ash.Domain,
    otp_app: :hot

  resources do
    resource Hot.Trakt.Show
    resource Hot.Trakt.Episode
    resource Hot.Trakt.Season
  end
end
