require 'travis/api/app'

class Travis::Api::App
  class Endpoint
    class Requests < Endpoint
      post '/' do
        respond_with service(:requests, :requeue, params)
      end
    end
  end
end

