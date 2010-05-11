module Csps::Relation
  def local
    if klass.respond_to? :find_local
      where('NOT imported')
    else
      scoped
    end
  end
end
