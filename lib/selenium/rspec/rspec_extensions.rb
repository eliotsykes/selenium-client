require "rubygems"
gem "rspec", "=1.2.6"
require 'spec'
require 'spec/example/example_group'

#
# Monkey-patch RSpec Example Group so that we can track whether an
# example already failed or not in an after(:each) block
#
# Useful to only capture Selenium screenshots when a test fails  
#
# * Changed execution_error to be an instance variable (in lieu of 
#   a local variable).
#
# * Introduced an unique id (example_uid) that is the same for 
#   a real Example (passed in after(:each) when screenshot is 
#   taken) as well as the corresponding ExampleProxy 
#   (passed to the HTML formatter). This unique id gives us
#   a way to correlate file names between generation and 
#   reporting time.
#
module Spec
  module Example
    module ExampleMethods

      attr_reader :execution_error

      def execute(run_options, instance_variables) # :nodoc:
        @_proxy.options[:actual_example] = self
        
        run_options.reporter.example_started(@_proxy)
        set_instance_variables_from_hash(instance_variables)
        
        @execution_error = nil
        Timeout.timeout(run_options.timeout) do
          begin
            before_each_example
            instance_eval(&@_implementation)
          rescue Exception => e
            @execution_error ||= e
          end
          begin
            after_each_example
          rescue Exception => e
            @execution_error ||= e
          end
        end

        run_options.reporter.example_finished(@_proxy.update(description), @execution_error)
        success = @execution_error.nil? || ExamplePendingError === @execution_error
      end

      def reporting_uid
        # backtrace is not reliable anymore using the implementation proc          
        Digest::MD5.hexdigest @_implementation.inspect
      end
 
    end

    class ExampleProxy

      def reporting_uid
        options[:actual_example].reporting_uid
      end

    end

  end
end

