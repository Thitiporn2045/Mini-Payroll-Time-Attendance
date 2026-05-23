class Position < ApplicationRecord
  has_many :employees, dependent: :restrict_with_error

  before_validation :normalize_name

  validates :name, presence: true
  validates :normalized_name, uniqueness: true, allow_nil: true

  def self.find_or_create_by_name!(raw_name)
    cleaned_name = raw_name.to_s.strip
    normalized = cleaned_name.downcase

    if cleaned_name.blank?
      position = new(name: cleaned_name)
      position.errors.add(:name, :blank)
      raise ActiveRecord::RecordInvalid, position
    end

    existing_position = find_by(normalized_name: normalized)
    return existing_position if existing_position.present?

    create!(name: cleaned_name)
  rescue ActiveRecord::RecordNotUnique
    find_by!(normalized_name: normalized)
  end

  private

  def normalize_name
    self.name = name.to_s.strip
    self.normalized_name = name.downcase if name.present?
  end
end
