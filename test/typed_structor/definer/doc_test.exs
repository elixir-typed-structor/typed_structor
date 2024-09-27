defmodule TypedStructor.Definer.DocTest do
  use ExUnit.Case, async: true

  alias TypedStructor.Definer.Defexception
  alias TypedStructor.Definer.Defrecord
  alias TypedStructor.Definer.Defstruct

  test "works" do
    assert Defexception.__additional_options__()
    assert Defrecord.__additional_options__()
    assert Defstruct.__additional_options__()
  end
end
