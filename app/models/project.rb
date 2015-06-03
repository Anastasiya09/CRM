# == Schema Information
#
# Table name: projects
#
#  id         :integer          not null, primary key
#  name       :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Project < ActiveRecord::Base
  has_and_belongs_to_many :users

  def self.all_active
    where(status: "active")
  end

  def self.all_exsept_project_current_user user
    all_active.pluck(:name, :id).select do|p|
      p unless Project.find(p[1]).users.include? user
    end
  end

  def self.all_project_current_user user
    all_active.pluck(:name, :id).select do|p|
      p if Project.find(p[1]).users.include? user
    end
  end
end
