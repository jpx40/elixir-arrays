# NOTE: We store the AST of the body of the module separately
# such that we can compile it one more time in the thest environment,
# but then with `ErlangArray` as default representation.
#
# This allows us to re-use all doctests for the ErlangArray as well as the MapArray.
contents =
  quote location: :keep do
    @current_default_array inspect(@default_array_implementation)

    @moduledoc """
    Well-structured Array with fast random-element-access for Elixir, offering a common interface with multiple implementations with varying performance guarantees that can be switched in your configuration.

    ## Using `Array`

    ### Some simple examples:

    #### Constructing Array

    By calling `Array.new` or `Array.empty`:

        iex> Array.new(["Dvorak", "Tchaikovsky", "Bruch"])
        ##{@current_default_array}<["Dvorak", "Tchaikovsky", "Bruch"]>

    By using `Collectable`:

        iex> [1, 2, 3] |> Enum.into(Array.new())
        ##{@current_default_array}<[1, 2, 3]>
        iex> for x <- 1..2, y <- 4..5, into: Array.new(), do: {x, y}
        ##{@current_default_array}<[{1, 4}, {1, 5}, {2, 4}, {2, 5}]>

    #### Some common array operations:

    - Indexing is fast.
    - The full Access calls are supported,
    - Variants of many common `Enum`-like functions that keep the result an array (rather than turning it into a list), are available.

          iex> words = Array.new(["the", "quick", "brown", "fox", "jumps", "over", "the", "lazy", "dog"])
          ##{@current_default_array}<["the", "quick", "brown", "fox", "jumps", "over", "the", "lazy", "dog"]>
          iex> Array.size(words) # Runs in constant-time
          9
          iex> words[3] # Indexing is fast
          "fox"
          iex> words = put_in(words[2], "purple") # All of `Access` is supported
          ##{@current_default_array}<["the", "quick", "purple", "fox", "jumps", "over", "the", "lazy", "dog"]>
          iex> Array.map(words, &String.upcase/1) # Map a function, keep result an array
          ##{@current_default_array}<["THE", "QUICK", "PURPLE", "FOX", "JUMPS", "OVER", "THE", "LAZY", "DOG"]>
          iex> lengths = Array.map(words, &String.length/1)
          ##{@current_default_array}<[3, 5, 6, 3, 5, 4, 3, 4, 3]>
          iex> Array.reduce(lengths, 0, &Kernel.+/2) # `reduce_right` is supported as well.
          36

    Concatenating Array:

        iex> Array.new([1, 2, 3]) |> Array.concat(Array.new([4, 5, 6]))
        ##{@current_default_array}<[1, 2, 3, 4, 5, 6]>

    Slicing Array:

        iex> ints = Array.new(1..100)
        iex> Array.slice(ints, 9..19)
        ##{@current_default_array}<[10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20]>

    ### Rationale


    Algorithms that use Array can be used while abstracting away from the underlying representation.
    Which array implementation/representation is actually used, can then later be configured/compared, to make a trade-off between ease-of-use and time/memory efficiency.

    `Array` itself comes with two built-in implementations:

    - `Array.Implementations.ErlangArray` wraps the Erlang `:array` module, allowing this time-tested implementation to be used with all common Elixir protocols and syntactic sugar.
    - `Array.Implementations.MapArray` is a simple implementation that uses a map with sequential integers as keys.

    By default, #{@default_array_implementation} is used when creating new array objects, but this can be configured by either changing the default in your whole application, or by passing an option to a specific invocation of [`new/0-2`](`new/0`), or [`empty/0-1`](`empty/0`).


    Implementations provided by other libraries:

    - [ArrayAja](https://github.com/Qqwy/elixir-Array_aja) adds support for [Aja](https://github.com/sabiwara/aja)'s `A.Vector`, which is an implementation of a 'Hickey Trie' vector. For most operations, it significantly outperforms `ErlangArray` and `MapArray`.


    ### Protocols

    Besides being able to use all functions in this module,
    one can use the following protocols and behaviours with them:

    - From Elixir's standard library:
      - `Enumerable`: Iterating over Array
      - `Collectable`: Creating Array from collections
      - the `Access` behaviour: access a particular element using square brackets, `put_in` etc.

    - From common container libraries:
      - `Insertable`: Append a single item from the end of an array
      - `Extractable`: Take a single item from the end of an array
      - `FunLand.Mappable`: Map a function over each element in the array, creating a new array with the results
      - `FunLand.Reducible`: Reduce an array to a single value.


    Note: `FunLand` is an optional dependency of this library, so its functionality will only be available if `:fun_land` is also added to your `mix.exs` dependencies list.

    #### Enumerable

        iex> myarray = Array.new([2, 1, 4, 2, 0])
        iex> Enum.sort(myarray)
        [0, 1, 2, 2, 4]
        iex> Enum.count(myarray)
        5
        iex> Enum.with_index(myarray)
        [{2, 0}, {1, 1}, {4, 2}, {2, 3}, {0, 4}]
        iex> Enum.slice(myarray, 1, 3)
        [1, 4, 2]

        iex> names = Array.new(["Ernie", "Bert", "Kermit"])
        iex> names |> Stream.map(&String.upcase/1) |> Enum.into(Array.new())
        ##{@current_default_array}<["ERNIE", "BERT", "KERMIT"]>

        iex> foods = Array.new(["Cheese", "Strawberries", "Cookies"])
        iex> foods |> Enum.take(2)
        ["Cheese", "Strawberries"]

        iex> Array.new([1, 2, 3]) |> Stream.zip(Array.new([4, 5, 6])) |> Enum.take(2)
        [{1, 4}, {2, 5}]


    #### Collectable

        iex> [10, 20, 30, 40] |> Enum.into(Array.new())
        ##{@current_default_array}<[10, 20, 30, 40]>


    #### Access

    Fast random-element access and updates are supported.


        iex> arr = Array.new([1, 2, 3, 4])
        iex> arr = put_in(arr[2], 33)
        ##{@current_default_array}<[1, 2, 33, 4]>
        iex> arr = update_in(arr[1], (&(&1 * -2)))
        ##{@current_default_array}<[1, -4, 33, 4]>
        iex> update_in(arr[-1], (&(&1 + 1)))
        ##{@current_default_array}<[1, -4, 33, 5]>

    Popping from a random location however, is not.
    Only removals of the last element of the array are fast.
    For this, use `Array.extract/1`.

        iex> arr = Array.new([1, -4, 33, 5])
        iex> {33, _arr} = pop_in(arr[-2])
        ** (ArgumentError) There is no efficient implementation possible to remove an element from a random location in an array, so `Access.pop/2` (and returning `:pop` from `Access.get_and_update/3` ) are not supported by #{@current_default_array}. If you want to remove the last element, use `Array.extract/1`.

        iex> arr2 = Array.new([10, 20, 30])
        iex> {20, _arr2} = get_and_update_in(arr2[1], fn _ -> :pop end)
        ** (ArgumentError) There is no efficient implementation possible to remove an element from a random location in an array, so `Access.pop/2` (and returning `:pop` from `Access.get_and_update/3` ) are not supported by #{@current_default_array}. If you want to remove the last element, use `Array.extract/1`.

        iex> arr2 = Array.new([10, 20, 30])
        iex> {:ok, {value, arr2}} = Array.extract(arr2)
        iex> value
        30
        iex> arr2
        ##{@current_default_array}<[10, 20]>



    square-bracket access, `get_in`, `put_in` and `update_in` are very fast operations.
    Unless `pop`/`pop_in` is used for the last element in the array, is a very slow operation,
    as it requires moving of all elements after the given index in the array.

    Both positive indexes (counting from zero) and negative indexes
    (`-1` is the last element, `-2` the second-to-last element, etc.) are supported.

    However, if `positive_index > Array.size(array)` or `negative_index < -Array.size(array)`,
    an ArgumentError is raised (when trying to put a new value), or `:error` is returned when fetching a value:

        iex> arr = Array.new([1,2,3,4])
        iex> put_in(arr[4], 1234)
        ** (ArgumentError) argument error

        iex> arr = Array.new([1,2,3,4])
        iex> put_in(arr[-5], 100)
        ** (ArgumentError) argument error

        iex> arr = Array.new([1,2,3,4])
        iex> Access.fetch(arr, 4)
        :error
        iex> Access.fetch(arr, -5)
        :error
        iex> arr[4]
        nil
        iex> arr[-5]
        nil

        iex> arr = Array.new([1,2,3,4])
        iex> update_in(arr[8], fn x -> x * 2 end)
        ** (ArgumentError) argument error

        iex> arr = Array.new([1,2,3,4])
        iex> update_in(arr[-8], fn x -> x * 2 end)
        ** (ArgumentError) argument error

    #### Insertable

        iex> arr = Array.new()
        iex> {:ok, arr} = Insertable.insert(arr, 42)
        iex> {:ok, arr} = Insertable.insert(arr, 100)
        iex> arr
        ##{@current_default_array}<[42, 100]>

    #### Extractable

        iex> Extractable.extract(Array.new())
        {:error, :empty}
        iex> {:ok, {3, arr}} = Extractable.extract(Array.new([1, 2, 3]))
        iex> arr
        ##{@current_default_array}<[1, 2]>


    #### FunLand.Reducible

    Note: `FunLand` is an optional dependency of this library.

        iex> Array.new([1,2,3,4]) |> FunLand.reduce(0, &(&1+&2))
        10

    #### FunLand.Mappable

        iex> Array.new([1, 2, 3, 4]) |> FunLand.Mappable.map(fn x -> x * 2 end)
        ##{@current_default_array}<[2, 4, 6, 8]>

    ## Array vs Lists

    Elixir widely uses `List` as default collection type.
    Compared to lists, Array have the folowing differences:

    - Array keep track of their *size*. The size of a list needs to be computed.
    - Array allow fast¹ element *indexing*. Indexing later elements in a list slows down linearly in the size of the list.
    - Array allow fast *slicing*. For lists, this slows down the further away from the head of the list we are.
    - Pushing a single element to the _end_ of an array is fast¹. Pushing a single element to the end of a list is very slow (the whole list needs to be copied), taking linear time.
    - *Pushing* a single element to the _start_ of an array is slow, taking linear time (the whole array needs to be moved around). Pushing a single element to the head of a list is fast, taking constant time.
    - *Concatenating* Array takes time proportional to the size of the second array (individual elements are pushed to the end). Concatenating two lists takes time proportional to the length of the first list. This means that repeated appending
    - Array are always well-formed. In certain cases, Lists are allowed to be improper.
    - Many common operations in Elixir transform an enumerable into a list automatically. Array are made using `Array.new/0`, `Array.new/1` `Array.empty/0`, the `into:` option on a `for`, or `Enum.into`.

    ¹: Depending on the implementation, 'fast' is either _O(1)_ (constant time, regardless of array size) or _O(log(n))_ (logarithmic time, becoming a constant amount slower each time the array doubles in size.)

    The linear time many operations on lists take, means that the operation becomes twice as slow when the list doubles in size.

    ## Implementing a new Array type

    To add array-functionality to a custom datastructure, you'll need to implement the `Array.Protocol`.

    Besides these, you probably want to implement the above-mentioned protocols as well.
    You can look at the source code of `Array.CommonProtocolImplementations` for some hints as to how those protocols can be easily implemented, as many functions can be defined as simple wrappers on top of the functions that `Array.Protocol` itself already provides.
    """

    @typedoc """
    Any datatype implementing the `Array.Protocol`.
    """
    @type array :: Array.Protocol.t()

    @typedoc """
    An array of elements of type `element`.

    This type is equivalent to `t:array/0` but is especially useful for documentation.

    For example, imagine you define a function that expects an array of
    integers and returns an array of strings:

        @spec integers_to_strings(Array.array(integer())) :: Array.array(String.t())
        def integers_to_strings(integers) do
          Array.map(integers, &Integer.to_string/1)
        end
    """
    @typedoc since: "2.1.0"
    @type array(_element) :: array()

    @typedoc """
    An array index can be either a nonnegative index (up to the size of the array),
    or a negative index (then we count backwards from the size.)
    """
    @type index :: Array.Protocol.index()

    @typedoc """
    Type of the kind of value stored in the array.
    In practice, Array can store anything so this is an alias for `any`.
    """
    @type value :: Array.Protocol.value()

    @doc """
    Creates a new, empty, array.

        iex> Array.empty()
        ##{@current_default_array}<[]>


    ### Options

    - `implementation:` Module name of array-implementation to use.
    - When not specified, will use the implementation which is configured in `:Array, :default_array_implementation`,
    - When no configuration is specified either, #{@default_array_implementation} will be used by default.

          iex> Array.empty([implementation: Array.Implementations.MapArray])
          #Array.Implementations.MapArray<[]>

          iex> Array.empty([implementation: Array.Implementations.ErlangArray])
          #Array.Implementations.ErlangArray<[]>

    Any other option is passed on to the particular array implementation.
    Not all array implementations recognize all options.
    However, the following two options are very common (and supported by both built-in implementations, `Array.Implementations.ErlangArray` and `Array.Implementations.MapArray`):

    - `default:` Value that empty elements should start with. (Default: `nil`)
    - `size:` Size of the array at start. (Default: 0)

    #### Using the MapArray
        iex> Array.empty([default: 42, size: 5, implementation: Array.Implementations.MapArray])
        ##{@current_default_array}<[42, 42, 42, 42, 42]>

    #### Using the ErlangArray
        iex> Array.empty([default: "Empty" , size: 1, implementation: Array.Implementations.ErlangArray])
        #Array.Implementations.ErlangArray<["Empty"]>

    """
    def empty(options \\ []) do
      impl_module =
        Keyword.get(
          options,
          :implementation,
          default_array_implementation()
        )

      options = Keyword.delete(options, :implementation)
      Module.concat(Array.Protocol, impl_module).empty(options)
    end

    defp default_array_implementation() do
      # Application.get_env(:Array, :default_array_implementation, @default_array_implementation)
    Array.ErlangArray
    end
    
    
    @spec new(integer()) :: array()
  def new(size) when is_integer(size) do
    array = empty()
    resize(array,size)
  end
    @doc """
    Creates a new, empty array with default options.

        iex> Array.new()
        ##{@current_default_array}<[]>
    """
    @spec new() :: array()
    def new(), do: new([], [])

    @doc """
    Creates a new array, receiving its elements from the given `Enumerable`, with default options.
    """
    @spec new(Enum.t()) :: array()
    def new(enumerable), do: new(enumerable, [])

    
  
    @doc """
    Creates a new array, receiving its elements from the given `Enumerable`, with the given options.

    Which options are supported depends on the type of array.

        iex> Array.new([1, 2, 3])
        ##{@current_default_array}<[1, 2, 3]>

        iex> Array.new(["Hello"])
        ##{@current_default_array}<["Hello"]>

    """
    @spec new(Enum.t(), keyword) :: array()
    def new(enumerable, options) do
      Enum.into(enumerable, empty(options))
    end

    @doc """
    The number of elements in the array.

    Looking up the size of an array is fast: this function runs in constant time.

        iex> Array.new([2, 4, 6]) |> Array.size()
        3

        iex> Array.new([]) |> Array.size()
        0

    See also `resize/2`.
    """
    @spec size(array) :: non_neg_integer
    defdelegate size(array), to: Array.Protocol

    @doc """
    Maps a function over an array, returning a new array.

        iex> Array.new([1,2,3]) |> Array.map(fn val -> val * 2 end)
        ##{@current_default_array}<[2, 4, 6]>
    """
    @spec map(array, (current_value :: value -> updated_value :: value)) :: array
    defdelegate map(array, fun), to: Array.Protocol

    @doc """
    Reduce an array to a single value, by calling the provided accumulation function for each element, left-to-right.

    If the array is empty, the accumulator argument `acc` is returned as result immediately.
    Otherwise, the function is called on all elements in the array, in order, with `acc` as *second* argument.
    The result of each of these function calls creates the new accumulator passed to the next invocation.

        iex> Array.new([1, 2, 3]) |> Array.reduce(0, fn val, sum -> sum + val end)
        6

        iex> Array.new(["the", "quick", "brown", "fox"]) |> Array.reduce("", fn val, result -> result <> " " <> val end)
        " the quick brown fox"

        iex> Array.new([]) |> Array.reduce(1234, fn val, mul -> mul * val end)
        1234

    See also `reduce_right/3`.
    """
    @spec reduce(array, acc :: any, (item :: any, acc :: any -> any)) :: array
    defdelegate reduce(array, acc, fun), to: Array.Protocol

    @doc """
    Reduce an array to a single value, by calling the provided accumulation function for each element, right-to-left.


    If the array is empty, the accumulator argument `acc` is returned as result immediately.
    Otherwise, the function is called on all elements in the array, in reverse (right-to-left) order, with `acc` as *first* argument.
    The result of each of these function calls creates the new accumulator passed to the next invocation.

        iex> Array.new([1, 2, 3]) |> Array.reduce_right(0, fn sum, val -> sum + val end)
        6

        iex> Array.new(["the", "quick", "brown", "fox"]) |> Array.reduce_right("", fn result, val -> result <> " " <> val end)
        " fox brown quick the"

        iex> Array.new([]) |> Array.reduce_right(1234, fn mul, val -> mul * val end)
        1234


    See also `reduce/3`.

    """
    @spec reduce_right(array, acc :: any, (acc :: any, item :: any -> any)) :: array
    defdelegate reduce_right(array, acc, fun), to: Array.Protocol

    @doc """
    Retrieves the value stored in `array` of the element at `index`.

    Array indexes start at *zero*.

        iex> Array.new([3, 6, 9]) |> Array.get(0)
        3

        iex> Array.new([3, 6, 9]) |> Array.get(1)
        6

    As Array types also implement the `Access` behaviour,
    the `[]` (square-bracket) syntactic sugar can also be used:

        iex> myarray = Array.new([2, 4, 8])
        iex> myarray[0]
        2
        iex> myarray[1]
        4

    ## Negative indexes

    It is also possible to use negative indexes, to read elements starting from the right side of the array.
    For example, index `-1` works equivalently to `size - 1`, if your array has `size`  elements.


        iex> names = Array.new(["Alice", "Bob", "Charlie", "David"])
        iex> Array.get(names, -2)
        "Charlie"
        iex> names[-1]
        "David"

    """
    # TODO implement negative indexes here rather than impl-defined.
    @spec get(array, index) :: any
    defdelegate get(array, index), to: Array.Protocol

    @doc """
    Replaces the element in `array` at `index` with `value`.


        iex> Array.new([4, 5, 6]) |> Array.replace(1, 69)
        ##{@current_default_array}<[4, 69, 6]>

    Just like `get/2`, negative indices are supported.

        iex> Array.new([7, 8, 9]) |> Array.replace(-1, 33)
        ##{@current_default_array}<[7, 8, 33]>
    """
    # TODO implement negative indexes here rather than impl-defined.
    @spec replace(array, index, value :: any) :: array
    defdelegate replace(array, index, value), to: Array.Protocol

    @doc """
    Appends ('pushes') a single element to the end of the array.

        iex> Array.new([1, 2, 3]) |> Array.append(4)
        ##{@current_default_array}<[1, 2, 3, 4]>

    See also `extract/1`.
    """
    @spec append(array, item :: any) :: array
    defdelegate append(array, item), to: Array.Protocol

    @doc """
    Extracts ('pops') a single element from the end of the array.

    Returns `{:ok, item_that_was_removed, array_without_item}` if the array was non-empty.
    When called on an empty array, `{:error, :empty}` is returned.

        iex> {:ok, {elem, arr}} = Array.new([1,2,3,4]) |> Array.extract()
        iex> elem
        4
        iex> arr
        ##{@current_default_array}<[1, 2, 3]>

        iex> Array.new([]) |> Array.extract()
        {:error, :empty}

    See also `append/2`.
    """
    @spec extract(array) :: {:ok, {item :: any, array}} | {:error, :empty}
    defdelegate extract(array), to: Array.Protocol

    @doc """
    Changes the size of the array.

    When the array becomes larger, new elements at the end will al receive the `default` value.
    When the array becomes smaller, elements larger than the new `size` will be dropped.

        iex> Array.new([1, 2, 3]) |> Array.resize(6)
        ##{@current_default_array}<[1, 2, 3, nil, nil, nil]>

        iex> Array.new([1, 2, 3]) |> Array.resize(5, 42)
        ##{@current_default_array}<[1, 2, 3, 42, 42]>

        iex> Array.new([1, 2, 3]) |> Array.resize(1)
        ##{@current_default_array}<[1]>

        iex> Array.new([9, 8, 7]) |> Array.resize(0)
        ##{@current_default_array}<[]>

        iex> Array.new([1, 2, 3]) |> Array.resize(3)
        ##{@current_default_array}<[1, 2, 3]>

    See also `size/1`.
    """
    @spec resize(array, size :: non_neg_integer, default :: any) :: array
    def resize(array, size, default \\ nil) do
      Array.Protocol.resize(array, size, default)
    end

    @doc """
    Transforms the array into a list.

        iex> Array.new(["Joe", "Mike", "Robert"]) |> Array.to_list
        ["Joe", "Mike", "Robert"]
    """
    @spec to_list(array) :: list
    defdelegate to_list(array), to: Array.Protocol

    @doc """
    Returns an array where all elements of `right` are added to the end of `left`.

    `left` should be an array. `right` can be either an array or any other enumerable.

    Takes time proportional to the number of elements in `right`.
    Essentially, each element in `right` is appended to `left` in turn.

        iex> Array.new([1, 2, 3]) |> Array.concat(Array.new([4, 5, 6]))
        ##{@current_default_array}<[1, 2, 3, 4, 5, 6]>

        iex> Array.new([1, 2, 3]) |> Array.concat((1..10))
        ##{@current_default_array}<[1, 2, 3, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10]>

    """
    @doc since: "1.1.0"
    @spec concat(array(), array() | Enumerable.t()) :: array()
    def concat(left, right) do
      Enum.into(right, left)
    end

    @doc """
    Turns an array of Array (or other enumerable of enumerables) into a single array.

        iex> arr = Array.new([1, 2, 3])
        iex> Array.concat([arr, arr, arr])
        ##{@current_default_array}<[1, 2, 3, 1, 2, 3, 1, 2, 3]>

        iex> Array.concat([])
        #Array.Implementations.MapArray<[]>

    See also `concat/2`.
    """
    @doc since: "1.1.0"
    @spec concat(Enumerable.t()) :: array()
    def concat(enumerable_of_enumerables) do
      case Enum.split(enumerable_of_enumerables, 1) do
        {[], []} ->
          Array.new()

        {[first], rest} ->
          Enum.reduce(rest, first, &Enum.into/2)
      end
    end

    @doc """
    Returns a sub-array of the given array by `index_range`.

    `index_range` must be a `Range`. Given an array, it drops elements before
    `index_range.first` (zero-based), then it takes elements until element
    `index_range.last` (inclusively).

    Indexes are normalized, meaning that negative indexes will be counted from the
    end (for example, -1 means the last element of the array).

    If `index_range.last` is out of bounds, then it is assigned as the index of the
    last element.

    If the normalized `index_range.first` is out of bounds of the given array,
    or if it is is greater than the normalized `index_range.last`,
    then an empty array is returned.

        iex> Array.slice(Array.new([1, 2, 3, 4, 5, 6]), 2..4)
        ##{@current_default_array}<[3, 4, 5]>

        iex> Array.slice(Array.new(1..100), 5..10)
        ##{@current_default_array}<[6, 7, 8, 9, 10, 11]>

        iex> Array.slice(Array.new(1..10), 5..20)
        ##{@current_default_array}<[6, 7, 8, 9, 10]>

        # last five elements (negative indexes)
        iex> Array.slice(Array.new(1..30), -5..-1)
        ##{@current_default_array}<[26, 27, 28, 29, 30]>

    If values are out of bounds, it returns an empty array:

        iex> Array.slice(Array.new(1..10), 11..20)
        ##{@current_default_array}<[]>

        # first is greater than last
        iex> Array.slice(Array.new(1..10), 6..5)
        ##{@current_default_array}<[]>

    See also `slice/3`.

    This function is similar to `Enum.slice/2`, but will always return an array (whereas `Enum.slice` will return a list).

    Slicing on Array is significantly faster than slicing on plain lists or maps, as there is no need to iterate over all elements we're going to skip since we can index them directly.
    """
    @doc since: "1.1.0"
    @spec slice(array, Range.t()) :: array
    def slice(array, index_range)

    @doc """
    Returns a sub-array of the given array, from `start_index` (zero-based)
    with `amount` number of elements if available.

    Given an array, it skips elements right before element `start_index`; then,
    it takes `amount` of elements, returning as many elements as possible if there
    are not enough elements.

    A negative `start_index` can be passed, which means the array is enumerated
    once and the index is counted from the end (for example, -1 starts slicing from
    the last element).

    It returns an empty array if `amount` is 0 or if `start_index` is out of bounds.

        iex> Array.slice(Array.new([1, 2, 3, 4, 5, 6]), 2, 4)
        ##{@current_default_array}<[3, 4, 5, 6]>

        iex> Array.slice(Array.new([1, 2, 3, 4, 5, 6]), 10, 20)
        ##{@current_default_array}<[]>

        iex> Array.slice(Array.new(1..100), 5, 10)
        ##{@current_default_array}<[6, 7, 8, 9, 10, 11, 12, 13, 14, 15]>

        # amount to take is greater than the number of elements
        iex> Array.slice(Array.new(1..10), 5, 100)
        ##{@current_default_array}<[6, 7, 8, 9, 10]>

        iex> Array.slice(Array.new(1..10), 5, 0)
        ##{@current_default_array}<[]>

        # using a negative start index
        iex> Array.slice(Array.new(1..10), -6, 3)
        ##{@current_default_array}<[5, 6, 7]>

        # out of bound start index (positive)
        iex> Array.slice(Array.new(1..10), 10, 5)
        ##{@current_default_array}<[]>

        # out of bound start index (negative)
        iex> Array.slice(Array.new(1..10), -11, 5)
        ##{@current_default_array}<[]>

    See also `slice/2`.

    This function is similar to `Enum.slice/3`, but will always return an array (whereas `Enum.slice` will return a list).

    Slicing on Array is significantly faster than slicing on plain lists or maps, as there is no need to iterate over all elements we're going to skip since we can index them directly.
    """
    @doc since: "1.1.0"
    @spec slice(array, index, non_neg_integer) :: array
    def slice(array, start_index, amount)

    # NOTE: we are not using the new range step syntax here
    # for backwards-compatibility with older Elixir versions.
    def slice(array, index_range = %{first: first, last: last, step: step}) do
      if step == 1 or (step == -1 and first > last) do
        slice_range(array, first, last)
      else
        raise ArgumentError,
              "Array.slice/2 does not accept ranges with custom steps, got: #{inspect(index_range)}"
      end
    end

    def slice(array, index_range = %{__struct__: Range, first: first, last: last}) do
      step = if first <= last, do: 1, else: -1
      slice(array, Map.put(index_range, :step, step))
    end

    defp slice_range(array, first, last) when last >= first and last >= 0 and first >= 0 do
      slice_any(array, first, last - first + 1)
    end

    defp slice_range(array = %impl{}, first, last) do
      count = Array.Protocol.size(array)
      first = if first >= 0, do: first, else: first + count
      last = if last >= 0, do: last, else: last + count
      amount = last - first + 1

      if first >= 0 and first < count and amount > 0 do
        Array.Protocol.slice(array, first, min(amount, count - first))
      else
        Array.empty(implementation: impl)
      end
    end

    def slice(array = %impl{}, start_index, 0) when is_integer(start_index),
      do: Array.empty(implementation: impl)

    def slice(array, start_index, amount)
        when is_integer(start_index) and is_integer(amount) and amount >= 0 do
      slice_any(array, start_index, amount)
    end

    defp slice_any(array = %impl{}, start, amount) when start < 0 do
      count = Array.Protocol.size(array)
      start = count + start

      if start >= 0 do
        Array.Protocol.slice(array, start, min(amount, count - start))
      else
        Array.empty(implementation: impl)
      end
    end

    defp slice_any(array = %impl{}, start, amount) when start >= 0 do
      count = Array.Protocol.size(array)

      if start >= count do
        Array.empty(implementation: impl)
      else
        Array.Protocol.slice(array, start, min(amount, count - start))
      end
    end
  end

Module.create(
  Array,
  quote location: :keep do
    @default_array_implementation Array.Implementations.MapArray
    unquote(contents)

    # This is only relevant in the testing environment.
    # On normal compilation, we do not need to make the compiled module larger.

    # coveralls-ignore-start
    if Mix.env() == :test do
      @internal_module_contents unquote(Macro.escape(contents))
      @doc false
      def __internal_module_contents__ do
        @internal_module_contents
      end
    end

    # coveralls-ignore-stop
  end,
  __ENV__
)
