require "test_helper"

class EmployeesIndexTest < ActionDispatch::IntegrationTest
  test "shows employee index page" do
    get employees_path

    assert_response :success
    assert_select "h1", "พนักงาน"
  end

  test "shows employee detail page with payroll summary" do
    employee = employees(:gift)

    get employee_path(employee)

    assert_response :success
    assert_select "h1.page-title", "รายละเอียดพนักงาน"
    assert_select "h2", employee.name
    assert_select "p", "รายได้สุทธิ"
    assert_select "td", text: I18n.l(attendances(:gift_present).work_date, format: :long)
  end

  test "creates employee with a new position from position_name" do
    assert_difference("Employee.count", 1) do
      assert_difference("Position.count", 1) do
        post employees_path, params: {
          employee: {
            name: "Jane Doe",
            salary: 60_000,
            position_name: "QA Engineer"
          }
        }
      end
    end

    employee = Employee.order(:id).last

    assert_redirected_to employee_path(employee)
    assert_equal "QA Engineer", employee.position.name
    assert_equal "qa engineer", employee.position.normalized_name
  end

  test "reuses existing position when position_name differs by case and spacing" do
    assert_difference("Employee.count", 1) do
      assert_no_difference("Position.count") do
        post employees_path, params: {
          employee: {
            name: "Jane Doe",
            salary: 60_000,
            position_name: "  developer  "
          }
        }
      end
    end

    employee = Employee.order(:id).last

    assert_redirected_to employee_path(employee)
    assert_equal positions(:developer), employee.position
  end

  test "renders unprocessable entity when position_name is blank" do
    assert_no_difference("Employee.count") do
      assert_no_difference("Position.count") do
        post employees_path, params: {
          employee: {
            name: "Jane Doe",
            salary: 60_000,
            position_name: "   "
          }
        }
      end
    end

    assert_response :unprocessable_entity
    assert_select ".field_with_errors"
  end

  test "destroys employee successfully" do
    employee = employees(:gift)

    assert_difference("Employee.count", -1) do
      delete employee_path(employee)
    end

    assert_redirected_to employees_path
  end
end
