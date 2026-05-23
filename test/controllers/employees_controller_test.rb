require "test_helper"

class EmployeesIndexTest < ActionDispatch::IntegrationTest
  test "shows employee index page" do
    get employees_path

    assert_response :success
    assert_select "h1", "พนักงาน"
  end

  test "destroys employee successfully" do
    employee = employees(:gift)

    assert_difference("Employee.count", -1) do
      delete employee_path(employee)
    end

    assert_redirected_to employees_path
  end
end
