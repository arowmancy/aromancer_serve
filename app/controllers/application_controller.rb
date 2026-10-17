class ApplicationController < ActionController::Base
  include Authentication
  allow_unauthenticated_access only: %i[ rules ]

  def rules
    word_file = File.read(Rails.root.join("app/models/word.rb"))
    word_file = word_file.split(:"def weight".to_s)[1].split("end")[0]
    render json: JSON.pretty_generate({rules: word_file})
  end

  private


    def respond_with_error(head_response, message, object = nil, param_structure = nil)
      # using Rack::Utils::SYMBOL_TO_STATUS_CODE to set head status code
      Rails.logger.info(" *\n" * 1)
      Rails.logger.info(" * #{self.class.name} #{__method__}")
      Rails.logger.info(" *\n" * 1)
      Rails.logger.info("head_response: #{head_response}")
      Rails.logger.info("message: #{message}")
      Rails.logger.info("object:")
      Rails.logger.info(JSON.pretty_generate(object || message))
      Rails.logger.info("param_structure:")
      Rails.logger.info(JSON.pretty_generate(param_structure || @param_structure || message))
      Rails.logger.info("backtrace:")
      Thread.current.backtrace.first(11).each{|l|
        Rails.logger.info(l.split("/").last(6).join("/"))
      }
      Rails.logger.info(" *\n" * 1)
      Rails.logger.info(" * #{self.class.name} #{__method__}")
      Rails.logger.info(" *\n" * 1)

      render json: {
        error_message: message,
        error_object: object || message,
        param_structure: param_structure || @param_structure || message
      }, status: head_response
    end


end
