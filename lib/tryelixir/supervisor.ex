defmodule Tryelixir.Supervisor do
  @moduledoc false

  use Supervisor

  def start_link() do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  # Supervisor callbacks.

  def init([]) do
    tree = [
      supervisor(Tryelixir.Repl, []),
      worker(Tryelixir.Watcher, [])
    ]

    supervise(tree, strategy: :one_for_one, max_restarts: 10, max_seconds: 10)
  end
end
