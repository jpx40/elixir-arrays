defmodule Array.Implementations.ErlangArray do
  @moduledoc """
  Wraps the Erlang [`:array`](http://erlang.org/doc/man/array.html) module.

  These kinds of Array use a 'functional tree' format,
  with a leaf size of 10 nodes wide ([ref.](https://github.com/erlang/otp/blob/maint/lib/stdlib/src/array.erl#L108)).

  Common operations like element access thus take O(log10(n)) time.

  Note that when no custom default value is specified,
  `nil` will be used, rather than `:array`'s default of `:undefined`.
  """

  alias __MODULE__

  defstruct len: 0, contents: :array.new(default: nil)

  @doc """
  Create an `%ErlangArray{}`-struct from an `:array`-record.


      iex> :array.new([]) |> ErlangArray.from_raw()
      #Array.Implementations.ErlangArray<[]>
  """
  def from_raw(raw_array) do
    %ErlangArray{len: :array.size(raw_array), contents: raw_array}
  end

  @doc """
  Turn an %ErlangArray{len: len, }-struct back into an `:array`-record.

        iex> Array.new([1, 2, 3], implementation: Array.Implementations.ErlangArray) |> ErlangArray.to_raw()
        {:array, 3, 10, nil, {1, 2, 3, nil, nil, nil, nil, nil, nil, nil}}
  """
  def to_raw(%ErlangArray{len: _, contents: contents}) do
    contents
  end

  if Code.ensure_loaded?(FunLand.Mappable) do
    Module.eval_quoted(
      __MODULE__,
      quote do
        use FunLand.Mappable

        @doc """
        Implementation for `FunLand.Mappable.map`.

        Note that `FunLand` is an optional dependency of `Array` so you need to add it to your `mix.exs` dependencies manually to use it.
        """
        def map(array, fun), do: Array.Protocol.map(array, fun)
      end
    )
  end

  if Code.ensure_loaded?(FunLand.Reducible) do
    Module.eval_quoted(
      __MODULE__,
      quote do
        use FunLand.Reducible, auto_enumerable: false

        @impl FunLand.Reducible
        @doc """
        Implementation for `FunLand.Reducible.reduce`.

        Note that `FunLand` is an optional dependency of `Array` so you need to add it to your `mix.exs` dependencies manually to use it.
        """
        def reduce(array = %ErlangArray{len: len}, acc, fun) do
          Array.Protocol.reduce(array, acc, fun)
        end
      end
    )
  end

  @behaviour Access

  @impl Access
  def fetch(%ErlangArray{contents: contents}, index) when index >= 0 do
    if index >= :array.size(contents) do
      :error
    else
      {:ok, :array.get(index, contents)}
    end
  end

  def fetch(%ErlangArray{contents: contents}, index) when index < 0 do
    size = :array.size(contents)

    if index < -size do
      :error
    else
      {:ok, :array.get(index + size, contents)}
    end
  end

  @undefined_pop_message """
                         There is no efficient implementation possible to remove an element from a random location in an array, so `Access.pop/2` (and returning `:pop` from `Access.get_and_update/3` ) are not supported by #{inspect(__MODULE__)}. If you want to remove the last element, use `Array.extract/1`.
                         """
                         |> String.trim()

  @impl Access
  def get_and_update(array = %ErlangArray{len: len, contents: contents}, index, function)
      when index >= 0 do
    if index >= :array.size(contents) do
      raise ArgumentError
    else
      value = :array.get(index, contents)

      case function.(value) do
        {get, new_value} ->
          new_contents = :array.set(index, new_value, contents)
          {get, %ErlangArray{array | contents: new_contents, len: len}}

        :pop ->
          raise ArgumentError, @undefined_pop_message
      end
    end
  end

  @impl Access
  def get_and_update(array = %ErlangArray{len: len, contents: _}, index, function)
      when index < 0 do
    if index < len do
      raise ArgumentError
    else
      get_and_update(array, index + len, function)
    end
  end

  @impl Access
  def pop(%ErlangArray{}, _index) do
    raise ArgumentError, @undefined_pop_message
  end

  @doc false
  def build_slice(%ErlangArray{contents: contents}, start, length, into) do
    for index <- start..(start + length - 1), into: into do
      :array.get(index, contents)
    end
  end

  defimpl Array.Protocol do
    alias Array.Implementations.ErlangArray

    @impl true
    def size(%ErlangArray{contents: contents}) do
      :array.size(contents)
    end

    @impl true
    def map(array = %ErlangArray{len: len, contents: contents}, fun) do
      new_contents = :array.map(fn _index, val -> fun.(val) end, contents)
      %ErlangArray{array | contents: new_contents, len: len}
    end

    @impl true
    def reduce(%ErlangArray{len: _, contents: contents}, acc, fun) do
      :array.foldl(fn _index, val, acc -> fun.(val, acc) end, acc, contents)
    end

    @impl true
    def reduce_right(%ErlangArray{len: _, contents: contents}, acc, fun) do
      :array.foldr(fn _index, val, acc -> fun.(acc, val) end, acc, contents)
    end

    @impl true
    def get(%ErlangArray{len: _, contents: contents}, index) do
      if index < 0 do
        :array.get(index + :array.size(contents), contents)
      else
        :array.get(index, contents)
      end
    end

    @impl true
    def len(array) do
      array.len
    end

    @impl true
    def replace(array = %ErlangArray{len: len, contents: contents}, index, item) do
      new_contents =
        if index < 0 do
          :array.set(index + :array.size(contents), item, contents)
        else
          :array.set(index, item, contents)
        end

      %ErlangArray{array | contents: new_contents, len: len}
    end

    @impl true
    def append(array = %ErlangArray{len: len, contents: contents}, item) do
      len = len + 1
      new_contents = :array.set(len, item, contents)
      %ErlangArray{array | contents: new_contents, len: len}
    end

    @impl true
    def resize(array = %ErlangArray{len: len, contents: contents}, new_size, default) do
      changed = change_default(contents, default)
      new_contents = :array.resize(new_size, changed)
      %ErlangArray{array | contents: new_contents, len: len}
    end

    # NOTE: We depend on the exact implementation of the `:array` record here.
    # This is _probably_ fine, but important to keep in mind.
    # Changing the default is a O(1) operation, because:
    # - All elements between `:array.sparse_size` and the next multiple of 10 are physically stored.
    #   But these are at most 9 elements.
    # - All elements after the next multiple of 10 are not physically stored at all.
    defp change_default(raw_array, new_default) do
      sparse_size = :array.sparse_size(raw_array)
      up_to_next_multiple_of_10 = 10 * div(sparse_size, 10) + 10 - 1
      {:array, a, b, _old_default, vals} = raw_array
      new_array = {:array, a, b, new_default, vals}

      Enum.reduce(sparse_size..up_to_next_multiple_of_10, new_array, fn index, arr ->
        :array.set(index, new_default, arr)
      end)
    end

    @impl true
    def extract(array = %ErlangArray{len: len, contents: contents}) do
      case :array.size(contents) do
        0 ->
          {:error, :empty}

        size ->
          index = size - 1
          elem = :array.get(index, contents)
          contents_rest = :array.resize(index, contents)
          array_rest = %ErlangArray{array | contents: contents_rest, len: len}
          {:ok, {elem, array_rest}}
      end
    end

    @impl true
    def to_list(%ErlangArray{contents: contents}) do
      :array.to_list(contents)
    end

    @impl true
    def slice(array = %ErlangArray{len: _, contents: contents}, start, amount) do
      @for.build_slice(array, start, amount, empty(default: :array.default(contents)))
    end

    @impl true
    def empty(options) when is_list(options) do
      contents = :array.new([default: nil] ++ options)
      %ErlangArray{len: :array.size(contents), contents: contents}
    end
  end
end
