defmodule Rumbl.PermalinkTest do
  use ExUnit.Case, async: true

  alias Rumbl.Permalink

  test "it casts a numeric string" do
    assert Permalink.cast("1") == {:ok, 1}
  end

  test "it casts a slug" do
    assert Permalink.cast("123-cute-kittens") == {:ok, 123}
  end
end
