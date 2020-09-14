module Inspector
  def self.included(action)
    action.class_eval do
      after do |req, res|
        res[:params] = req.params.to_h
        req.env['hanami.response'] = res
      end
    end
  end
end

class Renderer
  def render(env, response)
    action   = env.delete('hanami.action')
    response = env.delete('hanami.response') || response

    handle_hanami_response(env, action, response) ||
      handle_rack_response(env, action, response)

    response
  end

  private

  def handle_hanami_response(env, action, response)
    return unless response.respond_to?(:status)

    if response.status == 200
      response.body = "#{action.class.name} #{response.exposures} params: #{response[:params].to_h} flash: #{response.session[:_flash].inspect}"
    end

    true
  end

  def handle_rack_response(env, action, response)
    if response[0] == 200
      response[2] = "#{action.class.name} params: #{env['router.params'].to_h} flash: #{env['rack.session'].fetch('flash', nil).inspect}"
    end
  end
end
