module WhisperPatches
  def send_whisper_response(transcript)
    if (@user.username == config.owner_username)
      try_swap_reply(transcript)
    else
      reply(transcript)
    end
  end

  def try_swap_reply(transcript)
    safe_delete(@msg)

    bot_message =
      if @replies_to
        reply_to_target(transcript)
      else
        send_message(transcript)
      end

    id = bot_message.dig("result", "message_id")

    message = OpenAI::BotMessage.new(
      body: transcript, id: id, tokens: 0, chat_id: @chat.id
    )
    current_thread.add(message)
  end
end
