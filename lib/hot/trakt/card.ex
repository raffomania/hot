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
    defaults [:destroy]
    default_accept [:title, :description, :show_id]

    read :read do
      primary? true
    end

    read :active_cards do
      filter expr(archived == false)
    end

    read :archived_cards do
      filter expr(archived == true)
    end

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

    # Archive a card
    update :archive do
      accept []
      require_atomic? false

      change set_attribute(:archived, true)
      change set_attribute(:archived_at, &DateTime.utc_now/0)
    end

    # Unarchive a card and move to "new" list
    update :unarchive do
      accept []
      require_atomic? false

      change set_attribute(:archived, false)
      change set_attribute(:archived_at, nil)
      change set_attribute(:list_id, 1)
      change Hot.Trakt.Changes.AssignPosition
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

    attribute :archived, :boolean do
      allow_nil? false
      default false
    end

    attribute :archived_at, :utc_datetime do
      allow_nil? true
    end

    timestamps()
  end

  relationships do
    belongs_to :show, Hot.Trakt.Show
  end
end
