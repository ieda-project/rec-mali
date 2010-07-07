module Wopata::ActiveRecord::Enumeration
  def enum field, data, options={}
    c = field.to_s.pluralize.upcase
    const_set c, data
    
    opt_path = if options[:opt]
      "opt.#{options[:opt]}"
    else
      "opt.#{name.underscore}.#{field}"
    end
    
    class_eval "def self.#{field}_opt
      '#{options[:opt].nil? ? name.underscore + '.' + field.to_s : options[:opt]}'
    end", __FILE__, __LINE__

    class_eval "def #{c}.to_select
      map.with_index do |i,n|
        [ I18n.t(\"#{opt_path}.\#{::#{name}::#{c}[n]}\"), n ]
      end
    end", __FILE__, __LINE__
    
    if options[:many]
      # overwrite the accessor, since self.foo = ["5"] is not converted to self.foo = [5]
      class_eval "def #{field.to_s.pluralize}= l
        write_attribute(:#{field.to_s.pluralize}, (l.blank? ? nil : l.map(&:to_i)))
      end", __FILE__, __LINE__

      class_eval "def #{field}_keys
        #{field.to_s.pluralize} ?
        #{field.to_s.pluralize}.map { |v| ::#{name}::#{c}[v] } :
        []
      end", __FILE__, __LINE__
      
      class_eval "def #{field}_names
        #{field.to_s.pluralize} ?
        #{field.to_s.pluralize}.map { |v| I18n.t(\"#{opt_path}.\#{::#{name}::#{c}[v]}\") } :
        []
      end", __FILE__, __LINE__
      
      class_eval "def #{field.to_s.pluralize}_selected_to_select
        #{field.to_s.pluralize} ?
        #{field.to_s.pluralize}.map { |v| [I18n.t(\"#{opt_path}.\#{::#{name}::#{c}[v]}\"), v] } :
        []
      end", __FILE__, __LINE__
      
      class_eval "def #{field.to_s.pluralize}_unselected_to_select
        (0..::#{name}::#{c}.size-1).to_a - (#{field.to_s.pluralize} || []).map do |v|
          [I18n.t(\"#{opt_path}.\#{::#{name}::#{c}[v]}\"), v]
        end
      end", __FILE__, __LINE__
    else
      class_eval "def #{field}_key
        #{field}.present? && ::#{name}::#{c}[#{field}]
      end", __FILE__, __LINE__

      class_eval "def #{field}_name
        #{field} && I18n.t(\"#{opt_path}.\#{::#{name}::#{c}[#{field}]}\")
      end", __FILE__, __LINE__
    end
  end
end
