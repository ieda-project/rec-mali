if Rails.env.development?
  User.create first_name: 'Albert', last_name: 'Schweitzer', login: 'albert'

  for n in %w(Kiembara Kongoussi Bobo-Dioulasso Niangoloko).map do
    Village.create name: n
  end

  100.times do
    child = Child.create(
      first_name: Faker::Name.first_name,
      last_name:  Faker::Name.last_name,
      born_on:    Date.parse('1999-08-11')+rand(1500),
      village_id: rand(4)+1)

    date = Date.parse('2010-05-05')
    (rand(5)+3).times do
      Diagnostic.create(
        child: child,
        author_id: 1,
        done_on: date)
      date += 1
    end
  end
end
