class Child < ActiveRecord::Base
  include Csps::Exportable
  include Csps::Human
  belongs_to :village
  has_many :child_photos
  has_many :diagnostics
  has_one :last_visit,
          class_name: 'Diagnostic',
          order: 'id DESC'

  def age
    born_on ? ((Date.today - born_on) / 365).to_i : nil
  end

  def age_in_months
    born_on ? ((Date.today - born_on) / 12).to_i : nil
  end
end
