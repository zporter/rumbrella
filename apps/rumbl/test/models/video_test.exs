defmodule Rumbl.VideoTest do
  use Rumbl.ModelCase

  alias Rumbl.Video

  @valid_attrs %{description: "some content", title: "some content", url: "some content"}
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = Video.changeset(%Video{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = Video.changeset(%Video{}, @invalid_attrs)
    refute changeset.valid?
  end

  test "slugification" do
    changeset = Video.changeset(%Video{}, Map.merge(@valid_attrs, %{title: "Funny Cats"}))
    video     = Repo.insert!(changeset)

    assert video.slug == "funny-cats"
  end

  test "generating URL path with slug" do
    video = %Video{id: 6, slug: "funny-things"}
    path  = Rumbl.Router.Helpers.watch_path(%URI{}, :show, video)

    assert path == "/watch/6-funny-things"
  end
end
