require "test_helper"

class AttendancesControllerTest < ActionDispatch::IntegrationTest
  test "edit form hides time fields for leave attendance" do
    get edit_employee_attendance_path(employees(:gift), attendances(:gift_leave))

    assert_response :success
    assert_select "[data-attendance-form-target='timeFields'].hidden"
  end

  test "edit form shows time fields for present attendance" do
    get edit_employee_attendance_path(employees(:gift), attendances(:gift_present))

    assert_response :success
    assert_select "[data-attendance-form-target='timeFields']:not(.hidden)"
  end
end
