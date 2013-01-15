class PostPresenter
  def initialize(post_id)
    @post_id = post_id
  end

  def post
    @post ||= Post.includes(:comments).find(@post_id)
  end

end