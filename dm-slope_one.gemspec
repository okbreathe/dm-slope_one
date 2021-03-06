# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in Rakefile, and run 'rake gemspec'
# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "dm-slope_one"
  s.version = "0.3.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Asher Van Brunt"]
  s.date = "2012-04-02"
  s.description = "Implementation of the [Slope One](http://en.wikipedia.org/wiki/Slope_One) recommendation algorithm for DataMapper"
  s.email = "asher.vanbrunt@gmail.com"
  s.extra_rdoc_files = [
    "LICENSE.txt",
    "README.rdoc"
  ]
  s.files = [
    ".autotest",
    ".document",
    "Gemfile",
    "Gemfile.lock",
    "LICENSE.txt",
    "README.rdoc",
    "Rakefile",
    "VERSION",
    "dm-slope_one.gemspec",
    "lib/dm-slope_one.rb",
    "lib/dm-slope_one/is/rating.rb",
    "lib/dm-slope_one/is/slope_one.rb",
    "test/data.rb",
    "test/helper.rb",
    "test/test_dm-slope_one.rb"
  ]
  s.homepage = "http://github.com/okbreathe/dm-slope_one"
  s.licenses = ["MIT"]
  s.require_paths = ["lib"]
  s.rubygems_version = "1.8.10"
  s.summary = "Implementation of the [Slope One](http://en.wikipedia.org/wiki/Slope_One) recommendation algorithm for DataMapper"

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<dm-ar-finders>, [">= 1.2.0"])
      s.add_runtime_dependency(%q<dm-validations>, [">= 1.2.0"])
      s.add_runtime_dependency(%q<dm-constraints>, [">= 1.2.0"])
      s.add_runtime_dependency(%q<dm-transactions>, [">= 1.2.0"])
      s.add_development_dependency(%q<minitest>, [">= 0"])
      s.add_development_dependency(%q<bundler>, [">= 0"])
      s.add_development_dependency(%q<jeweler>, [">= 0"])
      s.add_development_dependency(%q<rr>, [">= 0"])
      s.add_development_dependency(%q<dm-sqlite-adapter>, [">= 1.2.0"])
      s.add_development_dependency(%q<dm-postgres-adapter>, [">= 1.2.0"])
      s.add_development_dependency(%q<dm-migrations>, [">= 1.2.0"])
    else
      s.add_dependency(%q<dm-ar-finders>, [">= 1.2.0"])
      s.add_dependency(%q<dm-validations>, [">= 1.2.0"])
      s.add_dependency(%q<dm-constraints>, [">= 1.2.0"])
      s.add_dependency(%q<dm-transactions>, [">= 1.2.0"])
      s.add_dependency(%q<minitest>, [">= 0"])
      s.add_dependency(%q<bundler>, [">= 0"])
      s.add_dependency(%q<jeweler>, [">= 0"])
      s.add_dependency(%q<rr>, [">= 0"])
      s.add_dependency(%q<dm-sqlite-adapter>, [">= 1.2.0"])
      s.add_dependency(%q<dm-postgres-adapter>, [">= 1.2.0"])
      s.add_dependency(%q<dm-migrations>, [">= 1.2.0"])
    end
  else
    s.add_dependency(%q<dm-ar-finders>, [">= 1.2.0"])
    s.add_dependency(%q<dm-validations>, [">= 1.2.0"])
    s.add_dependency(%q<dm-constraints>, [">= 1.2.0"])
    s.add_dependency(%q<dm-transactions>, [">= 1.2.0"])
    s.add_dependency(%q<minitest>, [">= 0"])
    s.add_dependency(%q<bundler>, [">= 0"])
    s.add_dependency(%q<jeweler>, [">= 0"])
    s.add_dependency(%q<rr>, [">= 0"])
    s.add_dependency(%q<dm-sqlite-adapter>, [">= 1.2.0"])
    s.add_dependency(%q<dm-postgres-adapter>, [">= 1.2.0"])
    s.add_dependency(%q<dm-migrations>, [">= 1.2.0"])
  end
end

