lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'courier/feeds/version'

Gem::Specification.new do |spec|
  spec.name          = 'courier-feeds'
  spec.version       = Courier::Feeds::VERSION
  spec.authors       = ['Matt Moriarity']
  spec.email         = ['matt@mattmoriarity.com']

  spec.summary       = 'API client for courier-feeds microservice'
  spec.homepage      = 'https://github.com/mjm/courier-feeds'
  spec.license       = 'MIT'

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = "TODO: Set to 'http://mygemserver.com'"
  else
    raise 'RubyGems 2.0 or newer is required to protect against ' \
      'public gem pushes.'
  end

  spec.files         = Dir['lib/**/*']
  spec.require_paths = ['lib']

  spec.add_dependency 'jwt'
  spec.add_dependency 'twirp'
  spec.add_dependency 'typhoeus'
end
