class SilverstripeSmartAsset
  module Adapters
    module Sinatra
      
      def self.included(klass)
        if klass.environment && klass.root
          SilverstripeSmartAsset.env = klass.environment
          SilverstripeSmartAsset.load_config klass.root
        end
      end
    end
  end
end

Sinatra::Base.send(:include, SilverstripeSmartAsset::Helper)