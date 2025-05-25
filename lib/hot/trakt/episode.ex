defmodule Hot.Trakt.Episode do
  use Ash.Resource,
    otp_app: :hot,
    domain: Hot.Trakt,
    data_layer: AshSqlite.DataLayer

  sqlite do
    table "episodes"
    repo Hot.Repo
  end

  actions do
    defaults [:read]

    create :create do
      primary? true
      upsert? true
      upsert_identity :unique_season_number

      accept [:plays, :number, :last_watched_at]
    end
  end

  attributes do
    uuid_v7_primary_key :id

    attribute :number, :integer do
      allow_nil? false
    end

    attribute :last_watched_at, :datetime

    attribute :plays, :integer do
      allow_nil? false
    end
  end

  relationships do
    belongs_to :season, Hot.Trakt.Season do
      allow_nil? false
    end
  end

  identities do
    identity :unique_season_number, [:season_id, :number]
  end
end
