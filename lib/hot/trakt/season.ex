defmodule Hot.Trakt.Season do
  use Ash.Resource,
    otp_app: :hot,
    domain: Hot.Trakt,
    data_layer: AshSqlite.DataLayer

  sqlite do
    table "seasons"
    repo Hot.Repo
  end

  actions do
    defaults [:read]
    default_accept [:number]

    create :create do
      primary? true

      argument :episodes, {:array, :map} do
        allow_nil? false
      end

      change manage_relationship(:episodes, type: :create)
    end
  end

  attributes do
    uuid_v7_primary_key :id

    attribute :number, :integer do
      allow_nil? false
    end
  end

  relationships do
    belongs_to :show, Hot.Trakt.Show do
      allow_nil? false
    end

    has_many :episodes, Hot.Trakt.Episode
  end
end
