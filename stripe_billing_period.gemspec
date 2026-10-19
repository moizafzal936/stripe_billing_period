# frozen_string_literal: true

require_relative "lib/stripe_billing_period/version"

Gem::Specification.new do |s|
  s.name        = "stripe_billing_period"
  s.version     = StripeBillingPeriod::VERSION
  s.summary     = "Read a Stripe subscription's billing period from any API version"
  s.description = "Newer Stripe API versions moved current_period_start/end onto subscription items. " \
                  "This gem reads the period from either shape so webhook handlers stop silently getting nil."
  s.authors     = ["Mueez Afzal"]
  s.license     = "MIT"
  s.files       = Dir["lib/**/*.rb", "README.md", "LICENSE"]
  s.required_ruby_version = ">= 3.0"
  s.homepage    = "https://github.com/moizafzal936/stripe_billing_period"
  s.add_development_dependency "minitest", "~> 5.0"
end
