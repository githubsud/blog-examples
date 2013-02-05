# Model to hold the current state
# position: last scrollTop before clicking an item
# state: Can be ITEM_VIEW or PRODUCT_LIST
# productDetailsHTML: The HTML for the detail view
class window.ProductViewState extends Backbone.Model
  @PRODUCT_LIST = 'product_list'
  @ITEM_VIEW = 'item_view'

# View to manage transitions between two states
class window.ProductView extends Backbone.View
  el: '.container'
  events:
    'click .products li a': 'onClickProduct'
    'click .header a': 'onClickBackToList'

  initialize: (e) ->
    @model = new ProductViewState()
    @model.on('change', this.render)

  getModel: =>
    @model

  # Navigates to single item view
  onClickProduct: (e) =>
    e.preventDefault();

    product_url = $(e.currentTarget).attr('href');
    app.navigate(product_url, { trigger: true });

    $.ajax({
      url: product_url
    }).done(this.onProductArrived)

  onProductArrived: (data, textStatus, jqXHR) =>
    @model.set {productDetailsHTML: data }

  onClickBackToList: (e) =>
    e.preventDefault();
    app.navigate('master-detail-page-rails/products/', { trigger: true });

  render: (e) =>
    if @model.get('state') == ProductViewState.PRODUCT_LIST
      if $('#product_list').is(':hidden')
        $('#product_list').show()
        $(window).scrollTop(@model.get('position'))

      $('#product_details').hide()
    else
      $('#product_list').hide()
      $('#product_details').show()

    if @model.get('productDetailsHTML') != null
      $('#product_details').html(@model.get('productDetailsHTML'))
    else
      $('#product_details').empty()

class window.ProductRouter extends Backbone.Router

  routes:
    'master-detail-page-rails/products': 'indexPage',
    'master-detail-page-rails/products/:product_id': 'productDetail'

  initialize: ->
    window.activeView = new ProductView()
    @model = window.activeView.getModel()
    Backbone.history.start({pushState: true})

  indexPage: ->
    @model.set({state: ProductViewState.PRODUCT_LIST, productDetailsHTML: null})

  productDetail: (productId) ->
    @model.set({state: ProductViewState.ITEM_VIEW, position: $(window).scrollTop()})