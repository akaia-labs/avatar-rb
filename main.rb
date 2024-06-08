#!/usr/bin/env ruby
# frozen_string_literal: true

require "openai"
require "pry"
require "down"
require "rubydium"
require "base64"

require_relative "lib/hash_with_indifferent_access"

require_relative "app/clean_bot"
require_relative "app/prob"

require_relative "app/akaia_avatar"
require_relative "app/clean_bot"

bots = {
  "akaia_avatar" => AkaiaAvatar,
  "clean" => CleanBot
}

bot_name = (ARGV & bots.keys).first
bot = bots[bot_name] || AkaiaAvatar

bot.config = JSON.load_file("#{__dir__}/config.json").to_h_with_indifferent_access

bot.configure do |config|
  config.open_ai_client = OpenAI::Client.new(
    access_token: config.open_ai_token
    # organization_id: config.open_ai_organization_id
  )
end

if __FILE__ == $PROGRAM_NAME
  command_list = bot.help_message.lines.map { _1.delete_prefix("/") }.join
  puts "Launching #{bot}. Command list: \n\n#{command_list}\n"
  bot.run
end
