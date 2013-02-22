# Better caching helper for Ruby On Rails that provides:
# * Dogpile protection support
# * Use the same caches from different places (since there is no '{controller}/{view}' at the beginning of each key)
# * Fetching multiple fragments using multi-get
#
# Keys are separate from timestamp to allow the dog pile protection and are constructed using custom_cache_key
#
# Usage:
# <% custom_cache custom_cache_key('product-tile', @product.id), @product.updated_at, dogpile_protection: true do %>
#   <%= @product.name %>
# <% end %>
#
# Usage for multiple-fetching (using multi-get to speed up fetching)
# <% prefetch_result = helper.prefetch_multiple_keys(@products.collect {|product| [custom_cache_key('product-tile', product.id), product.updated_at]}) %>
# <% @products.each do |product| %>
#   <% cache_content_if_not_prefetched custom_cache_key('product-tile', product.id), product.updated_at, prefetch_result do %>
#     <%= @product.name %>
#   <% end %>
# <% end %>


module ImprovedCacheHelper
  CACHE_VERSION = 20

  def custom_cache(name, timestamp, options = nil, &block)
    safe_concat(custom_fragment_for(name, timestamp, options, &block))
    nil
  end

  def custom_cache_key(*args)
    'cache:' + args.collect {|keypart| retrieve_cache_key(keypart) }.join(':') + ":v#{CACHE_VERSION}"
  end

  # cache multi feature

  # keys should have format [key, timestamp], [key2, timestamp2]
  def prefetch_multiple_keys(cache_keys)
    if controller.should_refresh_cache or !Rails.configuration.action_controller.perform_caching
      {}
    else
      Rails.cache.read_multi(cache_keys.collect { |key| timestamp_key(key[0],key[1]) })
    end
  end

  def cache_content_if_not_prefetched(name, timestamp, cache_contents, &block)
    cache_key = timestamp_key(name, timestamp)
    return cache_contents[cache_key] if cache_contents[cache_key].present?
    custom_cache(name, timestamp, nil, &block)
  end

  private
  def custom_fragment_for(name, timestamp, options = nil, &block) #:nodoc:
    if Rails.configuration.action_controller.perform_caching
      if options && options[:dogpile_protection]
        fragment = custom_read_dogpile(name, timestamp, options)
      else
        fragment = custom_read_fragment(name, timestamp, options)
      end
    end
    if fragment.present?
      fragment
    else
      # VIEW TODO: Make #capture usable outside of ERB
      # This dance is needed because Builder can't use capture
      pos = output_buffer.length
      yield
      output_safe = output_buffer.html_safe?
      fragment = output_buffer.slice!(pos..-1)
      if output_safe
        self.output_buffer = output_buffer.class.new(output_buffer)
      end

      if Rails.configuration.action_controller.perform_caching
        if options && options[:dogpile_protection]
          fragment = custom_write_dogpile(name, timestamp, fragment, options)
        else
          fragment = custom_write_fragment(name, timestamp, fragment, options)
        end
      end
      fragment
    end
  end

  def custom_read_fragment(name, timestamp, options)
    Rails.cache.read(timestamp_key(name, timestamp))
  end

  def custom_read_dogpile(name, timestamp, options)
    result = Rails.cache.read(timestamp_key(name, timestamp))

    if result.blank?
      Rails.cache.write(name + ':refresh-thread', 0, raw: true, unless_exist: true, expires_in: 5.seconds)
      if Rails.cache.increment(name + ':refresh-thread') == 1
        result = nil
      else
        result = Rails.cache.read(name + ':last')
      end
    end
    result
  end

  def custom_write_fragment(name, timestamp, fragment, options)
    Rails.cache.write(timestamp_key(name, timestamp), fragment)
    fragment
  end

  def custom_write_dogpile(name, timestamp, fragment, options)
    Rails.cache.write(timestamp_key(name, timestamp), fragment)
    Rails.cache.write(name + ':last', fragment)
    Rails.cache.delete(name + ':refresh-thread')
    fragment
  end

  def timestamp_key(key, timestamp)
    key.to_s + ':' + timestamp.to_s
  end

  def retrieve_cache_key(key)
    case
      when key.respond_to?(:cache_key) then key.cache_key
      else                                  key.to_param
    end.to_s
  end
end