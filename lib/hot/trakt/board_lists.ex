defmodule Hot.Trakt.BoardLists do
  @moduledoc """
  Configuration module for board lists with integer-to-title mapping.

  This module defines the mapping between list IDs and their display titles,
  allowing for stable card relationships while supporting changeable titles.
  """

  @default_lists %{
    1 => %{title: "Trailers", position: 0},
    2 => %{title: "Watching", position: 1},
    3 => %{title: "Cancelled", position: 2},
    4 => %{title: "Finished", position: 3}
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
  def get_all_lists(), do: get_config()

  @doc """
  Gets all list IDs in position order.
  """
  def get_ordered_list_ids() do
    get_config()
    |> Enum.sort_by(fn {_id, config} -> config.position end)
    |> Enum.map(fn {id, _config} -> id end)
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
