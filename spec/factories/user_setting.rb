# == Schema Information
#
# Table name: user_settings
#
#  id                   :integer          not null, primary key
#  hh_record_per_page   :string
#  sale_record_per_page :string
#  user_id              :integer
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#

FactoryGirl.define do
  factory :user_setting do
  end
end