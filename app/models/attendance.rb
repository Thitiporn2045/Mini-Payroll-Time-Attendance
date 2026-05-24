class Attendance < ApplicationRecord
  belongs_to :employee

  enum :status, {
    present: 0,
    leave: 1,
    absent: 2
  }, prefix: true, default: :present

  validates :work_date, presence: true
  validates :status, presence: true
  validates :work_date, uniqueness: { scope: :employee_id }

  validates :check_in, presence: true, if: :status_present?
  validates :check_out, presence: true, if: :status_present?

  before_validation :clear_times_when_not_present

  validate :check_in_must_be_on_work_date, if: :status_present?
  validate :check_out_must_be_on_work_date, if: :status_present?
  validate :check_out_after_check_in, if: :status_present?

  def status_label
    case status
    when "present"
      "มาทำงาน"
    when "leave"
      "ลา"
    when "absent"
      "ขาด"
    else
      "-"
    end
  end

  def worked_hours
    return BigDecimal("0") unless status_present?
    return BigDecimal("0") if check_in.blank? || check_out.blank?

    BigDecimal(((check_out - check_in) / 1.hour).round(2).to_s)
  end

  def ot_hours
    [ worked_hours - BigDecimal("8"), BigDecimal("0") ].max
  end

  private

  def clear_times_when_not_present
    return if status_present?

    self.check_in = nil
    self.check_out = nil
  end

  def check_in_must_be_on_work_date
    return if work_date.blank? || check_in.blank?

    errors.add(:check_in, "ต้องเป็นเวลาในวันทำงานเดียวกัน") if check_in.to_date != work_date
  end

  def check_out_must_be_on_work_date
    return if work_date.blank? || check_out.blank?

    errors.add(:check_out, "ต้องเป็นเวลาในวันทำงานเดียวกัน") if check_out.to_date != work_date
  end

  def check_out_after_check_in
    return if check_in.blank? || check_out.blank?

    errors.add(:check_out, "ต้องเป็นเวลาหลังเวลาเข้า") if check_out <= check_in
  end
end
