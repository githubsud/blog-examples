require 'spec_helper'

class DummyClass
  include ImprovedCacheHelper

  attr_accessor :output_buffer

  def initialize(controller)
    @output_buffer = ""
    @controller = controller
  end

  def safe_concat(content)
    @output_buffer += content
  end

  def clear_buffer
    @output_buffer = ""
  end

  def controller
    @controller
  end
end

describe ImprovedCacheHelper do
  before :each do
    Rails.cache.clear
    controller = Object.new
    controller.stub(:should_refresh_cache) {false}
    @dummy_class = DummyClass.new(controller)
    Rails.configuration.action_controller.perform_caching = true
    @timestamp = Time.now.to_i
  end

  describe 'fetching multiple keys' do
    it 'should fetch all the keys in a single call' do
      Rails.cache.write("cache:test:multi-1:#{@timestamp}", 1)
      Rails.cache.write("cache:test:multi-2:#{@timestamp}", 1)
      Rails.cache.write("cache:test:multi-3:#{@timestamp}", 1)


      Rails.cache.should_receive(:read_multi).and_call_original
      Rails.cache.should_not_receive(:read)

      cache_contents = @dummy_class.prefetch_multiple_keys([['cache:test:multi-1', @timestamp], ['cache:test:multi-2', @timestamp], ['cache:test:multi-3', @timestamp]])

      @dummy_class.cache_content_if_not_prefetched('cache:test:multi-1', @timestamp, cache_contents).should == 1
    end
    it 'should still fetch values that were not found' do
      Rails.cache.write("cache:test:multi-1:#{@timestamp}", 1)
      Rails.cache.write("cache:test:multi-2:#{@timestamp}", 1)

      Rails.cache.should_receive(:read_multi).and_call_original
      Rails.cache.should_receive(:read).and_call_original

      cache_contents = @dummy_class.prefetch_multiple_keys([['cache:test:multi-1', @timestamp], ['cache:test:multi-2', @timestamp], ['cache:test:multi-3', @timestamp]])

      block_was_called = false
      @dummy_class.cache_content_if_not_prefetched('cache:test:multi-3', @timestamp, cache_contents) do
        @dummy_class.safe_concat('content for multi-3')
        block_was_called = true
      end

      block_was_called.should == true
    end
  end

  describe '#custom_fragment_for' do
    context 'with dogpile support' do
      it 'should read an existing value' do
        Rails.cache.write("cache:test:fragment:#{@timestamp}", 'content')
        @dummy_class.custom_cache('cache:test:fragment', @timestamp, dogpile_protection: true)
        @dummy_class.output_buffer.should == 'content'
      end
      it 'should rebuild an expired cache' do
        @dummy_class.custom_cache('cache:test:fragment', @timestamp, dogpile_protection: true) do
          @dummy_class.safe_concat('content-fresh')
        end

        @dummy_class.clear_buffer
        @dummy_class.custom_cache('cache:test:fragment', @timestamp, dogpile_protection: true)
        @dummy_class.output_buffer.should == 'content-fresh'
      end
      it 'should serve stale content to other clients' do
        # write stale content
        @dummy_class.custom_cache('cache:test:fragment', @timestamp, dogpile_protection: true) do
          @dummy_class.safe_concat('stale-content')
        end

        @dummy_class.clear_buffer

        Rails.cache.delete("cache:test:fragment:#{@timestamp}")
        Rails.cache.write("cache:test:fragment:refresh-thread", "1", raw: true)

        @dummy_class.custom_cache('cache:test:fragment', @timestamp, dogpile_protection: true)
        @dummy_class.output_buffer.should == 'stale-content'
      end
    end
    context 'without dogpile support' do
      it 'should read an existing value' do
        Rails.cache.write("cache:test:fragment:#{@timestamp}", 'content')
        @dummy_class.custom_cache('cache:test:fragment', @timestamp)
        @dummy_class.output_buffer.should == 'content'
      end
      it 'should rebuild an expired cache' do
        @dummy_class.custom_cache('cache:test:fragment', @timestamp) do
          @dummy_class.safe_concat('content-fresh')
        end

        @dummy_class.clear_buffer
        @dummy_class.custom_cache('cache:test:fragment', @timestamp)
        @dummy_class.output_buffer.should == 'content-fresh'
      end
    end
  end
end