defmodule TypedStructor.Definer.Defrecord do
  @moduledoc """
  A definer to define record macors and a type for a given definition.

  ## Additional options for `typed_structor`

    * `:record_name`(**required**) - the name of the record, it must be provided.
    * `:record_tag` - if set, the record will be tagged with the given value. Defaults to `nil`.
    * `:define_record` - if `false`, the type will be defined, but the record will not be defined. Defaults to `true`.

  ## Usage

      defmodule MyRecord do
        use TypedStructor

        typed_structor definer: :defrecord, record_name: :user, record_tag: User, define_recrod: true do
          field :name, String.t(), enforce: true
          field :age, pos_integer(), enforce: true
        end
      end

  The above code is equivalent to:

      defmodule MyRecord do
        require Record

        @type t() :: {User, name :: String.t(), age :: pos_integer()}

        Record.defrecord(:user, User, [:name, :age])
      end
  """

  alias TypedStructor.Definer.Utils

  @doc """
  Defines an exception and a type for a given definition.
  """
  defmacro define(definition) do
    quote do
      unquote(__MODULE__).__record_ast__(:public, unquote(definition))
      unquote(__MODULE__).__type_ast__(unquote(definition))
    end
  end

  @doc false
  defmacro __record_ast__(visibility, definition) do
    quote bind_quoted: [visibility: visibility, definition: definition] do
      define_record? =
        Keyword.get_lazy(definition.options, :define_record, fn ->
          case Keyword.fetch(definition.options, :define_struct) do
            {:ok, value} ->
              IO.warn("""
              Use `:define_record` instead of `:define_struct` in the `defrecord` or `defrecordp` definer options.

              Change this:

                  typed_structor definer: :defrecord, record_name: :user, define_struct: true

              to this:

                  typed_structor definer: :defrecord, record_name: :user, define_record: true
              """)

              value

            :error ->
              true
          end
        end)

      # credo:disable-for-next-line Credo.Check.Design.AliasUsage
      record_name = TypedStructor.Definer.Defrecord.__get_record_name__(definition)
      record_tag = Keyword.get(definition.options, :record_tag)

      if define_record? do
        {fields, enforce_keys} = Utils.fields_and_enforce_keys(definition)

        require Record

        case visibility do
          :public ->
            Record.defrecord(record_name, record_tag, fields)

          :private ->
            Record.defrecordp(record_name, record_tag, fields)
        end
      end
    end
  end

  @doc false
  defmacro __type_ast__(definition) do
    quote bind_quoted: [definition: definition] do
      {type_kind, type_name, parameters, fields} = Utils.types(definition, __ENV__)
      # combine name and type annotations
      fields =
        Enum.map(fields, fn {name, type} ->
          quote do: unquote(Macro.var(name, __MODULE__)) :: unquote(type)
        end)

      record_tag =
        Keyword.get_lazy(definition.options, :record_tag, fn ->
          # credo:disable-for-next-line Credo.Check.Design.AliasUsage
          TypedStructor.Definer.Defrecord.__get_record_name__(definition)
        end)

      case type_kind do
        :type ->
          @type unquote(type_name)(unquote_splicing(parameters)) ::
                  {unquote(record_tag), unquote_splicing(fields)}

        :opaque ->
          @opaque unquote(type_name)(unquote_splicing(parameters)) ::
                    {unquote(record_tag), unquote_splicing(fields)}

        :typep ->
          @typep unquote(type_name)(unquote_splicing(parameters)) ::
                   {unquote(record_tag), unquote_splicing(fields)}
      end
    end
  end

  @doc false
  def __get_record_name__(definition) do
    case Keyword.fetch(definition.options, :record_name) do
      {:ok, record_name} ->
        record_name

      :error ->
        raise ArgumentError, """
        Please provide the `:record_name` option when using the `defrecord` or `defrecordp` definer.

        Example:

              typed_structor definer: :defrecord, record_name: :user, define_record: true
        """
    end
  end
end
