task :create_data => :environment do
  # content from: www.neowin.net
  User.delete_all
  Post.delete_all
  Comment.delete_all

  @user1 = User.create(name: 'John Callaham')
  @user2 = User.create(name: 'ingramator')
  @user3 = User.create(name: 'virtorio')

  @post = Post.create title: 'Microsoft officially launches Windows Azure Media Services', user: @user1, content: 'Microsoft has announced that Windows Azure Media Services is officially available, allowing clients to stream video to a wide variety of platforms in many different media formats.'
  @post.comments.create(user: @user2, content: 'About time! This is going to be a really cool service and will let businesses do away with customized solutions that are slow an unstable!')
  @post.comments.create(user: @user3, content: 'That cat does not look happy.')
end