defmodule Hot.Trakt.Show do
  use Ash.Resource,
    otp_app: :hot,
    domain: Hot.Trakt,
    data_layer: AshSqlite.DataLayer

  import Ecto.Query

  sqlite do
    table "shows"
    repo Hot.Repo
  end

  actions do
    defaults [:read]
    default_accept [:title, :trakt_id, :imdb_id]

    create :create do
      upsert? true
      upsert_identity :unique_trakt_id

      argument :seasons, {:array, :map} do
        allow_nil? false
      end

      change manage_relationship(:seasons, type: :create)
    end

    action :count_episodes, :integer do
      argument :id, :uuid_v7, allow_nil?: false

      run fn input, _ ->
        count =
          from(sh in Hot.Trakt.Show,
            left_join: se in assoc(sh, :seasons),
            left_join: ep in assoc(se, :episodes),
            where: sh.id == ^input.arguments.id and not is_nil(ep.last_watched_at),
            select: count(ep.id)
          )
          |> Hot.Repo.one!()

        {:ok, count}
      end
    end

    action :recent_shows_by_year, :map do
      run fn _, _ ->
        year_fragment =
          shows =
          from(sh in Hot.Trakt.Show,
            left_join: se in assoc(sh, :seasons),
            left_join: ep in assoc(se, :episodes),
            select: %{
              year: fragment("strftime('%Y', ?)", ep.last_watched_at),
              title: sh.title,
              id: sh.id
            },
            group_by: [sh.id, fragment("strftime('%Y', ?)", ep.last_watched_at)]
          )
          |> Hot.Repo.all()
          |> Enum.group_by(& &1.year, &Function.identity/1)

        {:ok, shows}
      end
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

    attribute :imdb_id, :string
  end

  relationships do
    has_many :seasons, Hot.Trakt.Season
  end

  identities do
    identity :unique_title, [:title]
    identity :unique_trakt_id, [:trakt_id]
  end
end
