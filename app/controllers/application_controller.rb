class ApplicationController < ActionController::Base
  include Authentication

  private

  def respond_with_error(head_response, message, object = nil, param_structure = nil)
    # using Rack::Utils::SYMBOL_TO_STATUS_CODE to set head status code

    Rails.logger.debug(message)
    render json: {
      error_message: message
      # error_object: object,
      # param_structure: param_structure || @param_structure # todo: formalize better across all controllers
    }, status: head_response
  end
end
