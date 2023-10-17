module ChatGPTPatches
  module ClassMethods
    def new_thread(chat_id)
      super(chat_id, config.open_ai[:chat_gpt_model])
    end

    def default_instruction
      OpenAI::SystemMessage.new(body: config.personality.to_json)
    end

    def first_user_message
      from = config.open_ai.dig("first_user_message", "from")
      msg = config.open_ai.dig("first_user_message", "body")

      return unless from && msg

      OpenAI::Message.new(from: from, body: msg)
    end

    def first_bot_message
      msg = config.open_ai.dig("first_bot_message", "body")

      return unless msg

      OpenAI::BotMessage.new(body: msg)
    end

    def initial_messages
      [default_instruction, first_user_message, first_bot_message].compact
    end
  end

  def self.included(base)
    base.extend(ClassMethods)
  end

  def chat_not_allowed_message
    # Return false/nil (leave method empty) to ignore
    # "This chat (`#{@chat.id}`) is not whitelisted for ChatGPT usage. Ask @#{config.owner_username}."
    config.system_messages[:default_answer]
  end

  def send_chat_gpt_error(text)
    @@last_gpt_error_time ||= Time.now
    return if (Time.now - @@last_gpt_error_time) < 300

    @@last_gpt_error_time = Time.now

    super(text)
  end

  def session_restart_message
    config.system_messages[:session_restart]
  end

  def matches_by_triggers?
    string_triggers = config.open_ai[:gpt_triggers][:strings]
    re_triggers = config.open_ai[:gpt_triggers][:regexps]

    return true if string_triggers.any? { @text.include? _1 }

    re_triggers.any? { @text.match? Regexp.new(_1) }
  end

  def bot_mentioned?
    super || matches_by_triggers?
  end
end
