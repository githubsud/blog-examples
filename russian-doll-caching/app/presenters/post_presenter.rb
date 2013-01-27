class PostPresenter
  def initialize(post)
    @post = post
  end

  def comments
    Comment.includes(:user).where(post_id: @post.id)
  end

end