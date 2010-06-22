module Wopata::ActiveRecord
  module Search
    def search q
      return scoped unless q.present?
      c, d = [], []
      q.to_hash.each do |key,value|
        next unless value.present?

        if col = columns_hash["cache_#{key}"]
          value.cacheize!
        else
          next unless col = columns_hash[key.to_s]
        end

        case col.type
          when :string
            values = value.split(/\s+/).map { |q| "%#{q}%" }
            c << '(' + (["#{col.name} LIKE ?"]*values.length).join(' OR ') + ')'
            d += values
          when :boolean
            c << (%w(1 true yes).include?(value) ? key : "NOT #{key}")
          else
            c << "#{key} = ?"
            d << value
        end
      end
      where c.join(' AND '), *d
    end
  end
end
