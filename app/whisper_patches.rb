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

    if @replies_to
      reply_to_target(transcript)
    else
      send_message(transcript)
    end
  end
end
