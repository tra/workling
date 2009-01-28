require 'workling/clients/base'
Workling.try_load_an_amqp_client

#
#  An Ampq client
#
module Workling
  module Clients
    class AmqpClient < Workling::Clients::Base
      
      # starts the client. 
      def connect
        begin
          @options = (Workling.config[:amqp_options] || {}).symbolize_keys
          # host and port only needed for AMQP.start
          host, port = Workling.config[:listens_on].split(':', 2)
          start_opts = {:host => host || 'localhost', :port => (port || 5672).to_i}.merge(@options)
          @amq = MQ.new(AMQP.start(start_opts))
        rescue
          raise WorklingError.new("couldn't start amq client. if you're running this in a server environment, then make sure the server is evented (ie use thin or evented mongrel, not normal mongrel.): #{$!}")
        end
      end
      
      # no need for explicit closing. when the event loop
      # terminates, the connection is closed anyway. 
      def close; true; end
      
      # subscribe to a queue
      def subscribe(key)
        @amq.queue(key, @options).subscribe(@options) do |value|
          yield YAML.load(value)
        end
      end
      
      # request and retrieve work
      def retrieve(key); @amq.queue(key, @options); end
      def request(key, value)
        logger.info("> publishing to #{key}: #{value.inspect}")
        @amq.queue(key, @options).publish(YAML.dump(value), @options)
      end
    end
  end
end