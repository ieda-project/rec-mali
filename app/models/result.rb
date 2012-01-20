class Result < ActiveRecord::Base
  include Csps::Exportable
  globally_belongs_to :diagnostic
  belongs_to :classification
  belongs_to :treatment

  validates_presence_of :treatment, if: ->(r) { r.diagnostic.treatments_required? && r.can_have_treatment? }

  scope :with_treatment,
    where('treatment_id IS NOT NULL').
    includes(:classification, :treatment)

  def finalized?
    treatment.present? || !can_have_treatment?
  end

  def can_have_treatment?
    classification.treatments.any?
  end
end
