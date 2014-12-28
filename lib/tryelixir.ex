defmodule Tryelixir do
  use Application

  def start(_type, _args) do
    Tryelixir.Supervisor.start_link()
  end
end
