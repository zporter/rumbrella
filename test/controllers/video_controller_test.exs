defmodule Rumbl.VideoControllerTest do
  use Rumbl.ConnCase

  alias Rumbl.Video
  @valid_attrs %{url: "http://youtu.be", title: "vid", description: "a vid"}
  @invalid_attrs %{title: "invalid"}

  defp video_count(query), do: Repo.one(from v in query, select: count(v.id))

  setup %{conn: conn} = config do
    opts = %{}

    if username = config[:login_as] do
      user = insert_user(username: username)
      conn = assign(conn(), :current_user, user)
      opts = Map.merge(opts, %{conn: conn, user: user})
    end

    if video_title = config[:with_video] do
      video = insert_video(opts[:user], %{title: video_title})
      opts  = Map.merge(opts, %{video: video})
    end

    {:ok, opts}
  end

  test "requires user authentication on all actions", %{conn: conn} do
    Enum.each([
      get(conn, video_path(conn, :new)),
      get(conn, video_path(conn, :index)),
      get(conn, video_path(conn, :show, "123")),
      get(conn, video_path(conn, :edit, "123")),
      get(conn, video_path(conn, :update, "123", %{})),
      get(conn, video_path(conn, :create, %{})),
      get(conn, video_path(conn, :delete, "123"))
    ], fn conn ->
      assert html_response(conn, 302)
      assert conn.halted
    end)
  end

  @tag login_as: "max"
  test "lists all user's videos on index", %{conn: conn, user: user} do
    user_video  = insert_video(user, title: "funny cats")
    other_video = insert_video(insert_user(username: "other"), title: "another video")

    conn = get conn, video_path(conn, :index)
    assert html_response(conn, 200) =~ ~r/Listing videos/
    assert String.contains?(conn.resp_body, user_video.title)
    refute String.contains?(conn.resp_body, other_video.title)
  end

  @tag login_as: "max"
  test "creates user video and redirects", %{conn: conn, user: user} do
    conn = post conn, video_path(conn, :create), video: @valid_attrs

    assert redirected_to(conn) == video_path(conn, :index)
    assert Repo.get_by!(Video, @valid_attrs).user_id == user.id
  end

  @tag login_as: "max"
  test "does not create video and renders errors when invalid", %{conn: conn, user: _user} do
    count_before = video_count(Video)
    conn = post conn, video_path(conn, :create), video: @invalid_attrs

    assert html_response(conn, 200) =~ "check the errors"
    assert video_count(Video) == count_before
  end

  @tag login_as: "max", with_video: "giant robots"
  test "shows the user's video", %{conn: conn, user: _user, video: video} do
    conn = get conn, video_path(conn, :show, video)

    assert html_response(conn, 200) =~ ~r/giant robots/
  end

  @tag login_as: "max", with_video: "giant robots"
  test "edits the user's video", %{conn: conn, user: _user, video: video} do
    conn  = get conn, video_path(conn, :edit, video)

    assert html_response(conn, 200) =~ "Edit video"
    assert String.contains?(conn.resp_body, "giant robots")
  end

  @tag login_as: "max", with_video: "giant rawbits"
  test "updates the user's video and redirects", %{conn: conn, user: _user, video: video} do
    conn = put conn, video_path(conn, :update, video), video: @valid_attrs

    # Reload the video's attributes
    video         = Repo.get(Video, video.id)
    expected_path = video_path(conn, :show, video)

    assert redirected_to(conn) == expected_path
    assert String.contains?(conn.resp_body, @valid_attrs[:title])
  end

  @tag login_as: "max", with_video: "giant robots"
  test "deletes the user's video and redirects", %{conn: conn, user: _user, video: video} do
    count_before = video_count(Video)
    conn         = delete conn, video_path(conn, :delete, video)

    assert redirected_to(conn) == video_path(conn, :index)
    assert video_count(Video) == (count_before - 1)
    assert Repo.get_by(Video, %{id: video.id}) == nil
  end

  @tag login_as: "max"
  test "authorizes actions against access by other users", %{user: owner, conn: conn} do
    video     = insert_video(owner, @valid_attrs)
    non_owner = insert_user(username: "sneaky")
    conn      = assign(conn, :current_user, non_owner)

    assert_error_sent :not_found, fn ->
      get(conn, video_path(conn, :show, video))
    end

    assert_error_sent :not_found, fn ->
      get(conn, video_path(conn, :edit, video))
    end

    assert_error_sent :not_found, fn ->
      put(conn, video_path(conn, :update, video, video: @valid_attrs))
    end

    assert_error_sent :not_found, fn ->
      delete(conn, video_path(conn, :delete, video))
    end
  end

end
