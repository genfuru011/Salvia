class DashboardController < ApplicationController
  def index
    sales = Sale.all
    @sales_data = sales.pluck(:amount)
    @sales_labels = sales.pluck(:month)
  end
end
