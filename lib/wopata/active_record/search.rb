require 'base32'

module Wopata::ActiveRecord
  module Search
    def search q, order=nil, dir=nil
      return scoped unless q.present?
      c, d = [], []
      q.to_hash.each do |key,value|
        next unless value.present?

        if col = columns_hash["cache_#{key}"]
          value.cacheize!
        else
          if key == :identifier
            key = :uqid
            begin
              value = Base32.decode(value)
            rescue ArgumentError
              raise "Identifiant incorrect: #{value}"
            end
          end
          next unless col = columns_hash[key.to_s]
        end

        case col.type
          when :date
            case value
              when %r|^([0-9]{2})/([0-9]{2})/([0-9]{4})$|
                c << 'born_on = ?'
                d << "#{$3}-#{$2}-#{$1}"
              when /^([0-9]{4})$/
                c << 'born_on >= ? AND born_on <= ?'
                d += [ "#{$1}-01-01", "#{$1}-12-31" ]
            end
          when :string
            values =  value.split(' ').map {|slice| "%#{slice.strip.cacheize}%"}.sort.join(' ')
            c << "#{col.name} LIKE ?"
            d << values
          when :boolean
            c << (%w(1 true yes).include?(value) ? key : "NOT #{key}")
          else
            c << "#{key} = ?"
            d << value
        end
      end
      ret = where c.join(' AND '), *d

      if order.present? && order =~ /\A[a-z._, ]+\Z/
        ret.order "#{order} #{(dir.in?(%w(d desc DESC)) ? ' DESC' : '')}"
      else
        ret
      end
    end
  end
end
