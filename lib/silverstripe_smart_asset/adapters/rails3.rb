if Rails.root.nil?
  class SilverstripeSmartAsset
    class SilverstripeSmartAssetRailtie < Rails::Railtie
      initializer "silverstripe_smart_asset_railtie.configure_rails_initialization" do
        SilverstripeSmartAsset.env = Rails.env
        SilverstripeSmartAsset.load_config(Rails.root)
      end
    end
  end
else
  SilverstripeSmartAsset.env = Rails.env
  SilverstripeSmartAsset.load_config(Rails.root)
end

ActionController::Base.send(:include, SilverstripeSmartAsset::Helper)
ActionController::Base.helper(SilverstripeSmartAsset::Helper)