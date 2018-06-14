source "https://rubygems.org"

# git_source(:github) {|repo_name| "https://github.com/#{repo_name}" }

group :plugins do
  # Dependencies need to be specified in vagrant-databags.gemspec
  gemspec
end

group :development do
  # We depend on Vagrant for development, but we don't add it as a
  # gem dependency because we expect to be installed within the
  # Vagrant environment itself using `vagrant plugin`.
  gem 'vagrant', git: "https://github.com/mitchellh/vagrant.git"
  gem 'vagrant-spec', git: "https://github.com/mitchellh/vagrant-spec.git"
  gem 'spork'
  gem 'rspec'
  gem 'rake'
end
