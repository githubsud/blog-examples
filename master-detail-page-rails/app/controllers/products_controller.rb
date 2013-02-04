class ProductsController < ApplicationController
  def index
    @products = Product.all

    if params[:product_id].present?
      @product = Product.find(params[:product_id])
    end

    if params[:product_id].present? and request.xhr?
      render 'product', layout: false
    else

    end
  end
end
