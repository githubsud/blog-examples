class Post < ActiveRecord::Base
  attr_accessible :title, :content, :user

  belongs_to :user
  has_many :comments
end
