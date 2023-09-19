# frozen_string_literal: true
require "open_ai_bot"
require_relative "chat_gpt_patches"
require_relative "whisper_patches"

class AirinaAkaiaNeurobot < OpenAIBot
  include ChatGPTPatches
  include WhisperPatches

  on_every_message :react_to_sticker
  on_every_message :rust

  def allowed_chat?
    return true if config.open_ai[:whitelist].include? @user.id

    super
  end

  def rust
    return unless @msg.text&.match?(/\brust!?\b/i) && (rand < 0.4)

    send_chat_action(:upload_video)
    video = Faraday::UploadIO.new("#{__dir__}/../asset/rust.mp4", "mp4")
    send_video(video)
  end

  def react_to_sticker
    return unless @msg.sticker

    flip_sticker = lambda do
      return if @msg.sticker.is_video
      return if @msg.sticker.is_animated # ? fix for TGS?

      send_chat_action(:choose_sticker)
      sleep 0.5

      file = download_file(@msg.sticker)

      original = file.original_filename
      flopped = "flopped_#{original}"
      `convert ./#{original} -flop ./#{flopped}`
      sticker = Faraday::UploadIO.new(flopped, original.split(".").last)
      send_sticker(sticker)
    ensure
      FileUtils.rm_rf([original, flopped]) if file
    end

    random_sticker = lambda do
      send_chat_action(:choose_sticker)
      sleep 2
      sticker_pack_name = @msg.sticker.set_name
      stickers = @api.get_sticker_set(name: sticker_pack_name)["result"]["stickers"]
      random_sticker_id = stickers.sample["file_id"]
      send_sticker(random_sticker_id)
    end

    Probably do
      with 0.05, &flip_sticker
      with 0.05, &random_sticker
    end
  end
end
