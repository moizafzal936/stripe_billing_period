# frozen_string_literal: true

require "minitest/autorun"
require "stripe_billing_period"

class StripeBillingPeriodTest < Minitest::Test
  JAN1 = Time.utc(2026, 1, 1).to_i
  FEB1 = Time.utc(2026, 2, 1).to_i

  def test_reads_period_from_items_new_api_shape
    sub = { "id" => "sub_1", "items" => { "data" => [{ "id" => "si_1", "current_period_start" => JAN1, "current_period_end" => FEB1 }] } }
    w = StripeBillingPeriod.for(sub)
    assert_equal :item, w.source
    assert_equal Time.utc(2026, 1, 1), w.starts_at
    assert_equal 31, w.days
  end

  def test_falls_back_to_subscription_legacy_shape
    sub = { id: "sub_2", current_period_start: JAN1, current_period_end: FEB1, items: { data: [{ id: "si_2" }] } }
    assert_equal :subscription, StripeBillingPeriod.for(sub).source
  end

  def test_prefers_item_period_when_both_present
    sub = { current_period_start: 1, current_period_end: 2, items: { data: [{ current_period_start: JAN1, current_period_end: FEB1 }] } }
    assert_equal Time.utc(2026, 1, 1), StripeBillingPeriod.for(sub).starts_at
  end

  def test_targets_one_item
    sub = { items: { data: [{ id: "a", current_period_start: JAN1, current_period_end: FEB1 },
                            { id: "b", current_period_start: FEB1, current_period_end: FEB1 + 86_400 * 28 }] } }
    assert_equal Time.utc(2026, 2, 1), StripeBillingPeriod.for(sub, item_id: "b").starts_at
  end

  def test_works_with_stripe_like_objects
    item = Struct.new(:id, :current_period_start, :current_period_end).new("si", JAN1, FEB1)
    items = Struct.new(:data).new([item])
    sub = Struct.new(:id, :items, :current_period_start, :current_period_end).new("sub", items, nil, nil)
    assert_equal Time.utc(2026, 2, 1), StripeBillingPeriod.for(sub).ends_at
  end

  def test_raises_instead_of_silent_nil
    assert_raises(StripeBillingPeriod::MissingPeriodError) { StripeBillingPeriod.for({ id: "sub_x" }) }
    assert_nil StripeBillingPeriod.for({ id: "sub_x" }, strict: false)
  end

  def test_cover
    w = StripeBillingPeriod.for({ current_period_start: JAN1, current_period_end: FEB1 })
    assert w.cover?(Time.utc(2026, 1, 15))
    refute w.cover?(Time.utc(2026, 2, 1))
  end
end
