# frozen_string_literal: true

class LogEntryComponent < ApplicationComponent
  attr_reader :entry

  def on_load(entry:)
    @entry = entry.to_s
  end

  def call
    result = case detect_log_type
    when :trading_log
      format_trading_log
    when :death_message
      format_death_message
    when :timestamped_log
      format_timestamped_log
    else
      format_generic_log
    end

    result.html_safe
  end

  private

  def detect_log_type
    return :death_message if death_message?
    return :timestamped_log if timestamped_log?
    return :trading_log if trading_log?

    :generic
  end

  def death_message?
    entry.match?(/\w+ (died|commited suicide|was killed)/)
  end

  def timestamped_log?
    entry.start_with?("[") && entry.include?("] [Thread")
  end

  def trading_log?
    entry.include?("PLAYER:") && entry.include?("REMOTE")
  end

  def format_trading_log
    formatted = entry

    # Highlight player info
    formatted = formatted.gsub(/PLAYER:\s*\(\s*(\d+)\s*\)/,
      'PLAYER: <span class="text-success">( \1 )</span>')

    # Highlight player names (R Username:number format)
    formatted = formatted.gsub(/R\s+([^:]+:\d+)\s+\(([^)]+)\)/,
      'R <span class="text-success">\1</span> <span class="text-muted">(\2)</span>')

    # Highlight money amounts
    formatted = formatted.gsub(/(\d+(?:\.\d+)?e?\+?\d*)\s*POPTABS/,
      '<span class="text-warning fw-bold">\1 POPTABS</span>')

    formatted = formatted.gsub(/PLAYER TOTAL MONEY:\s*(\d+(?:\.\d+)?e?\+?\d*)/,
      'PLAYER TOTAL MONEY: <span class="text-warning fw-bold">\1</span>')

    # Highlight respect
    formatted = formatted.gsub(/(\d+(?:\.\d+)?)\s*RESPECT/,
      '<span class="text-info">\1 RESPECT</span>')

    # Highlight actions
    formatted = formatted.gsub(/\b(REMOTE\s+(?:PURCHASED|SOLD))\b/,
      '<span class="text-primary">\1</span>')

    formatted.gsub(/\b(ITEM|VEHICLE)\b/,
      '<span class="text-light fw-medium">\1</span>')
  end

  def format_death_message
    # These are hilarious, let's make them stand out
    formatted = entry

    # Highlight the player name
    formatted = formatted.gsub(/^(\w+)/, '<span class="text-danger fw-bold">\1</span>')

    # Highlight death reasons with some personality
    death_phrases = [
      "died because.*Arma",
      "died.*mysterious death",
      "commited suicide",
      "died.*awkward death",
      "died.*very unlucky",
      "was killed by an NPC",
      "died.*really dead-dead",
      "died.*universe hates"
    ]

    death_phrases.each do |phrase|
      formatted = formatted.gsub(/#{phrase}/i, '<span class="text-warning">\0</span>')
    end

    formatted
  end

  def format_timestamped_log
    formatted = entry

    # Extract and highlight the timestamp part
    formatted = formatted.gsub(/\[([^\]]+)\]/, '<span class="text-info">[\1]</span>')

    # Highlight thread info
    formatted = formatted.gsub(/\[Thread\s+(\d+)\]/, '<span class="text-muted">[Thread \1]</span>')

    # Apply trading log formatting to the rest if it's a trading log
    if formatted.include?("PLAYER:")
      # Extract the main part after timestamps and apply trading formatting
      main_part = formatted.split("] ").last
      if main_part&.include?("REMOTE")
        formatted_main = format_trading_log_content(main_part)
        formatted = formatted.gsub(main_part, formatted_main)
      end
    end

    formatted
  end

  def format_generic_log
    # Just return as-is with basic escaping
    ERB::Util.html_escape(entry)
  end

  def format_trading_log_content(content)
    # Same logic as format_trading_log but for just the content part
    formatted = content

    formatted = formatted.gsub(/PLAYER:\s*\(\s*(\d+)\s*\)/,
      'PLAYER: <span class="text-success">( \1 )</span>')

    formatted = formatted.gsub(/R\s+([^:]+:\d+)\s+\(([^)]+)\)/,
      'R <span class="text-success">\1</span> <span class="text-muted">(\2)</span>')

    formatted = formatted.gsub(/(\d+(?:\.\d+)?e?\+?\d*)\s*POPTABS/,
      '<span class="text-warning fw-bold">\1 POPTABS</span>')

    formatted.gsub(/PLAYER TOTAL MONEY:\s*(\d+(?:\.\d+)?e?\+?\d*)/,
      'PLAYER TOTAL MONEY: <span class="text-warning fw-bold">\1</span>')
  end
end
