class Sale < ApplicationRecord
  validates :month, presence: true
  validates :amount, presence: true
end
