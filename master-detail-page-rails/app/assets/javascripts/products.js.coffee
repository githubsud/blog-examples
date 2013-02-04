class window.ProductViewState extends Backbone.Model
  @PRODUCT_LIST = 'product_list'
  @ITEM_VIEW = 'item_view'


class window.ProductView extends Backbone.View
  el: '.container'
  events:
    'click .products li a': 'onClickProduct'
    'click .header a': 'onClickBackToList'

  initialize: (e) ->
    @model = new ProductViewState()
    @model.on('change', this.render)

  onClickProduct: (e) =>
    e.preventDefault();

    @model.set('state', ProductViewState.ITEM_VIEW)

    $(e.currentTarget).after($('#product_details').detach())

    product_url = $(e.currentTarget).attr('href');
    app.navigate(product_url);

    $.ajax({
      url: product_url
    }).done(this.onProductArrived)

  onProductArrived: (data, textStatus, jqXHR) =>
    @model.set('productDetailsHTML', data)

  onClickBackToList: (e) =>
    e.preventDefault();
    @model.set({state: ProductViewState.PRODUCT_LIST, productDetailsHTML: null})

  render: (e) =>
    if @model.get('state') == ProductViewState.PRODUCT_LIST
      $('#product_list').show()
      $('#product_details').hide()
    else
      $('#product_list').hide()
      $('#product_details').show()

    if @model.get('productDetailsHTML') != null
      $('#product_details').html(@model.get('productDetailsHTML'))
    else
      $('#product_details').html('');

class window.ProductRouter extends Backbone.Router
  routes:
    'products/': 'indexPage',
    'products/:product_id': 'productDetail'

  initialize: ->
    window.activeView = new ProductView()

  indexPage: ->
    $('#product_list').show()

  productDetail: (productId) ->
    $('#product_details').show()
