module Inspector
  def self.included(action)
    action.class_eval do
      after do |req, res|
        response[:params] = req.params.to_h
        req.env['hanami.response'] = res
      end
    end
  end
end

class Renderer
  def render(env, response)
    action = env.delete('hanami.action')
    response = env.delete('hanami.response') || response

    if action.renderable? && response && response.status == 200
      response.body = "#{action.class.name} #{response.exposures} params: #{response[:params].to_h} flash: #{response[:flash].inspect}"
    end

    response
  end
end
