class Employee < ApplicationRecord
  attr_accessor :position_name

  belongs_to :position
  has_many :attendances, dependent: :destroy

  validates :name, presence: true
  validates :salary,
            presence: true,
            numericality: { greater_than: 0 }
end
