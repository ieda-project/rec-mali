require 'date'

module Csps
  module Age
    extend ActiveSupport::Concern
    GROUPS = %w(newborn infant child)

    def self.[] key
      GROUPS.index key
    end

    included do
      before_save do
        self.saved_age_group = age_group if respond_to? :saved_age_group
      end
      validate do
        errors.add :born_on, :invalid if born_on > Date.today
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
          if days <= 7
            0 # newborn
          elsif months <= 2
            1 # infant
          elsif months < 60
            2 # child
          end
        end
      end

      def age_group_key
        GROUPS[age_group]
      end

      def age
        born_on && age_reference_date.full_years_from(born_on)
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
