require "test_helper"

class PositionTest < ActiveSupport::TestCase
  test "is valid with a name" do
    position = Position.new(name: "QA Engineer")

    assert position.valid?
  end

  test "normalizes name before validation" do
    position = Position.create!(name: " QA Engineer ")

    assert_equal "QA Engineer", position.name
    assert_equal "qa engineer", position.normalized_name
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

  test "find_or_create_by_name returns the existing normalized record" do
    existing = Position.create!(name: "Product Manager")

    found = Position.find_or_create_by_name!("  product manager  ")

    assert_equal existing.id, found.id
    assert_equal 1, Position.where(normalized_name: "product manager").count
  end
end
