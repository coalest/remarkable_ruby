module RemarkableRuby
  module ResponseHandling
    def handle_response(response)
      status = response.status
      body = response.body

      case status
      when 200
        # For the responses that fail with a http 200 code
        response_body = JSON.parse(response.body).first
        successful = response_body["Success"]
        message = response_body["Message"]
        raise Error, message unless successful
      when 400
        raise Error, "Your request was malformed. #{body}"
      when 401
        raise Error, "Invalid authentication credentials. #{body}"
      when 403
        raise Error, "You are not allowed to perform that action. #{body}"
      when 404
        raise Error, "No results were found for your request. #{body}"
      end

      response
    end
  end
end
