SilverstripeSmartAsset.env = Rails.env
SilverstripeSmartAsset.load_config(Rails.root)

ActionController::Base.send(:include, SilverstripeSmartAsset::Helper)
ActionController::Base.helper(SilverstripeSmartAsset::Helper)