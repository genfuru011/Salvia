require_relative "../config/environment"

puts "Creating seed data..."

Sale.destroy_all

Sale.create!([
  { month: "Jan", amount: 65 },
  { month: "Feb", amount: 59 },
  { month: "Mar", amount: 80 },
  { month: "Apr", amount: 81 },
  { month: "May", amount: 56 },
  { month: "Jun", amount: 55 }
])

puts "Created #{Sale.count} sales records."

# Projects
Project.destroy_all

Project.create!(
  name: "Website Redesign",
  status: "active",
  budget: 50000,
  spent: 12000,
  start_date: Date.today - 10,
  due_date: Date.today + 30
)

Project.create!(
  name: "Mobile App Development",
  status: "active",
  budget: 100000,
  spent: 85000, # 予算85%消化 -> At Risk
  start_date: Date.today - 60,
  due_date: Date.today + 10
)

Project.create!(
  name: "Legacy System Migration",
  status: "on_hold",
  budget: 30000,
  spent: 32000, # 予算超過 -> Critical
  start_date: Date.today - 100,
  due_date: Date.today - 5 # 期限切れ -> Critical
)

Project.create!(
  name: "AI Integration Pilot",
  status: "completed",
  budget: 20000,
  spent: 18000,
  start_date: Date.today - 40,
  due_date: Date.today - 1
)

puts "Created #{Project.count} projects records."

