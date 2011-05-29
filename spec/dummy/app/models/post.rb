class Post < ActiveRecord::Base
  has_eav_behavior
  validates :intro, :presence=>true, :on=>:create
end
