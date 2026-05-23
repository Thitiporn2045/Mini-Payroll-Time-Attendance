require "test_helper"

class EmployeeTest < ActiveSupport::TestCase
  test "is valid with fixture data" do
    assert employees(:somchai).valid?
  end

  test "requires a name" do
    employee = Employee.new(name: nil, salary: 25_000, position: positions(:developer))

    assert_not employee.valid?
    assert_includes employee.errors[:name], I18n.t("errors.messages.blank")
  end

  test "requires a salary" do
    employee = Employee.new(name: "New Employee", salary: nil, position: positions(:developer))

    assert_not employee.valid?
    assert_includes employee.errors[:salary], I18n.t("errors.messages.blank")
  end

  test "requires salary to be greater than zero" do
    employee = Employee.new(name: "New Employee", salary: 0, position: positions(:developer))

    assert_not employee.valid?
    assert_includes employee.errors[:salary], "ต้องมากกว่า 0"
  end

  test "belongs to a position" do
    employee = employees(:somchai)

    assert_equal positions(:developer), employee.position
  end

  test "has many attendances" do
    employee = employees(:somchai)

    assert_equal 4, employee.attendances.count
  end

  test "destroys dependent attendances when destroyed" do
    employee = employees(:somchai)

    assert_difference("Attendance.count", -employee.attendances.count) do
      employee.destroy
    end
  end
end
