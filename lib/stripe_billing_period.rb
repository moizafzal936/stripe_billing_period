# frozen_string_literal: true

require "time"
require_relative "stripe_billing_period/version"

# Reads a subscription's current billing period no matter which Stripe API
# version produced the payload.
#
# Newer Stripe API versions moved `current_period_start` / `current_period_end`
# from the Subscription onto each Subscription Item. Code (and webhook handlers)
# written for the old shape keep running but silently get `nil` periods.
# This gem gives you one place to read the period from either shape.
module StripeBillingPeriod
  class MissingPeriodError < StandardError; end

  Window = Struct.new(:starts_at, :ends_at, :source, keyword_init: true) do
    def cover?(time)
      time >= starts_at && time < ends_at
    end

    def days
      ((ends_at - starts_at) / 86_400.0).round
    end
  end

  module_function

  # subscription: a Stripe::Subscription, or a Hash from a webhook payload
  # (string or symbol keys).
  # item_id: pick a specific subscription item; defaults to the earliest
  # period across items.
  def for(subscription, item_id: nil, strict: true)
    window = from_items(subscription, item_id) || from_subscription(subscription)
    return window if window
    raise MissingPeriodError, "no billing period on subscription #{fetch(subscription, :id).inspect}" if strict

    nil
  end

  def from_items(subscription, item_id)
    items = Array(fetch(fetch(subscription, :items), :data))
    items = items.select { |i| fetch(i, :id) == item_id } if item_id
    windows = items.filter_map do |item|
      build(fetch(item, :current_period_start), fetch(item, :current_period_end), :item)
    end
    return nil if windows.empty?

    Window.new(starts_at: windows.map(&:starts_at).min, ends_at: windows.map(&:ends_at).min, source: :item)
  end

  def from_subscription(subscription)
    build(fetch(subscription, :current_period_start), fetch(subscription, :current_period_end), :subscription)
  end

  def build(start_ts, end_ts, source)
    return nil if start_ts.nil? || end_ts.nil?

    Window.new(starts_at: to_time(start_ts), ends_at: to_time(end_ts), source: source)
  end

  def to_time(value)
    case value
    when Time then value.utc
    when Integer then Time.at(value).utc
    when String then value.match?(/\A\d+\z/) ? Time.at(value.to_i).utc : Time.parse(value).utc
    else raise ArgumentError, "unsupported timestamp: #{value.inspect}"
    end
  end

  def fetch(obj, key)
    return nil if obj.nil?

    if obj.respond_to?(:key?) && obj.respond_to?(:[])
      return obj[key] if obj.key?(key)
      return obj[key.to_s] if obj.key?(key.to_s)
      return nil
    end
    obj.respond_to?(key) ? obj.public_send(key) : nil
  end
end
