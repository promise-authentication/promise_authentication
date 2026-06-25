# Default region used when a user types a phone number without an
# international prefix (e.g. "20 12 34 56" instead of "+45 20 12 34 56").
Phonelib.default_country = ENV.fetch('DEFAULT_PHONE_REGION', 'DK')
