class Array
  def to_hash &block
    block ||= proc { true }
    returning Hash.new do |h|
      each { |i| h[i] = block.(i) }
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
