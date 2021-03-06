// Defines the main uCommerce angular application module.
var app = angular.module('ucommerce', [
  'ucommerce.services',
  'ucommerce.directives',
  'ucommerce.resources',
  'LocalStorageModule'
])

app.config([
  '$httpProvider',
  function ($httpProvider) {
    // initialize get if not there
    if (!$httpProvider.defaults.headers.get) {
      $httpProvider.defaults.headers.get = {}
    }

    // disable IE ajax request caching
    $httpProvider.defaults.headers.get['Cache-Control'] = 'no-cache'
    $httpProvider.defaults.headers.get['Pragma'] = 'no-cache'
  }
])
