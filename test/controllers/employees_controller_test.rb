require "test_helper"

class EmployeesIndexTest < ActionDispatch::IntegrationTest
  test "shows employee index page" do
    get employees_path

    assert_response :success
    assert_select "h1", "พนักงาน"
  end
end