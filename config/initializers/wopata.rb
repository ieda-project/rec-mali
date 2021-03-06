ActionController::Responder.send :include, Wopata::ActionController::Responder

ActiveRecord::Relation.send :include, Wopata::ActiveRecord::Pagination::Relation
ActiveRecord::Relation.send :include, Wopata::ActiveRecord::Search
ActiveRecord::Relation.send :include, Wopata::ActiveRecord::ToSelect
[ :paginate, :search, :to_select ].each do |method|
  ActiveRecord::Associations::AssociationCollection.send :delegate, method, to: :scoped
  ActiveRecord::Base.metaclass.send :delegate, method, to: :scoped
end

ActiveRecord::Base.send :extend, Wopata::ActiveRecord::Enumeration
ActiveRecord::Base.metaclass.send :alias_method, :[], :find
