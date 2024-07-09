if defined?(AssetSync)
  AssetSync.configure do |config|
    config.enabled = Rails.env.production? && ENV['APP_RUN_PRECOMPILE_ASSETS'] == 'TRUE'
    config.fog_provider = 'AWS'
    config.aws_iam_roles = true
    config.aws_session_token = ENV['AWS_SESSION_TOKEN'] if ENV.key?('AWS_SESSION_TOKEN')
    config.fog_directory = ENV.fetch('ASSETS_BUCKET', nil)
    config.fog_region = 'eu-west-2'
  end
end
