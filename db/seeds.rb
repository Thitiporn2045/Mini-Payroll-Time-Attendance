position_names = [
  "Software Engineer",
  "Product Designer",
  "HR Officer",
  "Accountant",
  "Project Manager"
]

position_names.each do |name|
  Position.find_or_create_by!(name: name)
end