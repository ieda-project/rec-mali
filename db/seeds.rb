#User.create first_name: 'Albert', last_name: 'Schweitzer', login: 'albert'

for n in %w(Kiembara Kongoussi Bobo-Dioulasso Niangoloko).map do
  Village.create name: n
end

100.times do
  child = Child.create(
    first_name: Faker::Name.first_name,
    last_name:  Faker::Name.last_name,
    born_on:    Date.parse('1999-08-11')+rand(1500),
    village_id: rand(4)+1)

=begin
  date = Date.parse('2010-05-05')
  (rand(5)+3).times do
    Diagnostic.create(
      child: child,
      author_id: 1,
      done_on: date)
    date += 1
  end
=end
end

illnesses = {}

Illness.transaction do
  File.open('db/fixtures/signs.txt', 'r') do |f|
    illness, seq = nil, 0
    f.each_line do |line|
      next if line.blank?
      data = line.chomp.strip.split '|'
      if line =~ /\A\s/
        # Sign
        hash = {
          illness: illness,
          key: data[0],
          question: data[1] }
        case data[2]
          when 'integer'
            hash[:min_value] = data[3]
            hash[:max_value] = data[4]
          when 'list'
            hash[:values] = data[3]
        end
        (data[2].camelize + 'Sign').constantize.create hash
      else
        # Illness
        illness = Illness.create(
          key: data[0],
          name: data[1],
          sequence: seq)
        illnesses[illness.key] = illness
        seq += 1
      end
    end
  end
end

File.open('db/fixtures/classifications.txt', 'r') do |f|
  f.each_line do |line|
    next if line.blank?
    illness, name, equation = line.split '|'
    illnesses[illness].classifications.create(
      name: name,
      treatment: '# ' + Faker::Lorem.sentences(4).join("\n# "),
      equation: equation)
  end
end
