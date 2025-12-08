class Project < ApplicationRecord
  # ビジネスロジック: 予算消化率 (%)
  def budget_usage_percentage
    return 0 if budget.nil? || budget.zero?
    ((spent.to_f / budget) * 100).round
  end

  # ビジネスロジック: 残り日数
  def days_remaining
    return 0 if due_date.nil?
    (due_date - Date.today).to_i
  end

  # ビジネスロジック: プロジェクトの健全性判定
  # 予算超過または期限切れなら 'Critical'
  # 予算80%以上または期限まで3日以内なら 'At Risk'
  # それ以外は 'On Track'
  def health_status
    return 'Critical' if days_remaining < 0 || budget_usage_percentage > 100
    return 'At Risk' if days_remaining <= 7 || budget_usage_percentage >= 80
    'On Track'
  end

  # 表示用ヘルパーロジック
  def status_color_class
    case health_status
    when 'Critical' then 'bg-red-100 text-red-800'
    when 'At Risk' then 'bg-yellow-100 text-yellow-800'
    else 'bg-green-100 text-green-800'
    end
  end
end
