defmodule Hot.Repo.Migrations.RecreateCardsWithFloatPosition do
  @moduledoc """
  Recreates the cards table with float position field, preserving existing data.
  SQLite doesn't support ALTER COLUMN, so we need to recreate the table.
  """

  use Ecto.Migration

  def up do
    # Create new table with float position
    create table(:cards_new, primary_key: false) do
      add :id, :binary_id, primary_key: true, null: false
      add :title, :text, default: ""
      add :description, :text
      add :position, :float, null: false, default: 0.0
      add :list_title, :text, null: false
      add :show_id, references(:shows, type: :binary_id, on_delete: :nothing)
      add :inserted_at, :naive_datetime_usec, null: false
      add :updated_at, :naive_datetime_usec, null: false
    end

    # Copy data from old table, converting integer positions to floats
    execute """
    INSERT INTO cards_new (id, title, description, position, list_title, show_id, inserted_at, updated_at)
    SELECT id, title, description, CAST(position AS REAL), list_title, show_id, inserted_at, updated_at
    FROM cards
    """

    # Drop old table and rename new one
    drop table(:cards)
    execute "ALTER TABLE cards_new RENAME TO cards"

    # Recreate indexes if needed
    create index(:cards, [:show_id])
  end

  def down do
    # Create old table with integer position
    create table(:cards_old, primary_key: false) do
      add :id, :binary_id, primary_key: true, null: false
      add :title, :text, default: ""
      add :description, :text
      add :position, :bigint, null: false, default: 0
      add :list_title, :text, null: false
      add :show_id, references(:shows, type: :binary_id, on_delete: :nothing)
      add :inserted_at, :naive_datetime_usec, null: false
      add :updated_at, :naive_datetime_usec, null: false
    end

    # Copy data back, converting float positions to integers
    execute """
    INSERT INTO cards_old (id, title, description, position, list_title, show_id, inserted_at, updated_at)
    SELECT id, title, description, CAST(position AS INTEGER), list_title, show_id, inserted_at, updated_at
    FROM cards
    """

    # Drop new table and rename old one
    drop table(:cards)
    execute "ALTER TABLE cards_old RENAME TO cards"

    # Recreate indexes if needed
    create index(:cards, [:show_id])
  end
end
