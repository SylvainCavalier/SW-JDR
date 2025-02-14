Rails.application.config.vapid_keys = {
  public_key: ENV['VAPID_PUBLIC_KEY'],
  private_key: ENV['VAPID_PRIVATE_KEY'],
  subject: ENV['VAPID_SUBJECT']
}