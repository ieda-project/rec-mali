require 'date'

module Csps
  module Age
    extend ActiveSupport::Concern
    (GROUPS = %w(newborn infant child)).each.with_index do |name,i|
      const_set name.upcase, i
    end

    def self.[] key
      GROUPS.index key
    end

    included do
      before_save do
        self.saved_age_group = age_group if respond_to? :saved_age_group
      end

      validates_presence_of :born_on, unless: :temporary?
      validate do
        errors.add :born_on, :invalid if !temporary? && born_on && born_on > Date.today
      end
    end

    module ClassMethods
      def age_group born_on
        new(born_on: born_on).age_group
      end

      def age_group_key born_on
        new(born_on: born_on).age_group_key
      end
    end

    module InstanceMethods
      def age_reference_date
        Date.today
      end

      def age_group
        if born_on
          if days < 7
            NEWBORN
          elsif months < 2
            INFANT
          elsif months < 60
            CHILD
          end
        end
      end

      def age_group_key
        GROUPS[age_group]
      end

      def age
        born_on && age_reference_date.full_years_from(born_on)
      end

      def of_valid_age?
        months < 60
      end

      def months
        born_on && age_reference_date.full_months_from(born_on)
      end

      def days
        born_on && (age_reference_date - born_on).to_i
      end
    end
  end
end
