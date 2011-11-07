class Prescription < ActiveRecord::Base
  belongs_to :medicine
  belongs_to :treatment

  def name
    medicine.name
  end

  def html diag
    dosage = diag.instance_eval "->() { #{Medicine.find(10).code} }.()"
    if dosage
      out = instructions.gsub /{{(name|takes|duration)}}/ do
        send $1
      end
      out.gsub '{{dosage}}', "#{dosage} #{medicine.unit}"
    end
  end
end
