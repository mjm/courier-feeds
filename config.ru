#\ -p 5002

$LOAD_PATH.unshift(File.expand_path('.'))
require 'app'

use DocHandler
run App
