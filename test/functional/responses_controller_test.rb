require 'test_helper'

class ResponsesControllerTest < ActionController::TestCase
  setup do
    @response = responses(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:responses)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create response" do
    assert_difference('Response.count') do
      post :create, response: { evaluation_id: @response.evaluation_id, instructor_response: @response.instructor_response, peer_review: @response.peer_review, question_id: @response.question_id, scale_id: @response.scale_id, student_response: @response.student_response }
    end

    assert_redirected_to response_path(assigns(:response))
  end

  test "should show response" do
    get :show, id: @response
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @response
    assert_response :success
  end

  test "should update response" do
    put :update, id: @response, response: { evaluation_id: @response.evaluation_id, instructor_response: @response.instructor_response, peer_review: @response.peer_review, question_id: @response.question_id, scale_id: @response.scale_id, student_response: @response.student_response }
    assert_redirected_to response_path(assigns(:response))
  end

  test "should destroy response" do
    assert_difference('Response.count', -1) do
      delete :destroy, id: @response
    end

    assert_redirected_to responses_path
  end
end
