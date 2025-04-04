/**
 * Service class to interact with the NewsAPI for fetching top headlines
 */
public with sharing class NewsAPIService {
    // TODO: Define API endpoint constants
    private static final String API_NAMED_CREDENTIAL = 'callout:NewsAPIcred'; //https://newsapi.org
    private static final String API_ENDPOINT = '/v2/top-headlines';
    
    // TODO: Define default parameters
    private static final Integer DEFAULT_PAGE_SIZE = 20;
    private static final List<String> CATEGORIES = new List<String>{'business', 'entertainment', 'general', 'health', 'science', 'sports', 'technology'};
    private static final String DEFAULT_CATEGORY = 'general';
    private static final Integer DEFAULT_PAGE = 1;
    
    /**
     * Fetches top headlines for a specified category with pagination support
     * @param category The news category (business, entertainment, general, health, science, sports, technology)
     * @param pageSize Number of results per page (default: 20, max: 100)
     * @param page Page number for pagination
     * @return NewsAPIResponse The wrapper object containing the API response
     */
    public static NewsAPIResponse getTopHeadlinesByCategory(String category, Integer pageSize, Integer page) {
        // TODO: Implement method to fetch headlines by category
        // - Validate and set defaults for parameters
        if (string.isBlank(category) || !CATEGORIES.contains(category.toLowerCase())){
            category = DEFAULT_CATEGORY;
        }
        if (pageSize == null || pageSize < 1 || pageSize > 100){
            pageSize = DEFAULT_PAGE_SIZE;
        }
        if(page == null || page < 1) {
            page = DEFAULT_PAGE;
        }     
        
        // - Build the request URL
        String endpoint = API_NAMED_CREDENTIAL + API_ENDPOINT + '?category=' + category.toLowerCase() + '&pageSize=' + pageSize +'&page=' + page;
        
        // - Make the callout
        HttpResponse response = makeCallout(endpoint);

        // - Parse and return the response
        if (response.getStatusCode() < 200 || response.getStatusCode() >= 300){
            throw new NewsAPIException('Failed to retrieve articles. Status code: ' + response.getStatusCode());
        } else {
            return parseResponse(response.getBody());
        }        
    }
    
    /**
     * Helper method to make the HTTP callout
     * @param endpoint The full URL with parameters
     * @return HttpResponse The HTTP response
     */
    private static HttpResponse makeCallout(String endpoint) {
        // TODO: Implement HTTP callout
        // - Create and configure HTTP request
        Http http = new Http();
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setMethod('GET');
        
        // - Make the callout, handle exceptions
        try {
            return http.send(req);
        } catch(CalloutException e){
            throw new NewsAPIException('Callout failed: ' + e.getMessage());
        }
    }
    
    /**
     * Helper method to parse the JSON response
     * @param jsonResponse The JSON response string
     * @return NewsAPIResponse The parsed response object
     */
    private static NewsAPIResponse parseResponse(String jsonResponse) {
        // TODO: Implement JSON parsing
        // - Deserialize JSON to NewsAPIResponse & handle exceptions
        try{
            return (NewsAPIResponse)JSON.deserialize(jsonResponse, NewsAPIResponse.class);
        } catch(Exception e){
            throw new NewsAPIException('JSON parsing failed: ' + e.getMessage());
        }
    }
    
    /**
     * Custom exception class for NewsAPI errors
     */
    public class NewsAPIException extends Exception {}
} 