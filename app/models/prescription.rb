class Prescription < ActiveRecord::Base
  belongs_to :medicine
  belongs_to :treatment

  scope :mandatory, where(mandatory: true)
  scope :optional, where(mandatory: false)

  validates_inclusion_of :mandatory, in: [true, false]

  def name
    medicine.name
  end

  def valid_for? diag
    !!amount(diag)
  end

  def amount diag
    diag.instance_eval "->() { #{medicine.code} }.()"
  end

  def dosage diag
    if am = amount(diag)
      "#{am.round(1).to_s.sub('.0', '')} #{medicine.unit}"
    end
  end

  def html diag
    if dos = dosage(diag)
      out = instructions.gsub /{{(name|takes|duration)}}/ do
        send $1
      end
      out.gsub '{{dosage}}', dos
    end
  end
end
