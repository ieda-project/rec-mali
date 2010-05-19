ActionController::Responder.send :include, Wopata::ActionController::Responder

ActiveRecord::Relation.send :include, Wopata::ActiveRecord::Pagination::Relation
ActiveRecord::Relation.send :include, Wopata::ActiveRecord::Search
[ :paginate, :search ].each do |method|
  ActiveRecord::Associations::AssociationCollection.send :delegate, method, to: :scoped
  ActiveRecord::Base.metaclass.send :delegate, method, to: :scoped
end

ActiveRecord::Base.metaclass.send :alias_method, :[], :find
