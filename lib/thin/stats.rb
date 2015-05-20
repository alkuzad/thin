require 'erb'

module Thin
  module Stats
    # Rack adapter to log stats about a Rack application.
    class Adapter
      include ERB::Util
      
      def initialize(app, backend, path='/stats', last_request_visible=false)
        @app  = app
        @backend = backend
        @path = path

	@conns_max = @backend.instance_variable_get('@maximum_connections').to_i rescue 0
	@pers_conns_max = @backend.instance_variable_get('@maximum_persistent_connections').to_i rescue 0

        @template = ERB.new(File.read(File.dirname(__FILE__) + '/stats.html.erb'))
        
        @requests          = 0
        @requests_finished = 0
        @start_time        = Time.now
        @last_request_visible = last_request_visible
      end
      
      def call(env)
        if env['PATH_INFO'].index(@path) == 0
          serve(env)
        else
          log(env) { @app.call(env) }
        end
      end
      
      def log(env)
        @requests += 1
        @last_request = Rack::Request.new(env) if @last_request_visible
        request_started_at = Time.now

	@conns_count = @backend.instance_variable_get('@connections').size rescue 0
	@pers_conns_count = @backend.instance_variable_get('@persistent_connection_count') rescue 0

        response = yield
        
        @requests_finished += 1
        @last_request_time = Time.now - request_started_at
        
        response
      end
      
      def serve(env)
        body = @template.result(binding)
        
        [
          200,
          { 'Content-Type' => 'text/html' },
          [body]
        ]
      end
    end
  end
end
