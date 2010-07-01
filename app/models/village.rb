class Village < ActiveRecord::Base
  has_many :children

  def self.to_select
    order(:name).map { |i| [ i.name, i.id.to_s ] }
  end
end
