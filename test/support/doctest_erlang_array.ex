# Copy of `Array` module with different default representation
# so that we can re-use the doctests for `ErlangArray`.
Module.create(
  Array.Test.Support.Array.DoctestErlangArray,
  quote location: :keep do
    @default_array_implementation Array.Implementations.ErlangArray
    unquote(Array.__internal_module_contents__())
  end,
  Macro.Env.location(__ENV__)
)
