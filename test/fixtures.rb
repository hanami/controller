class CallAction
  include Lotus::Action

  def call(params)
    self.status  = 201
    self.headers = { 'X-Custom' => 'OK' }
    self.body    = 'Hi from TestAction!'
  end
end

class ErrorCallAction
  include Lotus::Action

  def call(params)
    raise
  end
end

class ParamsCallAction
  include Lotus::Action

  expose :number

  def call(params)
    @number = params[:number]
  end
end

class ExposeAction
  include Lotus::Action

  expose :film, :time

  def call(params)
    @film = '400 ASA'
  end
end
