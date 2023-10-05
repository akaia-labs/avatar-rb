# frozen_string_literal: true
require "open_ai_bot"
require_relative "chat_gpt_patches"
require_relative "whisper_patches"

class AkaiaAvatar < OpenAIBot
  include ChatGPTPatches
  include WhisperPatches

  def initialize(...)
    super(...)
    @@crab_attack_targets ||= []
  end

  def self.triggers_for_action(action)
    @triggers_for_action ||= {}
    @triggers_for_action[action] ||= begin
      gpt_string_triggers = config.open_ai[:gpt_triggers][:strings]
      gpt_re_triggers = config.open_ai[:gpt_triggers][:regexps]
      action_triggers = config.open_ai[:actions][action]
      string_triggers = []
      re_triggers = []

      action_triggers.map { |trigger|
        attach_action = ->(str) { [str, trigger].join(" ").squeeze(" ") }
        string_triggers += gpt_string_triggers.map(&attach_action)
        re_triggers += gpt_re_triggers.map(&attach_action).map { Regexp.new(_1) }
      }

      { re: re_triggers, str: string_triggers }
    end
  end

  on_every_message :react_to_sticker
  on_every_message :🦀🦀🦀
  on_every_message :try_swap_animation

  on_command "/d" do
    return unless @user.username == config.owner_username
    return unless @target&.id.in? [config.bot_id, @user.id]
    current_thread.delete(@replies_to.message_id)
    safe_delete(@replies_to)
    safe_delete(@msg)
  end

  on_command "/dd" do
    return unless @user.username == config.owner_username

    current_thread.history.select { _1.is_a? OpenAI::BotMessage }.each do |m|
      safe_delete_by_id(m.id)
    end

    safe_delete(@msg)
    init_session
  end

  def handle_gpt_command
    super unless dalle_with_custom_trigger
  end

  def dalle_with_custom_trigger
    triggers = self.class.triggers_for_action(:dalle)

    triggers[:re].each do |re|
      next unless @text.match?(re)
      return dalle(@text.sub(re, ''))
    end

    triggers[:str].each do |str|
      next unless @text.include?(str)
      return dalle(@text.sub(str, ''))
    end

    false
  end

  def try_swap_animation
    return unless @user.username == config.owner_username
    return unless @msg.animation

    safe_delete(@msg)
    download_file_but_with_types_and_pattern_matching(@msg.animation, "#{__dir__}/../asset/gifs/")

    @api.send_animation(
      chat_id: @chat.id,
      animation: @msg.animation.file_id,
      reply_to_message_id: @replies_to&.message_id,
      message_thread_id: @topic_id
    )
  end

  def allowed_chat?
    return true if config.open_ai[:whitelist].include? @user.id
    super
  end

  def 🦀🦀🦀
    return unless @msg.text&.match?(/\brust!?\b/i) && (rand < 0.1)

    send_chat_action(:upload_video)
    video = Faraday::UploadIO.new("#{__dir__}/../asset/🦀🦀🦀.mp4", "mp4")
    send_video(video)
  end

  def react_to_sticker
    return unless @msg.sticker

    flip_sticker = lambda do
      return if @msg.sticker.is_video
      return if @msg.sticker.is_animated # ? fix for TGS?

      send_chat_action(:choose_sticker)
      file = download_file_but_with_types_and_pattern_matching(@msg.sticker)
      original = file.original_filename
      flopped = "flopped_#{original}"
      `convert ./#{original} -flop ./#{flopped}`
      sticker = Faraday::UploadIO.new(flopped, original.split(".").last)
      send_sticker(sticker)
    ensure
      FileUtils.rm_rf([original, flopped]) if file
    end

    Probably do
      with 0.1, &flip_sticker
    end
  end

  def download_file(attachment, dir=nil)
    file_path = @api.get_file(file_id: attachment.file_id)["result"]["file_path"]

    url = "https://api.telegram.org/file/bot#{config.token}/#{file_path}"

    file = Down.download(url)
    dir ||= "."
    FileUtils.mkdir(dir) unless Dir.exist? dir
    FileUtils.mv(file.path, "#{dir.delete_suffix("/")}/#{file.original_filename}")
    file
  end

  def download_file_but_with_types_and_pattern_matching(attachment, dir=nil)
    case { attachment: attachment }
    in { attachment: Telegram::Bot::Types::Animation => animation }
      download_file(animation, dir)
    in { attachment: Telegram::Bot::Types::Voice => voice }
      download_file(voice, dir)
    in { attachment: Telegram::Bot::Types::Animation => audio }
      download_file(audio, dir)
    in { attachment: Telegram::Bot::Types::Sticker => sticker }
      download_file(sticker, dir)
    in { attachment: Telegram::Bot::Types::Video => video }
      download_file(video, dir)
    else
      nil
    end
  end

  def get_command(text)
    return text if text == "🦀"
    super(text)
  end

  on_command "🦀" do
    return unless @user.username == config.owner_username

    if @target
      reply "Crab attack on @#{@target.username} initiated."
      @@crab_attack_targets << @target.id
      10.times do
        reply_to_target "🦀"
        sleep rand(5..15)
        break unless @target.id.in? @@crab_attack_targets
      end
    end
  end

  on_command "/cancel" do
    return unless @user.username == config.owner_username

    if @target
      reply "Crab attack on @#{@target.username} cancelled."
      @@crab_attack_targets.delete(@target.id)
    end
  end
end
