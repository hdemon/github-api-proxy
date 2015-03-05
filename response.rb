class Response
  attr_accessor :data, :message, :error

  def render
    {
        message: @message || "Success.",
        errors: @errors || [],
        data: @data
    }.to_json
  end
end
