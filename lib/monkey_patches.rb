# encoding: UTF-8

module Enumerable
  def mapcat
    reduce [] { |m,i| m + yield(i) }
  end
end

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

  def keep *these
    {}.tap do |out|
      these.flatten.each do |key|
        out[key] = self[key]
      end
    end
  end
end

class Array
  def force_encoding enc
    each { |i| i.force_encoding enc rescue nil }
  end

  def hashize &block
    {}.tap do |h|
      each { |i| h.store block.(i), i }
    end
  end

  def rhashize
    {}.tap do |h|
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
    {}.tap do |hash|
      members.each do |k|
        val = send(k) and hash[k] = val
      end
    end
  end
end

require 'iconv'

class String
  @@iconv_cacheize = Iconv.new('ASCII//IGNORE//TRANSLIT', 'UTF-8')
  CACHEIZE_FROM = "áàâäçéèêëíîïóòôöúùûüÿÁÀÂÄÇÉÈÊËÍÎÏÓÒÔÖÚÙÛÜŸ"
  CACHEIZE_INTO = "aaaaceeeeiiioooouuuuyaaaaceeeeiiioooouuuuy"

  def cacheize
    @@iconv_cacheize.iconv(
      tr(CACHEIZE_FROM, CACHEIZE_INTO).
      gsub(/[œŒ]/, 'oe').
      gsub(/[-'\s]+/, ' ')).
    downcase.gsub(/[^a-z ]/, '').split(' ').sort.join(' ')
  end
  def cacheize!
    self[0..-1] = cacheize
  end
end

module ActiveRecord
  class ConnectionAdapters::TableDefinition
    def globally_belongs_to *list
      opts = list.extract_options!
      integer(*list.map { |n| "#{n}_uqid" }, opts)
    end
  end
end
