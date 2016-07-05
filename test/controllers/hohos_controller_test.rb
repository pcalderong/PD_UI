require 'test_helper'

class HohosControllerTest < ActionController::TestCase
  setup do
    @hoho = hohos(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:hohos)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create hoho" do
    assert_difference('Hoho.count') do
      post :create, hoho: { my: @hoho.my }
    end

    assert_redirected_to hoho_path(assigns(:hoho))
  end

  test "should show hoho" do
    get :show, id: @hoho
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @hoho
    assert_response :success
  end

  test "should update hoho" do
    patch :update, id: @hoho, hoho: { my: @hoho.my }
    assert_redirected_to hoho_path(assigns(:hoho))
  end

  test "should destroy hoho" do
    assert_difference('Hoho.count', -1) do
      delete :destroy, id: @hoho
    end

    assert_redirected_to hohos_path
  end
end
