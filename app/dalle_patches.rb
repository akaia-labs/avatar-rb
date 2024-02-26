module DallePatches
  def dalle3(prompt=nil, compress: true)
    return unless allowed_chat?

    attempt(3) do
      puts "DALL-E workflow trigered"
      prompt ||= @replies_to&.text || @text_without_command
      send_chat_action(:upload_photo)

      puts "Sending request"
      response = open_ai.images.generate(parameters: {
        prompt: prompt, size: "1024x1024", quality: "hd", model: "dall-e-3"
      })

      send_chat_action(:upload_photo)

      url = response.dig("data", 0, "url")

      puts "DALL-E finished, sending photo to Telegram..."

      if response["error"]
        reply_code(response)
      else
        if compress
          send_photo(url, reply_to_message_id: @msg.message_id)
        else
          send_document(url, reply_to_message_id: @msg.message_id)
        end
      end
    end
  end

  def send_document(url, **options)
    @api.send_document(document: url, chat_id: @chat.id, **options)
  end
end
