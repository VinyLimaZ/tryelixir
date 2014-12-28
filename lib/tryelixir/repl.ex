defmodule Tryelixir.Repl do
  @moduledoc """
  Exposes the REPL API and serves as a supervisor for the different
  `Tryelixir.Repl.Interpreter` processes.
  """

  use Supervisor

  def start_link() do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  @doc """
  Adds a `Tryelixir.Repl.Interpreter` process to the supervisor tree.
  """
  def new() do
    Supervisor.start_child(__MODULE__, [])
  end

  @doc """
  Evaluate the given `input` on the REPL server `pid`.
  """
  defdelegate eval(pid, input), to: Tryelixir.Repl.Server

  # Supervisor callbacks.

  def init([]) do
    tree = [
      worker(Tryelixir.Repl.Server, [],
        restart: :transient,
        shutdown: :brutal_kill)
    ]

    supervise(tree, strategy: :simple_one_for_one, max_restarts: 10, max_seconds: 10)
  end
end
