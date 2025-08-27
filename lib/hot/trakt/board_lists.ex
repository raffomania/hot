defmodule Hot.Trakt.BoardLists do
  @moduledoc """
  Configuration module for board lists with integer-to-title mapping.

  This module defines the mapping between list IDs and their display titles,
  allowing for stable card relationships while supporting changeable titles.
  """

  @default_lists %{
    1 => %{title: "new", position: 0},
    2 => %{title: "watching", position: 1},
    3 => %{title: "finished", position: 2},
    4 => %{title: "cancelled", position: 3}
  }

  @doc """
  Gets the title for a given list ID.
  Returns nil if the list ID doesn't exist.
  """
  def get_title(list_id), do: get_config()[list_id][:title]

  @doc """
  Gets the position for a given list ID.
  Returns nil if the list ID doesn't exist.
  """
  def get_position(list_id), do: get_config()[list_id][:position]

  @doc """
  Gets the complete configuration for all lists.
  """
  def get_all_lists(), do: get_config() |> Enum.sort_by(fn {_id, config} -> config.position end)

  @doc """
  Gets all list IDs in position order.
  """
  def get_ordered_list_ids() do
    get_config()
    |> Enum.sort_by(fn {_id, config} -> config.position end)
    |> Enum.map(fn {id, _config} -> id end)
  end

  @doc """
  Gets only the active lists (for board display).
  Returns lists with IDs 1 and 2 ("new" and "watching").
  """
  def get_active_lists() do
    get_config()
    |> Enum.filter(fn {id, _config} -> id in [1, 2] end)
    |> Enum.sort_by(fn {_id, config} -> config.position end)
  end

  @doc """
  Checks if a list ID is valid.
  """
  def valid_list_id?(list_id), do: Map.has_key?(get_config(), list_id)

  @doc """
  Legacy function for backward compatibility.
  Returns list configs in the old format.
  """
  def all_lists do
    get_config()
    |> Enum.sort_by(fn {_id, config} -> config.position end)
    |> Enum.map(fn {_id, config} -> config end)
  end

  defp get_config(), do: @default_lists
end
