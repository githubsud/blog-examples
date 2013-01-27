class RussianDollPostsController < ApplicationController
  def show
    @post = Post.find(params[:id])
    @presenter = PostPresenter.new(@post)
    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @post }
    end
  end

  #def index
  #    @posts = Post.all
  #
  #    respond_to do |format|
  #      format.html # index.html.erb
  #      format.json { render json: @posts }
  #    end
  #  end
end
