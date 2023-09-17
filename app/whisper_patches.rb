module WhisperPatches
  def send_whisper_response(text)
    if (@user.username == config.owner_username) && safe_delete(@msg)
      send_text_in_place_of_voice(text)
    else
      reply(text)
    end
  end

  def send_text_in_place_of_voice(text)
    if @replies_to
      reply_to_target(text)
    else
      send_message(text)
    end
  end
end
