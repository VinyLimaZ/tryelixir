defmodule Tryelixir.Eval do
  @moduledoc """
  Eval module for tryelixir, most of the code is the same as IEx.Server
  """

  @doc """
  Eval loop for a tryelixir session. It does the following:

    * read input
    * check if the code being evaluated is allowed
    * trap exceptions in the code being evaluated
    * keep expression history
  """
  def start() do
    # TODO: handle history
    IO.puts "Interactive Elixir (#{System.version}) - (type h() ENTER for help)"
    eval_loop(IEx.boot_config [])
  end

  defp eval_loop(config) do
    counter = config.counter
    code    = config.cache
    line    = io_get(config)

    unless line == :eof do
      new_config =
        try do
          eval(code, line, counter, config)
        rescue
          exception ->
            print_exception(exception)
            config.cache('')
        catch
          kind, error ->
            print_error(kind, error)
            config.cache('')
        end

      eval_loop(new_config)
    end
  end

  # The expression is parsed to see if it's well formed.
  # If parsing succeeds the AST is checked to see if the code is allowed,
  # if it is, the AST is evaluated.
  #
  # If parsing fails, this might be a TokenMissingError which we treat in
  # a special way (to allow for continuation of an expression on the next
  # line in the `eval_loop`). In case of any other error, we let :elixir_translator
  # to re-raise it.
  #
  # Returns updated config.
  @break_trigger '#iex:break\n'
  defp eval(_, @break_trigger, _, config=IEx.Config[cache: '']) do
    # do nothing
    config
  end

  defp eval(_, @break_trigger, line_no, _) do
    :elixir_errors.parse_error(line_no, "iex", 'incomplete expression', [])
  end

  defp eval(code_so_far, latest_input, line_no, config) do
    code = code_so_far ++ latest_input
    case :elixir_translator.forms(code, line_no, "iex", []) do
      { :ok, forms } ->
        if is_safe?(forms) do
          { result, new_binding, scope } =
            :elixir.eval_forms(forms, config.binding, config.scope)

          io_put result

          config = config.cache(code).scope(nil).result(result)
          config.update_counter(&1+1).cache('').binding(new_binding).scope(scope).result(nil)
        else
          raise "restricted"
        end

      { :error, { line_no, error, token } } ->
        if token == [] do
          # Update config.cache in order to keep adding new input to
          # the unfinished expression in `code`
          config.cache(code)
        else
          # Encountered malformed expression
          :elixir_errors.parse_error(line_no, "iex", error, token)
        end
    end
  end

  # Check if the AST contains non allowed code, returns false if it does,
  # true otherwise.
  @allowed [List, Enum, String]
  @allowed_funs [:fn, :'->', :&, :=, :==, :===, :>=, :<=, :!=, :!==, :>,
                 :<, :and, :or, :||, :&&, :!, :*, :+, :-, :/, :++, :--, :<>]

  # allow Kernel.access
  defp is_safe?({{:., _, [:'Elixir.Kernel', :access]}, _, _}) do
    true
  end

  # check modules
  defp is_safe?({{:., _, [module, _]}, _, args}) do
    module = Macro.expand(module, __ENV__)
    if module in @allowed do
      is_safe?(args)
    else
      false
    end
  end

  # used with :fn
  defp is_safe?([do: args]) do
    is_safe?(args)
  end

  # used with :'->'
  defp is_safe?({left, _, right}) when is_list(left) do
    is_safe?(left) and is_safe?(right)
  end

  # check local functions
  defp is_safe?({dot, _, args}) when args != nil do
    if dot in @allowed_funs do
      is_safe?(args)
    else
      false
    end
  end

  defp is_safe?(lst) when is_list(lst) do
    Enum.all?(lst, fn(x) -> is_safe?(x) end)
  end

  defp is_safe?(_) do
    true
  end

  defp io_get(config) do
    prefix = if config.cache != [], do: "..."

    prompt = "#{prefix || "iex"}(#{config.counter})> "

    case IO.gets(:stdio, prompt) do
      :eof -> :eof
      { :error, _ } -> ''
      data -> :unicode.characters_to_list(data)
    end
  end

  defp io_put(result) do
    IO.puts "#{inspect result}"
  end

  defp print_exception(exception) do
    IO.puts "** (#{inspect exception.__record__(:name)}) #{exception.message}"
  end

  defp print_error(kind, reason) do
    IO.puts "** (#{kind}) #{inspect(reason)}"
  end
end
