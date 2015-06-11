class Comment < ActiveRecord::Base
  default_scope {order('created_at DESC')}

  belongs_to :user

  has_one :table_comment, dependent: :destroy
  has_one :table, through: :table_comments
  has_many :options_for_history, as: :history_option, dependent: :destroy

  validates :body, presence: true
  validates :datetime, presence: true
  validates :user_id, presence: true

end
