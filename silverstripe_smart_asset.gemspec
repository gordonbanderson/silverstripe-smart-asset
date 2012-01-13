# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "silverstripe_smart_asset/version"

Gem::Specification.new do |s|
  s.name        = "silverstripe_smart_asset"
  s.version     = SilverstripeSmartAsset::VERSION
  s.authors     = ["Gordon Anderson"]
  s.email       = ["gordon.b.anderson@gmail.com"]
  s.homepage    = ""
  s.summary     = %q{Compress javascript and CSS files for silverstripe}
  s.description = %q{Adapted from smart_asset for Rails, squash JS and }

  s.rubyforge_project = "silverstripe_smart_asset"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  # specify any dependencies here; for example:
  # s.add_development_dependency "rspec"
  # s.add_runtime_dependency "rest-client"
end
