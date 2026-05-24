require "test_helper"

class EmployeesIndexTest < ActionDispatch::IntegrationTest
  test "shows employee index page" do
    get employees_path

    assert_response :success
    assert_select "h1", "พนักงาน"
    assert_select ".workspace-nav svg.workspace-nav-icon", minimum: 2
    assert_select ".workspace-nav", text: /⌂/, count: 0
  end

  test "filters employees by name and position" do
    get employees_path, params: { employee_query: "Som", position: positions(:developer).name }

    assert_response :success
    assert_select "#employees tr", 1
    assert_select "#employees tr td", /#{Regexp.escape(employees(:somchai).name)}/
    assert_select "#employees tr td", text: /#{Regexp.escape(employees(:woranan).name)}/, count: 0
  end

  test "renders employee results partial for turbo frame requests" do
    get employees_path, headers: { "Turbo-Frame" => "employees_results" }

    assert_response :success
    assert_select "turbo-frame#employees_results"
    assert_select "h1", count: 0
  end

  test "shows employee detail page with payroll summary" do
    employee = employees(:somchai)

    get employee_path(employee)

    assert_response :success
    assert_select "h1.page-title", "รายละเอียดพนักงาน"
    assert_select "h2", employee.name
    assert_select "p", "รายได้สุทธิ"
    assert_select "td", text: I18n.l(attendances(:somchai_may_present_ot).work_date, format: :long)
  end

  test "filters employee detail attendances by month and status" do
    employee = employees(:woranan)

    get employee_path(employee), params: { month: "2026-05", status: "leave" }

    assert_response :success
    assert_select "td", text: I18n.l(attendances(:woranan_may_leave).work_date, format: :long)
    assert_select "td", text: I18n.l(attendances(:woranan_may_present_ot).work_date, format: :long), count: 0
  end

  test "renders attendance table frame for employee detail turbo requests" do
    employee = employees(:somchai)

    get employee_path(employee), params: { month: "2026-05" }, headers: { "Turbo-Frame" => "attendance_table" }

    assert_response :success
    assert_select "turbo-frame#attendance_table"
    assert_select "h1", count: 0
  end

  test "employee selector preserves month and status context" do
    employee = employees(:somchai)

    get employee_path(employee), params: { month: "2026-05", status: "leave" }

    assert_response :success
    assert_select "select[data-month-value='2026-05'][data-status-value='leave']"
    assert_select "select[onchange*='status']"
  end

  test "employee detail month filter renders browser month picker" do
    employee = employees(:somchai)

    get employee_path(employee), params: { month: "2026-05", status: "present" }

    assert_response :success
    assert_select "#payroll_summary_header", text: /พฤษภาคม 2026/
    assert_select "#payroll_summary_header input[type='month'][name='month'][value='2026-05']"
    assert_select "#payroll_summary_header a", text: "← เดือนก่อนหน้า", count: 0
    assert_select "#payroll_summary_header a", text: "เดือนถัดไป →", count: 0
  end

  test "employee detail keeps selected month visible even when employee has no attendance that month" do
    employee = employees(:somchai)

    get employee_path(employee), params: { month: "2026-01" }

    assert_response :success
    assert_select "#payroll_summary_header", text: /มกราคม 2026/
    assert_select "#payroll_summary_header input[type='month'][name='month'][value='2026-01']"
    assert_select ".payroll-summary-subtitle", /มกราคม 2026/
    assert_select ".section-description", /มกราคม 2026/
    assert_select ".empty-state-detail .empty-title", "ยังไม่มีข้อมูลเวลาเข้าออกงาน"
  end

  test "employee detail falls back to current month when month param is invalid" do
    employee = employees(:somchai)
    current_month = Date.current.beginning_of_month

    get employee_path(employee), params: { month: "bad-value" }

    assert_response :success
    assert_select "#payroll_summary_header", text: /#{Regexp.escape(EmployeesHelper::THAI_MONTH_NAMES[current_month.month])} #{current_month.year}/
    assert_select "#payroll_summary_header input[type='month'][name='month'][value='#{current_month.strftime("%Y-%m")}']"
  end

  test "opens delete confirmation modal from employees list context" do
    employee = employees(:somchai)

    get confirm_destroy_employee_path(employee), params: {
      return_to: "employees",
      employee_query: "Som",
      position: positions(:developer).name
    }, headers: { "Turbo-Frame" => "employee_delete_panel" }

    assert_response :success
    assert_select "turbo-frame#employee_delete_panel"
    assert_select ".dialog-backdrop"
    assert_select "h2", "ลบพนักงานคนนี้?"
    assert_select "form[action='#{employee_path(employee, return_to: "employees", employee_query: "Som", position: positions(:developer).name)}']"
  end

  test "opens delete confirmation modal from employee detail context" do
    employee = employees(:somchai)

    get confirm_destroy_employee_path(employee), params: {
      return_to: "employee_show",
      month: "2026-05",
      status: "present"
    }, headers: { "Turbo-Frame" => "employee_delete_panel" }

    assert_response :success
    assert_select "turbo-frame#employee_delete_panel"
    assert_select ".dialog-backdrop"
    assert_select "h2", "ลบพนักงานคนนี้?"
    assert_select "form[data-turbo-frame='_top']"
  end

  test "new employee form shows delete icons only for removable positions" do
    get new_employee_path

    assert_response :success
    assert_select ".combobox-panel"
    assert_select "a[href*='/positions/']", count: 0
  end

  test "keeps employee form panel open when create validation fails" do
    assert_no_difference("Employee.count") do
      post employees_path, params: {
        employee: {
          name: "",
          salary: 60_000,
          position_name: "Data Analyst"
        }
      }
    end

    assert_response :unprocessable_entity
    assert_select "turbo-frame#employee_form_panel [data-controller='side-panel'][data-side-panel-open-value='true']"
    assert_select "turbo-frame#employee_form_panel .error-box"
  end

  test "edit employee form from detail context preserves close path to show page" do
    employee = employees(:somchai)

    get edit_employee_path(employee), params: {
      return_to: "employee",
      month: "2026-05",
      status: "present"
    }, headers: { "Turbo-Frame" => "employee_form_panel" }

    assert_response :success
    expected_path = employee_path(employee, month: "2026-05", status: "present")
    assert_select "[data-side-panel-close-url-value='#{expected_path}']"
    assert_select "a[href='#{expected_path}'].icon-button"
    assert_select "a[href='#{expected_path}']", text: "ยกเลิก"
  end

  test "edit employee form from list context preserves close path to employees index" do
    employee = employees(:somchai)

    get edit_employee_path(employee), params: {
      return_to: "employees",
      employee_query: "Som",
      position: positions(:developer).name
    }, headers: { "Turbo-Frame" => "employee_form_panel" }

    assert_response :success
    expected_path = employees_path(employee_query: "Som", position: positions(:developer).name)
    assert_select "[data-side-panel-close-url-value='#{expected_path}']"
    assert_select "a[href='#{expected_path}'].icon-button"
    assert_select "a[href='#{expected_path}']", text: "ยกเลิก"
  end

  test "keeps employee form panel open when update validation fails" do
    employee = employees(:somchai)

    patch employee_path(employee), params: {
      employee: {
        name: "",
        salary: 75_000,
        position_name: "Product Designer"
      },
      return_to: "employee",
      month: "2026-05",
      status: "present"
    }

    assert_response :unprocessable_entity
    assert_select "turbo-frame#employee_form_panel [data-controller='side-panel'][data-side-panel-open-value='true']"
    assert_select "turbo-frame#employee_form_panel .error-box"
  end

  test "new employee form from list context preserves close path to employees index" do
    get new_employee_path,
        params: { return_to: "employees", employee_query: "Som", position: positions(:developer).name },
        headers: { "Turbo-Frame" => "employee_form_panel" }

    assert_response :success
    expected_path = employees_path(employee_query: "Som", position: positions(:developer).name)
    assert_select "[data-side-panel-close-url-value='#{expected_path}']"
    assert_select "a[href='#{expected_path}'].icon-button"
    assert_select "a[href='#{expected_path}']", text: "ยกเลิก"
  end

  test "creates employee with a new position from position_name" do
    assert_difference("Employee.count", 1) do
      assert_difference("Position.count", 1) do
        post employees_path, params: {
          employee: {
            name: "Jane Doe",
            salary: 60_000,
            position_name: "Data Analyst"
          }
        }
      end
    end

    employee = Employee.order(:id).last

    assert_redirected_to employee_path(employee)
    assert_equal "Data Analyst", employee.position.name
    assert_equal "data analyst", employee.position.normalized_name
  end

  test "creates employee from index context and redirects back to employees list" do
    assert_difference("Employee.count", 1) do
      post employees_path, params: {
        employee: {
          name: "John Doe",
          salary: 55_000,
          position_name: "Designer"
        },
        return_to: "employees",
        employee_query: "Joh",
        position: positions(:designer).name
      }
    end

    assert_redirected_to employees_path(employee_query: "Joh", position: positions(:designer).name)
  end

  test "reuses existing position when position_name differs by case and spacing" do
    assert_difference("Employee.count", 1) do
      assert_no_difference("Position.count") do
        post employees_path, params: {
          employee: {
            name: "Jane Doe",
            salary: 60_000,
            position_name: "  software developer  "
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

  test "updates employee from detail context" do
    employee = employees(:somchai)

    patch employee_path(employee), params: {
      employee: {
        name: "Gift Updated",
        salary: 75_000,
        position_name: "Product Designer"
      },
      return_to: "employee",
      month: "2026-05",
      status: "present"
    }

    assert_redirected_to employee_path(employee, month: "2026-05", status: "present")
    employee.reload
    assert_equal "Gift Updated", employee.name
    assert_equal BigDecimal("75000"), employee.salary
    assert_equal "Product Designer", employee.position.name
  end

  test "destroys employee from detail page and redirects with see other" do
    employee = employees(:somchai)

    assert_difference("Employee.count", -1) do
      delete employee_path(employee), params: { return_to: "employee_show" }
    end

    assert_redirected_to employees_path
    assert_equal 303, response.status
  end

  test "destroys employee successfully" do
    employee = employees(:somchai)

    assert_difference("Employee.count", -1) do
      delete employee_path(employee)
    end

    assert_redirected_to employees_path
  end
end
