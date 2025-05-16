defmodule Hot.Trakt.Show do
  use Ash.Resource,
    otp_app: :hot,
    domain: Hot.Trakt,
    data_layer: AshSqlite.DataLayer

  sqlite do
    table "shows"
    repo Hot.Repo
  end

  actions do
    defaults [:read, create: []]
    default_accept [:title, :trakt_id]
  end

  attributes do
    uuid_v7_primary_key :id

    attribute :title, :string do
      allow_nil? false
    end

    attribute :trakt_id, :string do
      allow_nil? false
    end
  end
end
