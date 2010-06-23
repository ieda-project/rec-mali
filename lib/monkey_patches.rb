class Hash
  def force_encoding enc
    each { |k,v| v.try(:force_encoding, enc) }
  end
end

class Array
  def force_encoding enc
    each { |i| i.try(:force_encoding, enc) }
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
      gsub(/[-'\s]+/, ' ')).downcase.gsub(/[^a-z ]/, '')
  end
  def cacheize!
    self[0..-1] = cacheize
  end
end
