require "test_helper"

class LegendsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @legend = legends(:one)
  end

  test "should get index" do
    get legends_url, as: :json
    assert_response :success
  end

  test "should create legend" do
    assert_difference("Legend.count") do
      post legends_url, params: { legend: { player_count: @legend.player_count, status: @legend.status, story_count: @legend.story_count } }, as: :json
    end

    assert_response :created
  end

  test "should show legend" do
    get legend_url(@legend), as: :json
    assert_response :success
  end

  test "should update legend" do
    patch legend_url(@legend), params: { legend: { player_count: @legend.player_count, status: @legend.status, story_count: @legend.story_count } }, as: :json
    assert_response :success
  end

  test "should destroy legend" do
    assert_difference("Legend.count", -1) do
      delete legend_url(@legend), as: :json
    end

    assert_response :no_content
  end
end
