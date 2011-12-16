class Prescription < ActiveRecord::Base
  belongs_to :medicine
  belongs_to :treatment

  def name
    medicine.name
  end

  def html diag
    dosage = diag.instance_eval "->() { #{medicine.code} }.()"
    if dosage
      out = instructions.gsub /{{(name|takes|duration)}}/ do
        send $1
      end
      out.gsub '{{dosage}}', "#{dosage.round(1).to_s.sub('.0', '')} #{medicine.unit}"
    end
  end
end
