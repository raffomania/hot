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
    defaults [:read]
    default_accept [:title, :trakt_id]

    create :create do
      upsert? true
      upsert_identity :unique_trakt_id

      argument :seasons, {:array, :map} do
        allow_nil? false
      end

      change manage_relationship(:seasons, type: :create)
    end
  end

  attributes do
    uuid_v7_primary_key :id

    attribute :title, :string do
      allow_nil? false
    end

    attribute :trakt_id, :integer do
      allow_nil? false
    end
  end

  relationships do
    has_many :seasons, Hot.Trakt.Season
  end

  identities do
    identity :unique_title, [:title]
    identity :unique_trakt_id, [:trakt_id]
  end
end
