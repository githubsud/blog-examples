task :create_data => :environment do
  20.times do
    Product.create name: 'The Southern Past', image_url: 'http://ecx.images-amazon.com/images/I/41VKKApAOEL._SY160_.jpg'
    Product.create name: 'Domino: The Book of Decorating', image_url: 'http://ecx.images-amazon.com/images/I/51gBLgvTtPL._SL160_PIsitb-sticker-arrow-dp,TopRight,12,-18_SH30_OU01_AA160_.jpg'
    Product.create name: 'Chanel: Collections and Creations', image_url: 'http://ecx.images-amazon.com/images/I/41klJs78KCL._AA160_.jpg'
    Product.create name: 'Big Book of Chic', image_url: 'http://ecx.images-amazon.com/images/I/4162yLz-iXL._AA160_.jpg'
    Product.create name: 'The Psychology Book', image_url: 'http://ecx.images-amazon.com/images/I/51YG-nM0HkL._SL160_PIsitb-sticker-arrow-dp,TopRight,12,-18_SH30_OU01_AA160_.jpg'
  end
end