# This script uses the Zillow API to search for properties
# given some parameters (State: CA, City: Irvine, Childtype: zipcodes)
# A Faraday connection and response is made with the Zillow API url
# in order to read the XML response body. Given the parameters, the 
# test asserts that each of the results match the criteria.

# This script requires a text file titled "APIKey" 
# outside of the spec folder. This file should contain
# only your Zillow API key and nothing else.
apiKey = File.open('./APIKey.txt', &:readline)

# The Zillow API call is broken down into a two parts:
# - The Zillow Web Service 
# 		"http://www.zillow.com/webservice/GetRegionChildren.htm"
# - An API key (be careful not to share)
zillowWebService = 'http://www.zillow.com/webservice/GetRegionChildren.htm'
apiKey = '?zws-id=' + apiKey
constructedUrl = zillowWebService + apiKey

describe 'Make a Zillow API call for Irvine, CA' do
	before(:all) do
		@conn = Faraday.new(:url => constructedUrl) do |faraday|
			faraday.request :json
			faraday.response :json, :content_type => /\bjson$/
			faraday.adapter Faraday.default_adapter
		end
	end
	
	# After the Faraday connection is made, the parameters are appended to
	# the URL to create a response. The response is used to confirm the 
	# status of the API call and also to confirm that the request has been
	# completed correctly. 
	context 'Using these parameters: California, Irvine, Neighborhood' do
		before(:all) do
			@response = @conn.get do |req|
				req.params['state'] = 'ca'
				req.params['city'] = 'irvine'
				req.params['childtype'] = 'zipcode'
			end
		end
		
		it 'responds with a 200 Success' do
			expect(@response.status).to eq 200
		end
		
		# The xpath methods return the matching tagnames within the XML.
		# The test asserts that all parts of the request are correct and
		# then asserts that each property received is within Irvine.
		it 'has properties matching the criteria' do
			@doc = Nokogiri::XML(@response.body)
			
			@requestState = @doc.xpath("//request//state").inner_text
			@requestCity = @doc.xpath("//request//city").inner_text
			@requestChildtype = @doc.xpath("//request//childtype").inner_text
			@requestMessage = @doc.xpath("//message//text").inner_text
			@requestCode = @doc.xpath("//message//code").inner_text.to_i
			
			expect(@requestState).to be == "ca"
			expect(@requestCity).to be == "irvine"
			expect(@requestChildtype).to be == "zipcode"
			expect(@requestMessage).to be == "Request successfully processed"
			expect(@requestCode).to be == 0
			
			@irvineZipCodes = [92602, 92603, 92604, 92606, 92610, 92612, 92614, 92616,
			92617, 92618, 92619, 92620, 92623, 92637, 92650, 92657, 92679, 92697, 92782]
			
			@zipCodeResults = @doc.xpath("//list//region//name")
			@zipCodeResults.each do |line|
				@zipCode = line.inner_text.to_i
				expect(@irvineZipCodes).to include(@zipCode)
			end
		end
	end
end