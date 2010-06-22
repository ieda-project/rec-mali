class Child < ActiveRecord::Base
  include Csps::Exportable
  include Csps::Human
  belongs_to :village
  has_many :child_photos
  has_many :diagnostics
  has_one :last_visit,
          class_name: 'Diagnostic',
          order: 'id DESC'
  has_attached_file :photo,
                    styles: { thumbnail: '130x130' }

  before_save :fill_cache_fields

  def age
    born_on ? ((Date.today - born_on) / 365).to_i : nil
  end

  def age_in_months
    born_on ? ((Date.today - born_on) / 12).to_i : nil
  end

  protected

  @@iconv = Iconv.new('ASCII//IGNORE//TRANSLIT', 'UTF-8')
  def fill_cache_fields
    %w(first_name last_name).each do |field|
      send "cache_#{field}=", send(field).cacheize
    end
  end
end
