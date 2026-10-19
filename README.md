# stripe_billing_period

Read a Stripe subscription's current billing period from **any** API version.

Newer Stripe API versions moved `current_period_start` / `current_period_end` from the
Subscription onto each Subscription Item. Code written for the old shape keeps running,
but it gets `nil` and nothing raises, so renewals, proration and access checks quietly go wrong.

```ruby
window = StripeBillingPeriod.for(subscription)   # Stripe::Subscription or webhook Hash
window.starts_at   # => 2026-01-01 00:00:00 UTC
window.ends_at     # => 2026-02-01 00:00:00 UTC
window.source      # => :item or :subscription
window.cover?(Time.now.utc)
```

- Prefers the item-level period, falls back to the legacy subscription fields.
- Works with `Stripe::Subscription` objects and raw webhook hashes (string or symbol keys).
- Raises `StripeBillingPeriod::MissingPeriodError` instead of returning `nil` (pass `strict: false` to opt out).
- No dependencies.

## Install
```ruby
gem "stripe_billing_period", github: "moizafzal936/stripe_billing_period"
```

## Why
I hit this in production: after an API-version upgrade, webhooks stopped reconciling charges
and nothing errored. Putting every read of the billing period behind one function fixed it.

MIT licensed.
