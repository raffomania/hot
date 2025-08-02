defmodule Hot.Repo.Migrations.ReplaceListTitleWithListId do
  @moduledoc """
  Replaces list_title with list_id and drops all existing cards.

  This migration implements the changeable-list-titles-concept by:
  1. Dropping all existing cards (as specified in the plan)
  2. Removing the list_title column 
  3. Adding the list_id integer column
  """

  use Ecto.Migration

  def up do
    # Drop all existing cards as specified in the plan
    execute "DELETE FROM cards"

    # Recreate table structure with list_id instead of list_title
    # SQLite doesn't support ALTER COLUMN, so we need to recreate the table
    create table(:cards_new, primary_key: false) do
      add :id, :binary_id, primary_key: true, null: false
      add :title, :text, default: ""
      add :description, :text
      add :position, :float, null: false, default: 0.0
      add :list_id, :bigint, null: false
      add :show_id, references(:shows, type: :binary_id, on_delete: :nothing)
      add :inserted_at, :naive_datetime_usec, null: false
      add :updated_at, :naive_datetime_usec, null: false
    end

    # Drop old table and rename new one
    drop table(:cards)
    execute "ALTER TABLE cards_new RENAME TO cards"

    # Recreate indexes
    create index(:cards, [:show_id])
    create index(:cards, [:list_id])
  end

  def down do
    # Recreate table with list_title instead of list_id
    create table(:cards_old, primary_key: false) do
      add :id, :binary_id, primary_key: true, null: false
      add :title, :text, default: ""
      add :description, :text
      add :position, :float, null: false, default: 0.0
      add :list_title, :text, null: false
      add :show_id, references(:shows, type: :binary_id, on_delete: :nothing)
      add :inserted_at, :naive_datetime_usec, null: false
      add :updated_at, :naive_datetime_usec, null: false
    end

    # Drop all existing cards (data loss is acceptable going backwards)
    execute "DELETE FROM cards"

    # Drop new table and rename old one
    drop table(:cards)
    execute "ALTER TABLE cards_old RENAME TO cards"

    # Recreate indexes
    create index(:cards, [:show_id])
  end
end
