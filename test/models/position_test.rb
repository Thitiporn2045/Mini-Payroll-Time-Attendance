require "test_helper"

class PositionTest < ActiveSupport::TestCase
  test "is valid with a name" do
    position = Position.new(name: "QA Engineer")

    assert position.valid?
  end

  test "is invalid without a name" do
    position = Position.new(name: "")

    assert_not position.valid?
    assert_includes position.errors[:name], "can't be blank"
  end

  test "is invalid with duplicate name regardless of case" do
    Position.create!(name: "Product Manager")

    duplicate = Position.new(name: "product manager")

    assert_not duplicate.valid?
  end
end