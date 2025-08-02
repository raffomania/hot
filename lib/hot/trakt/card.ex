defmodule Hot.Trakt.Card do
  use Ash.Resource,
    otp_app: :hot,
    domain: Hot.Trakt,
    data_layer: AshSqlite.DataLayer

  sqlite do
    table "cards"
    repo Hot.Repo
  end

  actions do
    defaults [:read, :destroy]
    default_accept [:title, :description, :show_id]

    create :create do
      primary? true
      accept [:title, :description, :list_id, :show_id]

      change Hot.Trakt.Changes.AssignPosition
    end

    update :update do
      primary? true
      accept [:title, :description, :show_id, :position]
    end

    # Custom action for moving cards with position management
    update :move_to_position do
      accept []
      require_atomic? false

      argument :new_list_id, :integer, allow_nil?: false
      argument :target_index, :integer, allow_nil?: false

      change Hot.Trakt.Changes.MoveToPosition
    end

    # Bulk action for rebalancing positions when needed
    update :rebalance_positions do
      accept []
      require_atomic? false

      argument :list_id, :integer, allow_nil?: false

      change Hot.Trakt.Changes.RebalancePositions
    end
  end

  attributes do
    uuid_v7_primary_key :id

    attribute :title, :string do
      allow_nil? true
      default ""
    end

    attribute :description, :string

    attribute :position, :float do
      allow_nil? false
      default 0.0
    end

    attribute :list_id, :integer do
      allow_nil? false
    end

    timestamps()
  end

  relationships do
    belongs_to :show, Hot.Trakt.Show
  end
end
