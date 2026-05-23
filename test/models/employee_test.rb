require "test_helper"

class EmployeeTest < ActiveSupport::TestCase
  test "is valid with required attributes" do
    employee = Employee.new(
      name: "Jane Doe",
      salary: 60_000,
      position: positions(:developer)
    )

    assert employee.valid?
  end

  test "is invalid without a name" do
    employee = employees(:gift)
    employee.name = ""

    assert_not employee.valid?
    assert_includes employee.errors[:name], I18n.t("errors.messages.blank")
  end

  test "is invalid without salary" do
    employee = employees(:gift)
    employee.salary = nil

    assert_not employee.valid?
    assert_includes employee.errors[:salary], I18n.t("errors.messages.blank")
  end

  test "is invalid with zero salary" do
    employee = employees(:gift)
    employee.salary = 0

    assert_not employee.valid?
  end

  test "is invalid with negative salary" do
    employee = employees(:gift)
    employee.salary = -1

    assert_not employee.valid?
  end

  test "is invalid without position" do
    employee = employees(:gift)
    employee.position = nil

    assert_not employee.valid?
  end
end
