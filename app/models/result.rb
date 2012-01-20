class Result < ActiveRecord::Base
  include Csps::Exportable
  globally_belongs_to :diagnostic
  belongs_to :classification
  belongs_to :treatment

  validates_presence_of :treatment, if: ->(r) { r.diagnostic.treatments_required? }

  scope :with_treatment,
    where('treatment_id IS NOT NULL').
    includes(:classification, :treatment)

  def finalized?
    treatment.present? || classification.treatments.empty?
  end
end
