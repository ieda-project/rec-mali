class SerialNumber < ActiveRecord::Base
  belongs_to :zone

  def modified!
    if exported?
      update_attributes! value: value+1, exported: false
    elsif new_record?
      save!
    end
  end

  def exported!
    update_attribute :exported, true
  end
end
