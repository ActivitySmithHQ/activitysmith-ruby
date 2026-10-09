# frozen_string_literal: true

require_relative 'test_helper'
require 'open3'
require 'rbconfig'

class PushOptionsSerializationTest < Minitest::Test
  def test_real_generated_client_in_isolation
    # Other wrapper tests install fake OpenapiClient classes globally.
    output, status = Open3.capture2e(RbConfig.ruby, '-Ilib', 'test/support/push_options_serialization.rb')
    assert status.success?, output
    assert_includes output, '0 failures, 0 errors'
  end
end
