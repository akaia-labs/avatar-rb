module WhisperPatches
  def send_whisper_response(transcript)
    if (@user.username == config.owner_username)
      try_swap_reply(transcript)
      safe_delete(@msg)
    else
      reply(transcript)
    end
  end

  def try_swap_reply(transcript)
    bot_message =
      if @replies_to
        reply_to_target(transcript)
      else
        reply(transcript)
      end

    id = bot_message.dig("result", "message_id")

    message = OpenAI::BotMessage.new(
      id: id,
      tokens: 0,
      chat_id: @chat.id,
      body: transcript,
    )

    current_thread.add(message)
  end

  def send_whisper_error(error)
    @last_whisper_error_time ||= Time.now
    return if (Time.now - @last_whisper_error_time) < 5.minutes

    @last_whisper_error_time = Time.now
    gif = Faraday::UploadIO.new("#{__dir__}/../asset/whisper_error.mp4", "mp4")

    @api.send_animation(
      chat_id: @chat.id,
      animation: gif,
      reply_to_message_id: @replies_to&.message_id,
      message_thread_id: @topic_id,
      caption: "```\n#{error["message"]}```",
      parse_mode: "Markdown"
    )
  end
end
