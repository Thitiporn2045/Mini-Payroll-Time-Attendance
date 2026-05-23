class Employee < ApplicationRecord
  attr_accessor :position_name

  belongs_to :position

  validates :name, presence: true
  validates :salary,
            presence: true,
            numericality: { greater_than: 0 }
end
