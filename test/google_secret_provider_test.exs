defmodule GoogleSecretProviderTest do
  use ExUnit.Case
  doctest GoogleSecretProvider

  test "greets the world" do
    assert GoogleSecretProvider.hello() == :world
  end

  describe "load/2" do

    test "it replaces matching tags when there are" do

    end

  end
end
