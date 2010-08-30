module Wopata::ActiveRecord
  module ToSelect
    def to_select
      map { |i| [ i.option_title, i.id ] }.sort_by &:first
    end
  end
end
