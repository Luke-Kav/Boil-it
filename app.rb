require 'rubygems'
require 'base64'
require 'openssl'
require 'sinatra'
require 'shopify_api'
require 'active_support/security_utils'



# The Shopify app's shared secret, viewable from the Partner dashboard
SHARED_SECRET = 'cfc968d1c2bd375bcb23f17e12ebe4a1aab162a26cc837839ea738c824da095c'
API_KEY = 'xxxxxx'
PASSWORD = 'xxxxxxx'
SHOP_NAME = 'bruciesbonuses'
shop_url = "https://#{API_KEY}:#{PASSWORD}@#{SHOP_NAME}.myshopify.com"
ShopifyAPI::Base.site = shop_url
ShopifyAPI::Base.api_version = '2020-10' # find the latest stable api_version here: https://shopify.dev/concepts/about-apis/versioning


helpers do
  # Compare the computed HMAC digest based on the shared secret and the request contents
  # to the reported HMAC in the headers
  def verify_webhook(data, hmac_header)
    calculated_hmac = Base64.strict_encode64(OpenSSL::HMAC.digest('sha256', SHARED_SECRET, data))
    ActiveSupport::SecurityUtils.secure_compare(calculated_hmac, hmac_header)
  end
end


# Respond to HTTP POST requests sent to this web service
post '/webhook/product_update' do # - URL for the webhook subscription YOU 
  request.body.rewind # want to make to receive webhooks then do something processing
  data = request.body.read
  verified = verify_webhook(data, env["HTTP_X_SHOPIFY_HMAC_SHA256"])
  unless verified
  return [403, 'Authorisation failed. Provided hmac was #{hmac_header']
end

puts "Webhook verified: #{verified}"

#we're cool up to here

  json_data = JSON.parse data

  product = ShopifyAPI::Product.find(json_data['id'].to_i)
  #we are using the Shopify API GEM TO get the product id from the json data
  #which is the parsed request body data, there's a heap of other methods.
  # YOU GET THE ID SO THEN YOU CAN ADD TO THE PRODUCT LATER

  product.tags += ', Updated' #concentate product tags on comma delimited
  product.save  #and adding an 'updated' tag, to filter the products
#the SHopify API gem is basically doing alot of the work here and acts
# on an active resource (the products) to manupulate the products
  return [200, 'Webhook successfully received']
end
