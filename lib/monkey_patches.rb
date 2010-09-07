class Date
  def full_months_from other
    (year - other.year)*12 + (month - other.month) - (other.day <= day ? 0 : 1)
  end

  def full_years_from other
    full_months_from(other) / 12
  end
end

class Hash
  def force_encoding enc
    each { |k,v| v.force_encoding enc rescue nil }
  end
end

class Array
  def force_encoding enc
    each { |i| i.force_encoding enc rescue nil }
  end

  def to_hash &block
    returning Hash.new do |h|
      each { |i| h.store block.(i), i }
    end
  end

  def to_rhash
    returning Hash.new do |h|
      each { |i| h[i] = true }
    end
  end
end

class Object
  def metaclass
    class << self; self; end
  end

  def in? *arr
    arr.flatten.include? self
  end
end

class Struct
  def self.from_hash hash
    hash.present? ? new(*members.map { |k| hash[k] }) : new
  end

  def to_hash
    returning({}) do |hash|
      members.each do |k|
        val = send(k) and hash[k] = val
      end
    end
  end
end

require 'iconv'

class String
  def cacheize
    Iconv.new('ASCII//IGNORE//TRANSLIT', encoding.name).iconv(
      gsub(/[-'\s]+/, ' ')).downcase.gsub(/[^a-z ]/, '').split(' ').sort.join(' ')
  end
  def cacheize!
    self[0..-1] = cacheize
  end
end
