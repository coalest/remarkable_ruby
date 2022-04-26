module RemarkableRuby
  class Config
    HOME_DIR = Dir.home
    CONFIG_FILE_PATH = HOME_DIR + '/.rmapi'

    def self.load_tokens
      return unless File.exists?(CONFIG_FILE_PATH)

      YAML.load_file(CONFIG_FILE_PATH)
    end

    def self.save(device_token: nil, user_token: nil)
      FileUtils.touch(CONFIG_FILE_PATH) unless File.exists?(CONFIG_FILE_PATH)

      config_hash = YAML::load_file(CONFIG_FILE_PATH) || {}
      config_hash['devicetoken'] = device_token if device_token
      config_hash['usertoken'] = user_token if user_token
      File.write(CONFIG_FILE_PATH, config_hash.to_yaml)
    end
  end
end
