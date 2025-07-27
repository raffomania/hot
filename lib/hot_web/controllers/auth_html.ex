defmodule HotWeb.AuthHTML do
  @moduledoc """
  This module contains pages rendered by AuthController.
  """
  use HotWeb, :html

  embed_templates "auth_html/*"
end
