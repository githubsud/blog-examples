class Comment < ActiveRecord::Base
  attr_accessible :name, :content, :user

  belongs_to :post, touch: true
  belongs_to :user
end
