defmodule Hot.Trakt do
  use Ash.Domain,
    otp_app: :hot,
    extensions: [AshAdmin.Domain]

  admin do
    show? true
  end

  resources do
    resource Hot.Trakt.Show
    resource Hot.Trakt.Episode
    resource Hot.Trakt.Season
    resource Hot.Trakt.Card
  end
end
