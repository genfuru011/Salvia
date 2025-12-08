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
