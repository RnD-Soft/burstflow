require 'rubygems'
require 'bundler'
require 'bundler/setup'
Bundler.require(:default)

require 'awesome_print'
require 'burstflow'


ActiveJob::Base.queue_adapter = :test
ActiveJob::Base.logger = nil

$root = File.join(File.dirname(__dir__), 'spec')
Dir[File.join($root, 'support', '**', '*.rb')].each {|f| require f }

# ActiveJob::Base.logger = ActiveSupport::TaggedLogging.new(ActiveSupport::Logger.new(STDOUT))
ActiveJob::Base.logger = ActiveSupport::Logger.new('/dev/null')



RSpec::Matchers.define :have_jobs do |flow, jobs|
  match do |_actual|
    expected = jobs.map do |job|
      hash_including(args: include(flow, job))
    end
    expect(ActiveJob::Base.queue_adapter.enqueued_jobs).to match_array(expected)
  end

  failure_message do |_actual|
    "expected queue to have #{jobs}, but instead has: #{ActiveJob::Base.queue_adapter.enqueued_jobs.map{|j| j[:args][1] }}"
  end
end

RSpec.configure do |config|
  config.include ActiveJob::TestHelper

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.before(:each) do
    clear_enqueued_jobs
    clear_performed_jobs
  end

  config.after(:each) do
    clear_enqueued_jobs
    clear_performed_jobs
  end
end
