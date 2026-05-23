require "test_helper"

class PositionTest < ActiveSupport::TestCase
  test "is valid with fixture data" do
    assert positions(:developer).valid?
  end

  test "requires a name" do
    position = Position.new(name: "")

    assert_not position.valid?
    assert_includes position.errors[:name], I18n.t("errors.messages.blank")
  end

  test "normalizes name before validation" do
    position = Position.new(name: "  Finance Manager  ")

    assert position.valid?
    assert_equal "Finance Manager", position.name
    assert_equal "finance manager", position.normalized_name
  end

  test "enforces unique normalized_name" do
    duplicate = Position.new(name: "software developer")

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:normalized_name], I18n.t("errors.messages.taken")
  end

  test "find_or_create_by_name returns existing position case insensitively" do
    position = Position.find_or_create_by_name!("  SOFTWARE DEVELOPER ")

    assert_equal positions(:developer), position
  end

  test "find_or_create_by_name creates a new position when missing" do
    assert_difference("Position.count", 1) do
      position = Position.find_or_create_by_name!("Data Analyst")

      assert_equal "Data Analyst", position.name
      assert_equal "data analyst", position.normalized_name
    end
  end

  test "find_or_create_by_name raises invalid record when blank" do
    assert_raises(ActiveRecord::RecordInvalid) do
      Position.find_or_create_by_name!("   ")
    end
  end

  test "find_or_create_by_name returns existing record when create hits unique index race" do
    existing = positions(:developer)
    singleton = class << Position; self; end
    original_find_by = Position.method(:find_by)
    original_create = Position.method(:create!)
    original_find_by_bang = Position.method(:find_by!)

    singleton.define_method(:find_by) { |*| nil }
    singleton.define_method(:create!) { |*| raise ActiveRecord::RecordNotUnique }
    singleton.define_method(:find_by!) { |*| existing }

    assert_equal existing, Position.find_or_create_by_name!("Software Developer")
  ensure
    singleton.define_method(:find_by) { |*args, **kwargs| original_find_by.call(*args, **kwargs) }
    singleton.define_method(:create!) { |*args, **kwargs| original_create.call(*args, **kwargs) }
    singleton.define_method(:find_by!) { |*args, **kwargs| original_find_by_bang.call(*args, **kwargs) }
  end

  test "cannot destroy a position that is still referenced by employees" do
    position = positions(:developer)

    assert_no_difference("Position.count") do
      assert_not position.destroy
    end

    assert_includes position.errors[:base], I18n.t("errors.messages.restrict_dependent_destroy.has_many")
  end

  test "can destroy a position that is not referenced by employees" do
    position = positions(:qa)

    assert_difference("Position.count", -1) do
      position.destroy!
    end
  end
end
